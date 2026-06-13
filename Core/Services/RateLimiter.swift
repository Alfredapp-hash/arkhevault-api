import Foundation

// MARK: - Rate Limiter
class RateLimiter {
    private let maxRequestsPerMinute: Int
    private let maxRequestsPerHour: Int
    private var requestTimestamps: [Date] = []
    private var hourlyTimestamps: [Date] = []
    
    private let queue = DispatchQueue(label: "com.arkheholdings.vault.ratelimiter", attributes: .concurrent)
    
    init(maxRequestsPerMinute: Int, maxRequestsPerHour: Int) {
        self.maxRequestsPerMinute = maxRequestsPerMinute
        self.maxRequestsPerHour = maxRequestsPerHour
    }
    
    /// Check if a request is allowed
    func checkRateLimit() -> (allowed: Bool, resetTime: Date?) {
        return queue.sync {
            let now = Date()
            
            // Clean up old timestamps
            cleanUpTimestamps(now: now)
            
            // Check minute limit
            if requestTimestamps.count >= maxRequestsPerMinute {
                let resetTime = requestTimestamps.first?.addingTimeInterval(60)
                return (false, resetTime)
            }
            
            // Check hour limit
            if hourlyTimestamps.count >= maxRequestsPerHour {
                let resetTime = hourlyTimestamps.first?.addingTimeInterval(3600)
                return (false, resetTime)
            }
            
            // Request allowed - record timestamp
            requestTimestamps.append(now)
            hourlyTimestamps.append(now)
            
            return (true, nil)
        }
    }
    
    /// Record a successful request
    func recordRequest() {
        queue.sync {
            let now = Date()
            requestTimestamps.append(now)
            hourlyTimestamps.append(now)
        }
    }
    
    /// Reset rate limiter (for testing)
    func reset() {
        queue.sync {
            requestTimestamps.removeAll()
            hourlyTimestamps.removeAll()
        }
    }
    
    private func cleanUpTimestamps(now: Date) {
        // Remove timestamps older than 1 minute
        let oneMinuteAgo = now.addingTimeInterval(-60)
        requestTimestamps = requestTimestamps.filter { $0 > oneMinuteAgo }
        
        // Remove timestamps older than 1 hour
        let oneHourAgo = now.addingTimeInterval(-3600)
        hourlyTimestamps = hourlyTimestamps.filter { $0 > oneHourAgo }
    }
    
    /// Get current usage statistics
    func getUsageStats() -> (requestsThisMinute: Int, requestsThisHour: Int) {
        return queue.sync {
            return (requestTimestamps.count, hourlyTimestamps.count)
        }
    }
}

// MARK: - Rate Limit Error
enum RateLimitError: LocalizedError {
    case tooManyRequests(resetTime: Date)
    case serviceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .tooManyRequests(let resetTime):
            return "Rate limit exceeded. Please try again at \(resetTime.formatted(date: .abbreviated, time: .shortened))"
        case .serviceUnavailable:
            return "Service temporarily unavailable. Please try again later."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .tooManyRequests:
            return "Wait a few minutes before making another request"
        case .serviceUnavailable:
            return "Check your internet connection and try again"
        }
    }
}

// MARK: - API Request Manager
class APIRequestManager {
    static let shared = APIRequestManager()
    
    private let rateLimiter: RateLimiter
    
    private init() {
        let config = Configuration.shared
        self.rateLimiter = RateLimiter(
            maxRequestsPerMinute: config.maxAPIRequestsPerMinute,
            maxRequestsPerHour: config.maxAPIRequestsPerHour
        )
    }
    
    /// Execute API request with rate limiting
    func executeRequest<T>(_ request: () async throws -> T) async throws -> T {
        guard Configuration.shared.rateLimitingEnabled else {
            return try await request()
        }
        
        // Check rate limit
        let (allowed, resetTime) = rateLimiter.checkRateLimit()
        
        if !allowed, let resetTime = resetTime {
            throw RateLimitError.tooManyRequests(resetTime: resetTime)
        }
        
        // Execute request
        do {
            let result = try await request()
            // Request successful - no need to record separately (checkRateLimit already did)
            return result
        } catch let error as RateLimitError {
            throw error
        } catch {
            // Request failed - still count towards rate limit
            return try await request()
        }
    }
    
    /// Get current API usage statistics
    func getUsageStats() -> (requestsThisMinute: Int, requestsThisHour: Int) {
        return rateLimiter.getUsageStats()
    }
    
    /// Reset rate limiter (for testing)
    func resetRateLimiter() {
        rateLimiter.reset()
    }
}