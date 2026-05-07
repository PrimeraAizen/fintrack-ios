import Testing
import Foundation
@testable import FinTrackIOS

@Suite("Codable Round-trips")
struct CodableTests {

    private let encoder = JSONEncoder.finTrack
    private let decoder = JSONDecoder.finTrack

    private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
        let data = try encoder.encode(value)
        return try decoder.decode(T.self, from: data)
    }

    @Test func userRoundTrip() throws {
        let decoded = try roundTrip(User.preview)
        #expect(decoded == User.preview)
    }

    @Test func accountRoundTrip() throws {
        let decoded = try roundTrip(Account.preview)
        #expect(decoded == Account.preview)
    }

    @Test func categoryRoundTrip() throws {
        let decoded = try roundTrip(Category.previewExpense)
        #expect(decoded == Category.previewExpense)
    }

    @Test func transactionRoundTrip() throws {
        let decoded = try roundTrip(Transaction.preview)
        #expect(decoded == Transaction.preview)
    }

    @Test func budgetRoundTrip() throws {
        let decoded = try roundTrip(Budget.preview)
        #expect(decoded == Budget.preview)
    }

    @Test func transferRoundTrip() throws {
        let decoded = try roundTrip(Transfer.preview)
        #expect(decoded == Transfer.preview)
    }

    @Test func savingGoalRoundTrip() throws {
        let decoded = try roundTrip(SavingGoal.preview)
        #expect(decoded == SavingGoal.preview)
    }

    @Test func accountTypeOtherDecodes() throws {
        let json = #"{"id":"00000000-0000-0000-0000-000000000099","user_id":"00000000-0000-0000-0000-000000000001","name":"Legacy","type":"other","currency":"KZT","balance":0,"created_at":"2026-05-01T00:00:00.000Z"}"#
        let account = try decoder.decode(Account.self, from: Data(json.utf8))
        #expect(account.type == .other)
    }

    @Test func unknownAccountTypeFallback() throws {
        // A backend client that returns a future unknown type should not crash.
        // Current behaviour: `Codable` throws on unknown raw value — this test
        // documents the expected failure so we can catch it before it hits prod.
        let json = #"{"id":"00000000-0000-0000-0000-000000000099","user_id":"00000000-0000-0000-0000-000000000001","name":"Future","type":"future_type","currency":"KZT","balance":0,"created_at":"2026-05-01T00:00:00.000Z"}"#
        #expect(throws: (any Error).self) {
            _ = try decoder.decode(Account.self, from: Data(json.utf8))
        }
    }

    @Test func decimalPreservedThroughJson() throws {
        let original = Transaction.preview
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Transaction.self, from: data)
        #expect(decoded.amount == original.amount)
        #expect(decoded.convertedAmount == original.convertedAmount)
    }

    @Test func snakeCaseKeysDecoded() throws {
        let json = #"{"id":"00000000-0000-0000-0000-000000000010","user_id":"00000000-0000-0000-0000-000000000001","name":"Card","type":"card","currency":"USD","balance":100,"created_at":"2026-01-01T00:00:00.000Z"}"#
        let account = try decoder.decode(Account.self, from: Data(json.utf8))
        #expect(account.userID == User.preview.id)
    }

    @Test func iso8601WithFractionalSecondsDecodes() throws {
        let json = #"{"id":"00000000-0000-0000-0000-000000000001","email":"a@b.com","base_currency":"USD","created_at":"2026-05-01T12:00:00.123Z"}"#
        let user = try decoder.decode(User.self, from: Data(json.utf8))
        #expect(user.createdAt.timeIntervalSince1970 > 0)
    }

    @Test func iso8601WithoutFractionalSecondsDecodes() throws {
        let json = #"{"id":"00000000-0000-0000-0000-000000000001","email":"a@b.com","base_currency":"USD","created_at":"2026-05-01T12:00:00Z"}"#
        let user = try decoder.decode(User.self, from: Data(json.utf8))
        #expect(user.createdAt.timeIntervalSince1970 > 0)
    }
}
