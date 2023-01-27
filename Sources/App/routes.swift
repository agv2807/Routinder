import Fluent
import Vapor

func routes(_ app: Application) throws {
    
    app.get { req async in
        "It works!"
    }
    
    try app.register(collection: PlacesController())
    try app.register(collection: UsersController())
    try app.register(collection: TestChatController())
    try app.register(collection: ChatController())
    
}
