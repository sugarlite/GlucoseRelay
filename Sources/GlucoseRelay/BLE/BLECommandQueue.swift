import Foundation

/// BLE 命令队列 / BLE command queue
///
/// 串行化 BLE 操作，解决 iOS CoreBluetooth 并发写入限制。
/// Serializes BLE operations to work around iOS CoreBluetooth concurrent write limitations.
actor BLECommandQueue {
    private var queue: [BLECommand] = []
    private var isProcessing = false
    private let maxRetries = 3
    private var currentRetryCount = 0
    private var currentCommand: BLECommand?

    /// 命令执行回调 / Command execution callback
    var onExecute: (@Sendable (BLECommand) async -> Bool)?

    /// 入队单个命令 / Enqueue a single command
    func enqueue(_ command: BLECommand) {
        queue.append(command)
        processNext()
    }

    /// 入队多个命令 / Enqueue multiple commands
    func enqueue(_ commands: [BLECommand]) {
        queue.append(contentsOf: commands)
        processNext()
    }

    /// 处理队列中的下一个命令 / Process next command in queue
    func processNext() {
        guard !isProcessing, !queue.isEmpty else { return }

        isProcessing = true
        currentRetryCount = 0
        let command = queue.removeFirst()
        currentCommand = command

        Task {
            let success = await onExecute?(command) ?? false
            if success {
                handleSuccess()
            } else {
                handleFailure()
            }
        }
    }

    /// 处理成功回调 / Handle success callback
    func handleSuccess() {
        isProcessing = false
        currentCommand = nil
        currentRetryCount = 0
        processNext()
    }

    /// 处理失败回调，支持重试 / Handle failure callback with retry support
    func handleFailure() {
        currentRetryCount += 1
        if currentRetryCount <= maxRetries, let command = currentCommand {
            queue.insert(command, at: 0)
        }
        isProcessing = false
        currentCommand = nil
        processNext()
    }

    /// 清空队列 / Clear the queue
    func clear() {
        queue.removeAll()
        isProcessing = false
        currentCommand = nil
        currentRetryCount = 0
    }

    /// 处理写入完成事件 / Handle write completion event
    func handleWriteComplete(success: Bool) {
        if success {
            handleSuccess()
        } else {
            handleFailure()
        }
    }

    /// 处理读取完成事件 / Handle read completion event
    func handleReadComplete(data: Data?) {
        handleSuccess()
    }

    /// 处理描述符写入完成事件 / Handle descriptor write completion event
    func handleDescriptorWriteComplete(success: Bool) {
        if success {
            handleSuccess()
        } else {
            handleFailure()
        }
    }
}
