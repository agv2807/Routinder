import Vapor
import Fluent

final class Chat: Model, Content {
    static var schema: String = "chats"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "user_ids")
    var userIds: Array<String>
    
    init() { }
    
    init(
        id: UUID? = nil,
        userIds: Array<String>
    ) {
        self.id = id
        self.userIds = userIds
    }
    
    struct Public: Content {
        let id: UUID?
        let lastMessage: Message.Public?
        let users: [User.Public]
    }
    
    func toPublic(_ db: Database) async throws -> Public {
        let lastMessage: Message? = try await Message.query(on: db).filter("chat_id", .equal, id?.lowercassed()).all().last
        let users: [User.Public] = try await userIds.map {
            try await User.find(.init(uuidString: $0), on: db)?.toPublic
        }.compactMap { $0 }
        return try await .init(id: id, lastMessage: lastMessage?.toPublic(db), users: users)
    }
}

extension UUID {
    func lowercassed() -> UUID? {
        .init(uuidString: uuidString.lowercased())
    }
}
