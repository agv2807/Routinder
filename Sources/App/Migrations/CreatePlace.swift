import Fluent
import Vapor

struct CreatePlace: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        let scheme = database.schema(Place.schema)
            .id()
            .field("title", .string, .required)
            .field("description", .string, .required)
            .field("lat", .string)
            .field("lon", .string)
            .field("images", .array(of: .string))
            
        try await scheme.create()
    }
    
    func revert(on database: Database) async throws {
       try await database.schema(Place.schema).delete()
    }
    
}
