import Vapor
import Fluent

final class Message: Model, Content {
    static var schema: String = "messages"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "message")
    var message: String
    
    @Parent(key: "user_id")
    var user: User
    
    @Field(key: "date")
    var date: String
    
    @Parent(key: "chat_id")
    var chat: Chat
    
    init() { }
    
    init(
        id: UUID? = nil,
        message: String,
        userId: User.IDValue,
        date: String,
        chatId: Chat.IDValue
    ) {
        self.id = id
        self.message = message
        self.$user.id = userId
        self.date = date
        self.$chat.id = chatId
    }
    
    
    struct Public: Content {
        let id: UUID?
        let message: String
        let user: User.Public
        let date: String
        let chatId: String?
    }
    
    func toPublic(_ db: Database) async throws -> Public {
        let user = try await self.$user.get(on: db)
        return .init(
            id: id,
            message: message,
            user: user.toPublic,
            date: date,
            chatId: $chat.id.uuidString
        )
    }
}
