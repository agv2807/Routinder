import Fluent
import Vapor

private final class OpenSockets {
    var value: [String: [IdentWebSocket]] = [:]
    
    struct IdentWebSocket {
        let id = UUID()
        let socket: WebSocket
    }
}

struct ChatController: RouteCollection {
    
    private let openSockets = OpenSockets()
    
    func boot(routes: RoutesBuilder) throws {
        let chatsGroup = routes.grouped("chats")
        
        let tokenProtected = chatsGroup.grouped(UserToken.authenticator())
        tokenProtected.post(use: createChat)
        tokenProtected.get(use: getAllChats)
        tokenProtected.post(":chatID", "messages", use: postTestMessage)
        tokenProtected.get(":chatID", "messages", use: getMessagesHandler)
        tokenProtected.webSocket("socket", onUpgrade: openSocket)
    }
    
    func createChat(_ req: Request) async throws -> Chat.Public {
        struct CreateChat: Codable {
            let user_id: String
        }
        
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized)
        }

        guard let userFor = try? req.content.decode(CreateChat.self) else {
            throw Abort(.noContent)
        }
        
        let chat = Chat(
            id: .init(),
            userIds: [user.id?.uuidString, userFor.user_id].compactMap { $0?.lowercased() }
        )
        
        try await chat.save(on: req.db)
        
        return try await chat.toPublic(req.db)
    }
    
    func getAllChats(_ req: Request) async throws -> [Chat.Public] {
        guard
            let userId = try? req.auth.get(User.self)?.requireID().uuidString.lowercased()
        else {
            throw Abort(.notFound)
        }
        let chats = try await Chat.query(on: req.db).all().filter { $0.userIds.contains(userId) }
        return try await chats.map { try await $0.toPublic(req.db) }
    }
    
    func postTestMessage(_ req: Request) async throws -> Message.Public {
        struct MessageRequest: Codable {
            let message: String
        }
        
        guard
            let userId = try? req.auth.get(User.self)?.requireID().lowercassed(),
            let chat = try? await Chat.find(req.parameters.get("chatID"), on: req.db)
        else {
            throw Abort(.notFound)
        }
        let message = try req.content.decode(MessageRequest.self)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let dateString = dateFormatter.string(from: .init())
        
        let messageDB = try Message(
            id: .init(),
            message: message.message,
            userId: userId,
            date: dateString,
            chatId: chat.requireID()
        )
        
        try await messageDB.save(on: req.db)
        
        let messagePublic = try await messageDB.toPublic(req.db)
        
        let jsonData = try JSONEncoder().encode(messagePublic)
        let messageJson = String(data: jsonData, encoding: .utf8) ?? ""
        
        openSockets.value.filter { $0.key == userId.uuidString }.values.forEach {
            $0.forEach { st in st.socket.send(messageJson) }
        }
        
        return messagePublic
    }
    
    func getMessagesHandler(_ req: Request) async throws -> [Message.Public] {
        guard
            let chatIdString = req.parameters.get("chatID"),
            let chat = try await Chat.find(.init(uuidString: chatIdString), on: req.db)
        else {
            throw Abort(.noContent)
        }
        let messages = try await Message.query(on: req.db).filter("chat_id", .equal, chat.requireID().lowercassed()).all()
        
        return try await messages.map { try await $0.toPublic(req.db) }
    }
    
    func openSocket(_ req: Request, _ st: WebSocket) {
        guard
            let userId = try? req.auth.get(User.self)?.requireID().uuidString
        else {
            _ = st.close(code: .unacceptableData)
            return
        }
        let socketInfo = OpenSockets.IdentWebSocket(socket: st)
        
        st.onClose.whenComplete { result in
            openSockets.value[userId]?.removeAll { $0.id == socketInfo.id }
        }
        if openSockets.value.contains(where: { (key: String, _) in key == userId }) {
            openSockets.value[userId]?.append(socketInfo)
        } else {
            openSockets.value[userId] = [socketInfo]
        }
    }
}

extension Array {
    func map<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        if count == 0 { return [] }
        var arrayOut: [T] = []
        for i in 0...count-1 {
            let newValue = try await transform(self[i])
            arrayOut.append(newValue)
        }
        return arrayOut
    }
}
