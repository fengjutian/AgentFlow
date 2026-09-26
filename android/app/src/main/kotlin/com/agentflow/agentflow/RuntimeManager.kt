package com.agentflow.agentflow

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.InputStream
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Kotlin side of the `agentflow/runtime` MethodChannel.
 *
 * Implements the same contract as the Dart `Runtime` abstraction so the Agent
 * Core cannot tell whether it is running on-device, in Termux or (later) over
 * SSH. Commands run through a shell with a hard timeout; a foreground service is
 * held for the duration so the OS is less likely to kill a long agent task when
 * the app is backgrounded.
 *
 * Shell selection prefers Termux's bash when this process can actually execute
 * it and falls back to the system shell. Wiring the full Termux `RUN_COMMAND`
 * intent (which requires Termux to be installed and its runtime permission) is a
 * documented next step; the fallback already gives a working on-device shell.
 */
class RuntimeManager(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newCachedThreadPool()

    fun attach() {
        channel.setMethodCallHandler(this)
    }

    fun detach() {
        channel.setMethodCallHandler(null)
        executor.shutdownNow()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> result.success(true)
            "shellInfo" -> result.success(shellInfo())
            "executeCommand" -> executeCommand(call, result)
            "readFile" -> readFile(call, result)
            "writeFile" -> writeFile(call, result)
            "fileExists" -> fileExists(call, result)
            "listFiles" -> listFiles(call, result)
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

        startExecService()
        executor.execute {
            val out = try {
                runShell(command, cwd, timeout, env)
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
     * Chooses a shell. Termux's bash is used only when this process can actually
     * execute it (non-root apps normally cannot reach another app's private data
     * dir, so this cleanly falls back to the system shell).
     */
    private fun resolveShell(): String {
        val termuxBash = File("/data/data/com.termux/files/usr/bin/bash")
        if (termuxBash.canExecute()) return termuxBash.absolutePath
        return "/system/bin/sh"
    }

    private fun shellInfo(): Map<String, Any?> = mapOf(
        "shell" to resolveShell(),
        "termuxInstalled" to isTermuxInstalled(),
        "home" to context.filesDir.absolutePath,
    )

    private fun isTermuxInstalled(): Boolean = try {
        context.packageManager.getPackageInfo("com.termux", 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
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
        const val CHANNEL = "agentflow/runtime"
        private const val DEFAULT_TIMEOUT_MS = 60_000L
    }
}
