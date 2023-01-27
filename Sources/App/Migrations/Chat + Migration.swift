import Vapor
import Fluent

extension Chat {
    struct Migration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Chat.schema)
                .id()
                .field("user_ids", .array(of: .string))
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(TestMessage.schema).delete()
        }
    }
}

