import Foundation

/// Fixed-capacity ring buffer with O(1) append. Used by analyzers for sliding-window calculations.
struct RingBuffer<T> {
    private var buffer: [T?]
    private var writeIndex = 0
    private(set) var count = 0
    let capacity: Int

    init(capacity: Int) {
        precondition(capacity > 0, "RingBuffer capacity must be > 0")
        self.capacity = capacity
        self.buffer = Array(repeating: nil, count: capacity)
    }

    /// Whether the buffer has been fully filled at least once
    var isFull: Bool { count >= capacity }

    /// Append an element, overwriting the oldest if full
    mutating func append(_ element: T) {
        buffer[writeIndex] = element
        writeIndex = (writeIndex + 1) % capacity
        if count < capacity { count += 1 }
    }

    /// Return the last `n` elements in chronological order
    func last(_ n: Int) -> [T] {
        let take = min(n, count)
        guard take > 0 else { return [] }
        var result: [T] = []
        result.reserveCapacity(take)
        let startIdx = (writeIndex - take + capacity) % capacity
        for i in 0..<take {
            let idx = (startIdx + i) % capacity
            if let val = buffer[idx] {
                result.append(val)
            }
        }
        return result
    }

    /// Return all elements in chronological order
    func toArray() -> [T] {
        return last(count)
    }

    /// Most recently added element
    var latest: T? {
        guard count > 0 else { return nil }
        let idx = (writeIndex - 1 + capacity) % capacity
        return buffer[idx]
    }

    /// Clear all stored elements
    mutating func reset() {
        buffer = Array(repeating: nil, count: capacity)
        writeIndex = 0
        count = 0
    }
}
