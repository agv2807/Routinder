import Vapor
import Fluent

struct UsersController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let usersGroup = routes.grouped("users")
        usersGroup.post(use: createHandler)
        usersGroup.get(use: getAllHandler)
        usersGroup.get(":id", use: getHandler)
        usersGroup.post("auth", use: loginHandler)
        
        let tokenProtected = usersGroup.grouped(UserToken.authenticator())
        tokenProtected.get("me") { req -> User in
            try req.auth.require(User.self)
        }
        tokenProtected.put(use: updateHandler)
    }
    
    func createHandler(_ req: Request) async throws -> User.PublicUserWithToken {
        let user = try req.content.decode(User.self)
          
        user.password = try Bcrypt.hash(user.password)
        try await user.save(on: req.db)
        
        let token = try user.generateToken()
        try await token.save(on: req.db)
        
        return user.toPublic(with: token.value)
    }
    
    func updateHandler(_ req: Request) async throws -> User.Public {
        struct UpdateUserInfo: Codable {
            let name: String?
            let image: String?
        }
        
        guard let user = req.auth.get(User.self) else {
            throw Abort(.notFound)
        }
        let userUpdate = try req.content.decode(UpdateUserInfo.self)
          
        user.name = userUpdate.name ?? user.name
        user.image = userUpdate.image
        
        try await user.save(on: req.db)
        
        return user.toPublic
    }
    
    func getAllHandler(_ req: Request) async throws -> [User.Public] {
        let users = try await User.query(on: req.db).all()
        
        return await users.map { $0.toPublic }
    }
    
    func getHandler(_ req: Request) async throws -> User.Public {
        guard let user = try await User.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        return user.toPublic
    }
    
    func loginHandler(_ req: Request) async throws -> User.PublicUserWithToken {
        let userDTO = try req.content.decode(AuthUserDTO.self)
        guard
            let user = try await User.query(on: req.db)
                .filter("login", .equal, userDTO.login)
                .first()
        else {
            throw Abort(.notFound)
        }
        
        let isPassEqual = try Bcrypt.verify(userDTO.password, created: user.password)
        guard isPassEqual else { throw Abort(.unauthorized) }
        
        let token = try user.generateToken()
        try await token.save(on: req.db)
        
        return user.toPublic(with: token.value)
    }
    
}

struct AuthUserDTO: Content {
    let login: String
    let password: String
}
