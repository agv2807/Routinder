import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    app.databases.use(.postgres(
        hostname: Environment.get("PGHOST") ?? "localhost",
        port: Environment.get("PGPORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
        username: Environment.get("PGUSER") ?? "vapor_username",
        password: Environment.get("PGPASSWORD") ?? "vapor_password",
        database: Environment.get("PGDATABASE") ?? "vapor_database"
    ), as: .psql)
    
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = Int(Environment.get("PORT") ?? "8080")!
    
    app.migrations.add(CreateUser())
    app.migrations.add(Chat.Migration())
    app.migrations.add(Message.Migration())
    app.migrations.add(TestMessage.Migration())
    app.migrations.add(CreatePlace())
    app.migrations.add(UserToken.Migration())
    
    try app.autoMigrate().wait()

    // register routes
    try routes(app)
}
