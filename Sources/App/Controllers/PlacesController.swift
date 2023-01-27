import Fluent
import Vapor

struct PlacesController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let placesGroup = routes.grouped("places")
        placesGroup.get(use: getAllHandler)
        placesGroup.get(":productID", use: getHandler)
        
        let tokenProtected = placesGroup.grouped(UserToken.authenticator())
        tokenProtected.post(use: createHandler)
        tokenProtected.delete(":productID", use: deleteHandler)
        tokenProtected.put(":productID", use: updateHandler)
    }
    
    func createHandler(_ req: Request) async throws -> Place {
        guard let place = try? req.content.decode(Place.self) else {
            throw Abort(.custom(code: 499, reasonPhrase: "ЭЭЭ че делаешь, формат данных неправильный бро"))
        }
        
        try await place.save(on: req.db)
        return place
    }
    
    func getAllHandler(_ req: Request) async throws -> [Place] {
        let places = try await Place.query(on: req.db).all()
        return places
    }
    
    func getHandler(_ req: Request) async throws -> Place {
        guard let place = try await Place.find(req.parameters.get("productID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        return place
    }
    
    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        guard let place = try await Place.find(req.parameters.get("productID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await place.delete(on: req.db)
        
        return .ok
    }
    
    func updateHandler(_ req: Request) async throws -> Place {
        guard let place = try await Place.find(req.parameters.get("productID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let updatedPlace = try req.content.decode(Place.self)
        
        place.title = updatedPlace.title
        place.description = updatedPlace.description
        
        try await place.save(on: req.db)
        
        return place
    }
    
}
