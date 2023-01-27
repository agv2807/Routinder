import Vapor
import Fluent

extension Message {
    struct Migration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Message.schema)
                .id()
                .field("message", .string, .required)
                .field("user_id", .uuid, .required, .references("users", "id"))
                .field("date", .string)
                .field("chat_id", .uuid, .required, .references("chats", "id"))
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(TestMessage.schema).delete()
        }
    }
}

