import Vapor
import Fluent
import Foundation

final class User: Model, Content {
    static let schema = "users"
    
    @ID
    var id: UUID?
    @Field(key: "name") var name: String
    @Field(key: "login") var login: String
    @Field(key: "password") var password: String
    @OptionalField(key: "image") var image: String?
    
    final class Public: Content {
        var id: UUID?
        var name: String
        var login: String
        var image: String?
        
        init(
            id: UUID?,
            name: String,
            login: String,
            image: String?
        ) {
            self.id = id
            self.name = name
            self.login = login
            self.image = image
        }
    }
    
    final class PublicUserWithToken: Content {
        let user: Public
        let token: String
        
        init(user: Public, token: String) {
            self.user = user
            self.token = token
        }
    }
    
}

extension User {
    func toPublic(with token: String) -> PublicUserWithToken {
        .init(user: self.toPublic, token: token)
    }
    
    var toPublic: Public {
        .init(
            id: self.id,
            name: self.name,
            login: self.login,
            image: self.image
        )
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$login
    static let passwordHashKey = \User.$password
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}

extension User {
    func generateToken() throws -> UserToken {
        try .init(
            value: [UInt8].random(count: 16).base64,
            userID: self.requireID()
        )
    }
}
