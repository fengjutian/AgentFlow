package com.agentflow.agentflow

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger

/**
 * Runs shell commands inside Termux through its `RUN_COMMAND` service intent.
 *
 * Termux gives the agent a real Linux toolchain (bash, git, python…) that a
 * plain Android app process does not have, so where it is set up it is the
 * preferred way to execute a tool call. Three conditions have to hold, all of
 * them user-controlled: Termux must be installed, the dangerous
 * `com.termux.permission.RUN_COMMAND` permission must be granted to this app,
 * and `allow-external-apps=true` must be set in Termux's `termux.properties`.
 * [isUsable] covers the first two; violating the third comes back as an error
 * message in the result, which is reported to the caller like any other stderr.
 *
 * Commands are dispatched as background executions so stdout and stderr arrive
 * separately. Two properties of `RUN_COMMAND` shape the contract: it takes no
 * custom environment variables (they are dropped) and Termux cannot enter this
 * app's private directory, so a working directory outside Termux's visible tree
 * is remapped to Termux home.
 *
 * The string constants mirror `TermuxConstants.TERMUX_APP` from the termux-shared
 * library. They are stable public plugin API and are inlined here to avoid the
 * dependency; see the `RUN_COMMAND Intent` page of the termux-app wiki.
 */
object TermuxExec {

    private const val TAG = "AgentFlowTermux"

    const val PACKAGE_NAME = "com.termux"
    const val PERMISSION_RUN_COMMAND = "com.termux.permission.RUN_COMMAND"
    const val HOME_DIR = "/data/data/com.termux/files/home"
    const val BASH = "/data/data/com.termux/files/usr/bin/bash"

    private const val SERVICE_NAME = "com.termux.app.RunCommandService"
    private const val ACTION_RUN_COMMAND = "com.termux.RUN_COMMAND"
    private const val EXTRA_COMMAND_PATH = "com.termux.RUN_COMMAND_PATH"
    private const val EXTRA_ARGUMENTS = "com.termux.RUN_COMMAND_ARGUMENTS"
    private const val EXTRA_WORKDIR = "com.termux.RUN_COMMAND_WORKDIR"
    private const val EXTRA_BACKGROUND = "com.termux.RUN_COMMAND_BACKGROUND"
    private const val EXTRA_COMMAND_LABEL = "com.termux.RUN_COMMAND_COMMAND_LABEL"
    private const val EXTRA_PENDING_INTENT = "com.termux.RUN_COMMAND_PENDING_INTENT"

    // Keys of the result bundle Termux fills into our PendingIntent.
    private const val EXTRA_RESULT_BUNDLE = "result"
    private const val RESULT_STDOUT = "stdout"
    private const val RESULT_STDERR = "stderr"
    private const val RESULT_EXIT_CODE = "exitCode"
    private const val RESULT_ERRMSG = "errmsg"

    /** Our own extra, used to correlate a result with the call that produced it. */
    private const val EXTRA_REQUEST_ID = "com.agentflow.extra.TERMUX_REQUEST_ID"

    private val requestIds = AtomicInteger(0x1000)
    private val waiting = ConcurrentHashMap<Int, Callback>()

    /** Notified once per request, with Termux's result. Never called on timeout. */
    fun interface Callback {
        fun onResult(exitCode: Int, stdout: String, stderr: String, errorMessage: String?)
    }

