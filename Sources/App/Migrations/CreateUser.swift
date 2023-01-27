import Vapor
import Fluent

struct CreateUser: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        let scheme = database.schema(User.schema)
            .id()
            .field("name", .string, .required)
            .field("login", .string, .required)
            .field("password", .string, .required)
            .field("image", .string)
            .unique(on: "login")
            
        try await scheme.create()
    }
    
    func revert(on database: Database) async throws {
       try await database.schema(User.schema).delete()
    }
    
}
