import Vapor
import Fluent

final class TestMessage: Model, Content {    
    static var schema: String = "test_message"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "message")
    var message: String
    
    @Parent(key: "user_id")
    var user: User
    
    @Field(key: "date")
    var date: Date
    
    @Field(key: "chat_id")
    var chat: String
    
    init() { }
    
    init(
        id: UUID? = nil,
        message: String,
        userId: User.IDValue,
        date: Date,
        chatID: String
    ) {
        self.id = id
        self.message = message
        self.$user.id = userId
        self.date = date
        self.chat = chatID
    }
    
}
