import Fluent
import Vapor

struct TestChatController: RouteCollection {
    
    private let openTestSockets = TestOpenSockets()
    
    func boot(routes: RoutesBuilder) throws {
        let chatsGroup = routes.grouped("chats")
        
        // chatsGroup.get(use: getAllChats)
        // MARK: - TEST
        let testGroup = chatsGroup.grouped("test")
        testGroup.webSocket(onUpgrade: openSocket)
        
        let tokenProtected = testGroup.grouped(UserToken.authenticator())
        tokenProtected.post("message", use: postTestMessage)
        tokenProtected.get("messages", use: getMessagesHandler)
    }
    
    struct TestChat: Content {
        let id: String
        let lastMessage: TestMessage?
        
        struct Public: Content {
            let id: String
            let lastMessage: TestMessage.Public?
        }
        
        func toPublic(_ db: Database) async throws -> Public {
            try await .init(id: id, lastMessage: lastMessage?.toPublic(db))
        }
    }
    
    func getAllChats(_ req: Request) async throws -> [TestChat.Public] {
        let lastMessage = try await TestMessage.query(on: req.db).all().last
        let testChat = TestChat(id: "test", lastMessage: lastMessage)
        return [try await testChat.toPublic(req.db)]
    }
    
    func openSocket(_ req: Request, _ st: WebSocket) {
        openTestSockets.value.append(st)
    }
    
    func postTestMessage(_ req: Request) async throws -> TestMessage.Public {
        struct MessageRequest: Codable {
            let message: String
        }
        
        guard let user = req.auth.get(User.self) else {
            throw Abort(.notFound)
        }
        let message = try req.content.decode(MessageRequest.self)

        let messageDB = try TestMessage(
            id: .init(),
            message: message.message,
            userId: user.requireID(),
            date: .init(),
            chatID: "test"
        )
        
        try await messageDB.save(on: req.db)
        
        let messagePublic = try await messageDB.toPublic(req.db)
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        let jsonData = try jsonEncoder.encode(messagePublic)
        let messageJson = String(data: jsonData, encoding: .utf8)!
        
        openTestSockets.value.forEach {
            $0.send(messageJson)
        }
        
        return messagePublic
    }
    
    
    func getMessagesHandler(_ req: Request) async throws -> [TestMessage.Public] {
        let messages = try await TestMessage.query(on: req.db).all()
        return try await messages.map { try await $0.toPublic(req.db) }
    }
    
}

extension TestMessage {
    
    func toPublic(_ db: Database) async throws -> Public {
        let user = try await self.$user.get(on: db)
        return .init(
            id: id,
            message: message,
            user: user.toPublic,
            date: date,
            chatId: chat
        )
    }
    
    struct Public: Content {
        let id: UUID?
        let message: String
        let user: User.Public
        let date: Date
        let chatId: String
    }
}

final class TestOpenSockets {
    
    var value: [WebSocket] = []
    
}