    fun isInstalled(context: Context): Boolean = try {
        context.packageManager.getPackageInfo(PACKAGE_NAME, 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    /**
     * Whether the runtime permission is granted. It can only be granted while
     * Termux is installed — Android drops unknown permissions at install time,
     * so installing Termux after this app means this app has to be reinstalled.
     */
    fun hasPermission(context: Context): Boolean =
        context.checkSelfPermission(PERMISSION_RUN_COMMAND) == PackageManager.PERMISSION_GRANTED

    /** True when a command can be handed to Termux right now. */
    fun isUsable(context: Context): Boolean =
        hasPermission(context) && runCommandIntent(context) != null

    private fun runCommandIntent(context: Context): Intent? {
        val intent = Intent(ACTION_RUN_COMMAND).setClassName(PACKAGE_NAME, SERVICE_NAME)
        val resolved = context.packageManager.resolveService(intent, 0)
        return if (resolved != null) intent else null
    }

    /**
     * Dispatches [command] to Termux and returns the request id, or `-1` when the
     * intent could not be handed over at all so the caller can fall back to the
     * on-device shell.
     *
     * The result arrives asynchronously on [callback]; callers that need to bound
     * the wait cancel the request with [cancel].
     */
    fun execute(context: Context, command: String, cwd: String?, callback: Callback): Int {
        val base = runCommandIntent(context) ?: return -1
        val id = requestIds.incrementAndGet()
        val workdir = termuxWorkdir(cwd)

        // Mutable so Termux can fill the result bundle into this intent; the
        // request code is unique per call, otherwise Android would reuse (and
        // after the first delivery cancel) a pending intent from an earlier run.
        var flags = PendingIntent.FLAG_ONE_SHOT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            flags = flags or PendingIntent.FLAG_MUTABLE
        }
        val resultIntent = Intent(context, TermuxResultReceiver::class.java)
            .putExtra(EXTRA_REQUEST_ID, id)
        val pendingIntent = PendingIntent.getBroadcast(context, id, resultIntent, flags)

        val intent = base
            .putExtra(EXTRA_COMMAND_PATH, BASH)
            .putExtra(EXTRA_ARGUMENTS, arrayOf("-c", command))
            .putExtra(EXTRA_WORKDIR, workdir)
            .putExtra(EXTRA_BACKGROUND, true)
            .putExtra(EXTRA_COMMAND_LABEL, "AgentFlow")
            .putExtra(EXTRA_PENDING_INTENT, pendingIntent)

        waiting[id] = callback
        return try {
            // RunCommandService calls startForeground() in onCreate/onStartCommand,
            // so starting it as a foreground service from the background is safe.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            Log.d(TAG, "Dispatched request #$id to Termux (workdir=$workdir)")
            id
        } catch (e: Exception) {
            Log.w(TAG, "Termux RUN_COMMAND start failed for #$id: ${e.message}")
            waiting.remove(id)
            pendingIntent.cancel()
            -1
        }
    }

    /**
     * Drops a pending request so a late result is ignored. Termux itself is not
     * told to stop — a timed-out command may still be running there.
     */
    fun cancel(id: Int) {
        if (id < 0) return
        waiting.remove(id)
        Log.d(TAG, "Cancelled request #$id (no result within the timeout)")
    }

    /**
     * Termux runs in its own sandbox and cannot enter this app's private
     * directory, so anything that is not a Termux-visible path is remapped to
     * Termux home.
     */
    private fun termuxWorkdir(cwd: String?): String {
        if (cwd.isNullOrEmpty()) return HOME_DIR
        val visible = cwd.startsWith("/data/data/$PACKAGE_NAME/") ||
            cwd.startsWith("/sdcard") ||
            cwd.startsWith("/storage/")
        return if (visible) cwd else HOME_DIR
    }

    /** Hands a result from [TermuxResultReceiver] to the waiting callback. */
    internal fun deliver(intent: Intent) {
        val id = intent.getIntExtra(EXTRA_REQUEST_ID, -1)
        val callback = waiting.remove(id)
        if (callback == null) {
            // Either cancelled by a timeout or Termux delivered it twice.
            Log.w(TAG, "Ignoring Termux result for unknown request #$id")
            return
        }
        val bundle: Bundle? = intent.getBundleExtra(EXTRA_RESULT_BUNDLE)
        if (bundle == null) {
            callback.onResult(-1, "", "", "Termux returned no result bundle")
            return
        }
        Log.d(TAG, "Request #$id finished with exit code ${bundle.getInt(RESULT_EXIT_CODE)}")
        callback.onResult(
            bundle.getInt(RESULT_EXIT_CODE, -1),
            bundle.getString(RESULT_STDOUT) ?: "",
            bundle.getString(RESULT_STDERR) ?: "",
            bundle.getString(RESULT_ERRMSG),
        )
    }
}

/**
 * Receives Termux command results. Registered in the manifest rather than at
 * runtime so a result that arrives while no activity is alive is not lost; the
 * PendingIntent is created by this app, so delivery works even though the
 * receiver is not exported.
 */
class TermuxResultReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent != null) TermuxExec.deliver(intent)
    }
}
