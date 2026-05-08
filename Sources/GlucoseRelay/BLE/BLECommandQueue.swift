import Foundation

actor BLECommandQueue {
    private var queue: [BLECommand] = []
    private var isProcessing = false
    private let maxRetries = 3
    private var currentRetryCount = 0
    private var currentCommand: BLECommand?

    var onExecute: (@Sendable (BLECommand) async -> Bool)?

    func enqueue(_ command: BLECommand) {
        queue.append(command)
        processNext()
    }

    func enqueue(_ commands: [BLECommand]) {
        queue.append(contentsOf: commands)
        processNext()
    }

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

    func handleSuccess() {
        isProcessing = false
        currentCommand = nil
        currentRetryCount = 0
        processNext()
    }

    func handleFailure() {
        currentRetryCount += 1
        if currentRetryCount <= maxRetries, let command = currentCommand {
            queue.insert(command, at: 0)
        }
        isProcessing = false
        currentCommand = nil
        processNext()
    }

    func clear() {
        queue.removeAll()
        isProcessing = false
        currentCommand = nil
        currentRetryCount = 0
    }

    func handleWriteComplete(success: Bool) {
        if success {
            handleSuccess()
        } else {
            handleFailure()
        }
    }

    func handleReadComplete(data: Data?) {
        handleSuccess()
    }

    func handleDescriptorWriteComplete(success: Bool) {
        if success {
            handleSuccess()
        } else {
            handleFailure()
        }
    }
}
