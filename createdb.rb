# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
#######################################################################################

# Database schema - this should reflect your domain model

# New domain model - adds users
DB.create_table! :hoods do
  primary_key :id
  String :title
  String :description, text: true
  String :walkability
  String :nightlife
  String :location
end
DB.create_table! :rsvps do
  primary_key :id
  foreign_key :hood_id
  foreign_key :user_id
  Boolean :going
  String :comments, text: true
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
end

# Insert initial (seed) data
hoods_table = DB.from(:hoods)

hoods_table.insert(title: "Downtown / Waterfront", 
                    description: "If you’re looking for your own slice of New York City on the West Coast, downtown Seattle is a great place to start. Everything you could ever want from a big city is packed into Seattle’s very geographically manageable downtown. Catch a concert at Benaroya Hall, or enjoy a book in the Louvre Pyramid.",
                    walkability: "8/10",
                    nightlife: "8/10",
                    location: "downtown, seattle")

hoods_table.insert(title: "Capitol Hill / Seattle Metro", 
                    description: "Capitol Hill, located east of and just up the hill from downtown, acts as a sort of amphitheater stage to the residential neighborhoods surrounding it — this is where a lot of Seattle comes for entertainment. If you like nightlife, theaters, music, and living loud, Capitol Hill is your stop.",
                    walkability: "9/10",
                    nightlife: "10/10",
                    location: "capitol hill, seattle")

hoods_table.insert(title: "Queen Anne / Cascade", 
                    description: "Queen Anne is on its own little peninsula, jutting northwest from downtown and South Lake Union. It’s mostly upscale and pretty posh, but don’t take that the wrong way — this area is also a sweet place to hang out. If you’re the book-with-your-coffee and cocktails-with-a-few-friends type, this is your neighborhood.",
                    walkability: "7/10",
                    nightlife: "7/10",
                    location: "queen anne, seattle")

hoods_table.insert(title: "Ballard", 
                    description: "On the north shore opposite Queen Anne, you’ll find Ballard. It was once a separate city of Scandinavian immigrants, centered around fishing. These days, it’s a good example of a historic area that honors its heritage while moving forward into a new era. Ballard is an incredible mix of old, European-style brick buildings and new-construction condos.",
                    walkability: "8/10",
                    nightlife: "8/10",
                    location: "ballard, seattle")
                    
puts "Success!"