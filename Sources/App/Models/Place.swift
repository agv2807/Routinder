import Fluent
import Vapor
import Foundation

final class Place: Model, Content {
    static var schema: String = "places"
    
    @ID
    var id: UUID?
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "description")
    var description: String
    
    @Field(key: "lon")
    var lon: String
    
    @Field(key: "lat")
    var lat: String
    
    @Field(key: "images")
    var images: Array<String>
    
    init() { }
    
    init(
        id: UUID? = nil,
        title: String,
        description: String,
        lon: String,
        lat: String,
        images: Array<String>
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.lon = lon
        self.lat = lat
        self.images = images
    }
    
}
