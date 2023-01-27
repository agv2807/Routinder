import Fluent

extension TestMessage {
    struct Migration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(TestMessage.schema)
                .id()
                .field("message", .string, .required)
                .field("user_id", .uuid, .required, .references("users", "id"))
                .field("date", .date)
                .field("chat_id", .string)
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(TestMessage.schema).delete()
        }
    }
}
