package com.agentflow.agentflow

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.InputStream
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/**
 * Kotlin side of the `agentflow/runtime` MethodChannel.
 *
 * Implements the same contract as the Dart `Runtime` abstraction so the Agent
 * Core cannot tell whether it is running on-device, in Termux or (later) over
 * SSH. Commands run with a hard timeout; a foreground service is held for the
 * duration so the OS is less likely to kill a long agent task when the app is
 * backgrounded.
 *
 * A command is handed to Termux whenever [TermuxExec] can take it, because that
 * is where a real toolchain (bash, git, python) lives; otherwise it runs through
 * the system shell of this app's own process. Which of the two was used is
 * reported by `shellInfo` and surfaced in the Settings runtime card.
 */
class RuntimeManager(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val context: Context = activity.applicationContext
    private val channel = MethodChannel(messenger, CHANNEL)
    private val messenger: BinaryMessenger = messenger
    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newCachedThreadPool()

    /** Awaits the outcome of the Termux runtime permission dialog, if any. */
    private var pendingPermissionResult: MethodChannel.Result? = null

    /** Long-lived process sessions for BridgeProcessSession. */
    private val sessions = ConcurrentHashMap<String, LongProcessSession>()

    fun attach() {
        channel.setMethodCallHandler(this)
    }

    fun detach() {
        channel.setMethodCallHandler(null)
        sessions.values.forEach { it.terminate() }
        sessions.clear()
        executor.shutdownNow()
        pendingPermissionResult = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> result.success(true)
            "shellInfo" -> result.success(shellInfo())
            "executeCommand" -> executeCommand(call, result)
            "requestTermuxPermission" -> requestTermuxPermission(result)
            "readFile" -> readFile(call, result)
            "writeFile" -> writeFile(call, result)
            "deleteFile" -> deleteFile(call, result)
            "createDirectory" -> createDirectory(call, result)
            "renameEntry" -> renameEntry(call, result)
            "deleteEntry" -> deleteEntry(call, result)
            "fileExists" -> fileExists(call, result)
            "listFiles" -> listFiles(call, result)
            // Process session management (BridgeProcessSession).
            "startProcess" -> startProcess(call, result)
            "writeStdin" -> writeStdin(call, result)
            "terminateProcess" -> terminateProcess(call, result)
            else -> result.notImplemented()
        }
    }

    // ---------------------------------------------------------------------
    // Command execution
    // ---------------------------------------------------------------------

    private fun executeCommand(call: MethodCall, result: MethodChannel.Result) {
        val command = call.argument<String>("command") ?: ""
        val cwd = call.argument<String>("cwd") ?: context.filesDir.absolutePath
        val timeout = call.argument<Number>("timeoutMillis")?.toLong() ?: DEFAULT_TIMEOUT_MS
        val env = decodeEnv(call.argument<Map<*, *>>("env"))
        val preferTermux = call.argument<Boolean>("useTermux") ?: true

        startExecService()
        executor.execute {
            val out = try {
                runInTermux(command, cwd, timeout, preferTermux) ?: runShell(command, cwd, timeout, env)
            } catch (e: Exception) {
                mapOf(
                    "exitCode" to -1,
                    "stdout" to "",
                    "stderr" to (e.message ?: e.toString()),
                    "timedOut" to false,
                )
            }
            mainHandler.post {
                stopExecService()
                result.success(out)
            }
        }
    }

    /**
     * Runs [command] in Termux, blocking this worker thread until the result
     * arrives or [timeoutMillis] passes.
     *
     * Returns null when Termux cannot take the command — not installed, the
     * runtime permission is missing or the service intent would not start — so
     * the caller falls back to the on-device shell. A timeout cannot stop the
     * Termux side, so the command may still be running there.
     */
    private fun runInTermux(
        command: String,
        cwd: String,
        timeoutMillis: Long,
        preferTermux: Boolean,
    ): Map<String, Any?>? {
        if (!preferTermux || !TermuxExec.isUsable(context)) return null

        val delivered = AtomicReference<Map<String, Any?>>()
        val latch = CountDownLatch(1)
        val requestId = TermuxExec.execute(context, command, cwd) { exitCode, stdout, stderr, errorMessage ->
            delivered.set(
                mapOf(
                    "exitCode" to exitCode,
                    "stdout" to stdout,
                    "stderr" to withTermuxError(stderr, errorMessage),
                    "timedOut" to false,
                ),
            )
            latch.countDown()
        }
        if (requestId < 0) return null

        if (latch.await(timeoutMillis, TimeUnit.MILLISECONDS)) return delivered.get()
        TermuxExec.cancel(requestId)
        return mapOf(
            "exitCode" to 124,
            "stdout" to "",
            "stderr" to "Timed out after ${timeoutMillis}ms waiting for Termux; " +
                "the command may still be running there.",
            "timedOut" to true,
        )
    }

    /** Termux reports its own failures (policy violation, bad path) as errmsg. */
    private fun withTermuxError(stderr: String, errorMessage: String?): String {
        if (errorMessage.isNullOrBlank()) return stderr
        return if (stderr.isBlank()) "Termux: $errorMessage" else "Termux: $errorMessage\n$stderr"
    }

    private fun runShell(
        command: String,
        cwd: String,
        timeout: Long,
        env: Map<String, String>?,
    ): Map<String, Any?> {
        val dir = File(cwd)
        if (!dir.exists() || !dir.isDirectory) {
            return mapOf(
                "exitCode" to 127,
                "stdout" to "",
                "stderr" to "Working directory does not exist: $cwd",
                "timedOut" to false,
            )
        }

        val process = ProcessBuilder(resolveShell(), "-c", command)
            .directory(dir)
            .redirectErrorStream(false)
            .also { if (env != null) it.environment().putAll(env) }
            .start()

        val out = StreamGobbler(process.inputStream).also { it.start() }
        val err = StreamGobbler(process.errorStream).also { it.start() }

        val finished = CountDownLatch(1)
        val waiter = Thread {
            try {
                process.waitFor()
            } catch (_: InterruptedException) {
                Thread.currentThread().interrupt()
            } finally {
                finished.countDown()
            }
        }.also { it.isDaemon = true; it.start() }

        val completed = finished.await(timeout, TimeUnit.MILLISECONDS)
        if (!completed) {
            process.destroy()
            waiter.join(1000)
            out.join(500)
            err.join(500)
            return mapOf(
                "exitCode" to 124,
                "stdout" to out.text(),
                "stderr" to err.text(),
                "timedOut" to true,
            )
        }
        out.join()
        err.join()
        return mapOf(
            "exitCode" to process.exitValue(),
            "stdout" to out.text(),
            "stderr" to err.text(),
            "timedOut" to false,
        )
    }

    /**
     * The shell used for on-device execution. Termux's bash is deliberately not
     * probed here: another app's private directory is not executable from this
     * process, Termux commands go through [TermuxExec] instead.
     */
    private fun resolveShell(): String = "/system/bin/sh"

    private fun shellInfo(): Map<String, Any?> = mapOf(
        "shell" to resolveShell(),
        "termuxInstalled" to TermuxExec.isInstalled(context),
        "termuxPermission" to TermuxExec.hasPermission(context),
        "termuxUsable" to TermuxExec.isUsable(context),
        "home" to context.filesDir.absolutePath,
    )

    /**
     * Asks for the `com.termux.permission.RUN_COMMAND` runtime permission and
     * answers with whether Termux can be used afterwards.
     */
    private fun requestTermuxPermission(result: MethodChannel.Result) {
        if (TermuxExec.hasPermission(context) || !TermuxExec.isInstalled(context)) {
            result.success(TermuxExec.hasPermission(context))
            return
        }
        if (pendingPermissionResult != null) {
            // A dialog is already up; only its caller is told the outcome.
            result.success(false)
            return
        }
        pendingPermissionResult = result
        Log.d(TAG, "Requesting Termux RUN_COMMAND permission")
        activity.requestPermissions(
            arrayOf(TermuxExec.PERMISSION_RUN_COMMAND),
            REQUEST_TERMUX_PERMISSION,
        )
    }

    /** Forwards the permission dialog outcome from [MainActivity]. */
    fun onPermissionResult(requestCode: Int, granted: Boolean) {
        if (requestCode != REQUEST_TERMUX_PERMISSION) return
        Log.d(TAG, "Termux RUN_COMMAND permission granted=$granted")
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
    }

    // ---------------------------------------------------------------------
    // Filesystem
    // ---------------------------------------------------------------------

    private fun readFile(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        if (path == null) {
            result.error("bad_args", "path is required", null)
            return
        }
        executor.execute {
            val text = try {
                File(path).readText()
            } catch (e: Exception) {
                null
            }
            mainHandler.post {
                if (text == null) {
                    result.error("read_failed", "Cannot read file: $path", null)
                } else {
                    result.success(text)
                }
            }
        }
    }

    private fun writeFile(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        if (path == null) {
            result.error("bad_args", "path is required", null)
            return
        }
        val content = call.argument<String>("content") ?: ""
        executor.execute {
            val ok = try {
                val file = File(path)
                file.parentFile?.mkdirs()
                file.writeText(content)
                true
            } catch (e: Exception) {
                false
            }
            mainHandler.post {
                if (ok) {
                    result.success(null)
                } else {
                    result.error("write_failed", "Cannot write file: $path", null)
                }
            }
        }
    }

    private fun deleteFile(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        if (path == null) {
            result.error("bad_args", "path is required", null)
            return
        }
        executor.execute {
            val ok = try {
                val file = File(path)
                !file.exists() || file.delete()
            } catch (e: Exception) {
                false
            }
            mainHandler.post {
                if (ok) result.success(null)
                else result.error("delete_failed", "Cannot delete file: $path", null)
            }
        }
    }

    private fun fileExists(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        if (path == null) {
            result.error("bad_args", "path is required", null)
            return
        }
        executor.execute {
            val exists = try {
                File(path).exists()
            } catch (e: Exception) {
                false
            }
            mainHandler.post { result.success(exists) }
        }
    }

    private fun createDirectory(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        if (path == null) {
            result.error("bad_args", "path is required", null)
            return
        }
        executor.execute {
            val ok = try { File(path).mkdirs() || File(path).isDirectory } catch (_: Exception) { false }
            mainHandler.post {
                if (ok) result.success(null)
                else result.error("create_failed", "Cannot create directory: $path", null)
            }
        }
    }

    private fun renameEntry(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        val newPath = call.argument<String>("newPath")
        if (path == null || newPath == null) {
            result.error("bad_args", "path and newPath are required", null)
            return
        }
        executor.execute {
            val ok = try {
                val destination = File(newPath)
                destination.parentFile?.mkdirs()
                !destination.exists() && File(path).renameTo(destination)
            } catch (_: Exception) { false }
            mainHandler.post {
                if (ok) result.success(null)
                else result.error("rename_failed", "Cannot rename: $path", null)
            }
        }
    }

    private fun deleteEntry(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        if (path == null) {
            result.error("bad_args", "path is required", null)
            return
        }
        executor.execute {
            val ok = try { val file = File(path); !file.exists() || file.deleteRecursively() } catch (_: Exception) { false }
            mainHandler.post {
                if (ok) result.success(null)
                else result.error("delete_failed", "Cannot delete: $path", null)
            }
        }
    }

    private fun listFiles(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        if (path == null) {
            result.error("bad_args", "path is required", null)
            return
        }
        executor.execute {
            val entries: List<Map<String, Any?>>? = try {
                val listed = File(path).listFiles() ?: emptyArray()
                listed
                    .sortedWith(compareByDescending<File> { it.isDirectory }.thenBy { it.name.lowercase() })
                    .map { f ->
                        mapOf(
                            "name" to f.name,
                            "path" to f.absolutePath,
                            "type" to if (f.isDirectory) "directory" else "file",
                            "size" to f.length(),
                            "modified" to f.lastModified(),
                        )
                    }
            } catch (e: Exception) {
                null
            }
            mainHandler.post {
                if (entries == null) {
                    result.error("list_failed", "Cannot list directory: $path", null)
                } else {
                    result.success(entries)
                }
            }
        }
    }

    // ---------------------------------------------------------------------
    // Foreground service (best effort; never blocks command execution)
    // ---------------------------------------------------------------------

    private fun startExecService() {
        try {
            val intent = Intent(context, ExecService::class.java)
                .setAction(ExecService.ACTION_START)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        } catch (_: Exception) {
            // Starting a foreground service can be disallowed in the background;
            // the command still runs without it.
        }
    }

    private fun stopExecService() {
        try {
            val intent = Intent(context, ExecService::class.java)
                .setAction(ExecService.ACTION_STOP)
            context.startService(intent)
        } catch (_: Exception) {
            // Ignore; the service stops itself on the next start attempt anyway.
        }
    }

    private fun decodeEnv(raw: Map<*, *>?): Map<String, String>? {
        if (raw == null) return null
        val out = HashMap<String, String>()
        for ((key, value) in raw) {
            if (key is String && value is String) out[key] = value
        }
        return out
    }

    // ---------------------------------------------------------------------
    // Process session management (BridgeProcessSession)
    // ---------------------------------------------------------------------

    private fun startProcess(call: MethodCall, result: MethodChannel.Result) {
        val command = call.argument<String>("command") ?: ""
        @Suppress("UNCHECKED_CAST")
        val args = (call.argument<List<String>>("arguments")) ?: emptyList()
        val cwd = call.argument<String>("cwd") ?: context.filesDir.absolutePath
        val env = decodeEnv(call.argument<Map<*, *>>("env"))

        val sessionId = UUID.randomUUID().toString()

        try {
            val cmdParts = mutableListOf<String>()
            // Use shell so pipelines/redirects work like executeCommand.
            cmdParts.add("/system/bin/sh")
            cmdParts.add("-c")
            val fullCmd = if (args.isEmpty()) {
                command
            } else {
                "$command ${args.joinToString(" ") { shellQuote(it) }}"
            }
            cmdParts.add(fullCmd)

            val pb = ProcessBuilder(cmdParts)
                .directory(File(cwd))
                .redirectErrorStream(false)

            if (env != null) {
                pb.environment().putAll(env)
            }

            val process = pb.start()
            val session = LongProcessSession(sessionId, process, messenger)
            sessions[sessionId] = session
            session.startStreaming(executor, mainHandler) { sessions.remove(sessionId) }

            Log.d(TAG, "Started process session=$sessionId cmd=$command")
            result.success(mapOf("sessionId" to sessionId))
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start process: ${e.message}", e)
            result.error("start_failed", "Cannot start process: ${e.message}", null)
        }
    }

    private fun writeStdin(call: MethodCall, result: MethodChannel.Result) {
        val sessionId = call.argument<String>("sessionId")
        val data = call.argument<String>("data") ?: ""
        if (sessionId == null) {
            result.error("bad_args", "sessionId is required", null)
            return
        }
        val session = sessions[sessionId]
        if (session == null) {
            result.error("not_found", "Session not found: $sessionId", null)
            return
        }
        try {
            session.writeStdin(data)
            result.success(null)
        } catch (e: Exception) {
            result.error("write_failed", "Cannot write to stdin: ${e.message}", null)
        }
    }

    private fun terminateProcess(call: MethodCall, result: MethodChannel.Result) {
        val sessionId = call.argument<String>("sessionId")
        if (sessionId == null) {
            result.error("bad_args", "sessionId is required", null)
            return
        }
        val session = sessions.remove(sessionId)
        if (session == null) {
            result.success(null) // Already gone.
            return
        }
        session.terminate()
        Log.d(TAG, "Terminated process session=$sessionId")
        result.success(null)
    }

    private fun shellQuote(s: String): String {
        return if (s.matches(Regex("^[a-zA-Z0-9_./-]+$"))) s
        else "'${s.replace("'", "'\\''")}'"
    }

    /** Reads a stream fully on its own thread so the process never blocks. */
    private class StreamGobbler(private val stream: InputStream) : Thread() {
        private val buffer = StringBuffer()

        override fun run() {
            try {
                stream.bufferedReader().useLines { lines ->
                    lines.forEach { line -> buffer.append(line).append('\n') }
                }
            } catch (_: Exception) {
                // Stream closed early (e.g. process destroyed on timeout).
            }
        }

        fun text(): String = buffer.toString()
    }

    companion object {
        private const val TAG = "AgentFlowRuntime"
        const val CHANNEL = "agentflow/runtime"
        const val REQUEST_TERMUX_PERMISSION = 0x5452
        private const val DEFAULT_TIMEOUT_MS = 60_000L
        private const val EVENT_CHANNEL_PREFIX = "agentflow/process_events"
    }
}

/**
 * A long-lived process with bidirectional stdin/stdout/stderr streaming.
 *
 * Created by [RuntimeManager.startProcess], it streams stdout/stderr chunks
 * via an EventChannel at `agentflow/process_events/<sessionId>` and accepts
 * stdin writes via MethodChannel calls.
 */
class LongProcessSession(
    private val sessionId: String,
    private val process: Process,
    messenger: BinaryMessenger,
) {
    private val eventChannel = EventChannel(messenger, "$EVENT_CHANNEL_PREFIX/$sessionId")
    private var eventSink: EventChannel.EventSink? = null
    @Volatile
    private var terminated = false

    fun startStreaming(
        executor: java.util.concurrent.ExecutorService,
        mainHandler: Handler,
        onExit: () -> Unit,
    ) {
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        // Stream stdout.
        executor.execute {
            try {
                process.inputStream.bufferedReader().use { reader ->
                    val buffer = CharArray(4096)
                    while (true) {
                        val read = reader.read(buffer)
                        if (read <= 0) break
                        val chunk = String(buffer, 0, read)
                        postEvent(mainHandler, mapOf("type" to "stdout", "data" to chunk))
                    }
                }
            } catch (_: Exception) {}
        }

        // Stream stderr.
        executor.execute {
            try {
                process.errorStream.bufferedReader().use { reader ->
                    val buffer = CharArray(4096)
                    while (true) {
                        val read = reader.read(buffer)
                        if (read <= 0) break
                        val chunk = String(buffer, 0, read)
                        postEvent(mainHandler, mapOf("type" to "stderr", "data" to chunk))
                    }
                }
            } catch (_: Exception) {}
        }

        // Wait for process exit.
        executor.execute {
            try {
                val exitCode = process.waitFor()
                postEvent(mainHandler, mapOf("type" to "exit", "exitCode" to exitCode))
            } catch (_: Exception) {
                if (!terminated) {
                    postEvent(mainHandler, mapOf("type" to "exit", "exitCode" to -1))
                }
            } finally {
                onExit()
            }
        }
    }

    fun writeStdin(data: String) {
        process.outputStream.write(data.toByteArray())
        process.outputStream.flush()
    }

    fun terminate() {
        terminated = true
        try {
            process.destroy()
            if (!process.waitFor(3, java.util.concurrent.TimeUnit.SECONDS)) {
                process.destroyForcibly()
            }
        } catch (_: Exception) {}
    }

    private fun postEvent(mainHandler: Handler, event: Map<String, Any?>) {
        mainHandler.post {
            eventSink?.success(event)
        }
    }

    companion object {
        private const val EVENT_CHANNEL_PREFIX = "agentflow/process_events"
    }
}
