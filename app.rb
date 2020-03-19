# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "bcrypt"                                                                      #
require "twilio-ruby"
require "geocoder"                                                                #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

hoods_table = DB.from(:hoods)
rsvps_table = DB.from(:rsvps)
users_table = DB.from(:users)

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

# homepage and list of neighborhoods (aka "index")
get "/" do
    puts "params: #{params}"

    @hoods = hoods_table.all.to_a
    pp @hoods

    view "hoods"
end

# neighborhood details (aka "show")
get "/hoods/:id" do
    puts "params: #{params}"

    @users_table = users_table
    @hood = hoods_table.where(id: params[:id]).to_a[0]
    pp @hood

    @rsvps = rsvps_table.where(hood_id: @hood[:id]).to_a
    @going_count = rsvps_table.where(hood_id: @hood[:id], going: true).count

    @results = Geocoder.search(@hood[:location])
    @lat_long = @results.first.coordinates # => [lat, long]
    @coordinates = "#{@lat_long[0]} #{@lat_long[1]}"

    view "hood"
end

# display the rsvp form (aka "new")
get "/hoods/:id/rsvps/new" do
    puts "params: #{params}"

    @hood = hoods_table.where(id: params[:id]).to_a[0]
    view "new_rsvp"
end

# receive the submitted rsvp form (aka "create")
post "/hoods/:id/rsvps/create" do
    puts "params: #{params}"

    # first find the neighborhood that rsvp'ing for
    @hood = hoods_table.where(id: params[:id]).to_a[0]
    # next we want to insert a row in the rsvps table with the rsvp form data
    rsvps_table.insert(
        hood_id: @hood[:id],
        user_id: session["user_id"],
        comments: params["comments"],
        going: params["going"]
    )

    redirect "/hoods/#{@hood[:id]}"
end

# display the rsvp form (aka "edit")
get "/rsvps/:id/edit" do
    puts "params: #{params}"

    @rsvp = rsvps_table.where(id: params["id"]).to_a[0]
    @hood = hoods_table.where(id: @rsvp[:hood_id]).to_a[0]
    view "edit_rsvp"
end

# receive the submitted rsvp form (aka "update")
post "/rsvps/:id/update" do
    puts "params: #{params}"

    # find the rsvp to update
    @rsvp = rsvps_table.where(id: params["id"]).to_a[0]
    # find the rsvp's hood
    @hood = hoods_table.where(id: @rsvp[:hood_id]).to_a[0]

    if @current_user && @current_user[:id] == @rsvp[:id]
        rsvps_table.where(id: params["id"]).update(
            going: params["going"],
            comments: params["comments"]
        )

        redirect "/hoods/#{@hood[:id]}"
    else
        view "error"
    end
end

# delete the rsvp (aka "destroy")
get "/rsvps/:id/destroy" do
    puts "params: #{params}"

    rsvp = rsvps_table.where(id: params["id"]).to_a[0]
    @hood = hoods_table.where(id: rsvp[:hood_id]).to_a[0]

    rsvps_table.where(id: params["id"]).delete

    redirect "/hoods/#{@hood[:id]}"
end

# display the signup form (aka "new")
get "/users/new" do
    view "new_user"
end

# receive the submitted signup form (aka "create")
post "/users/create" do
    puts "params: #{params}"

    # if there's already a user with this email, skip!
    existing_user = users_table.where(email: params["email"]).to_a[0]
    if existing_user
        view "error"
    else
        users_table.insert(
            name: params["name"],
            email: params["email"],
            password: BCrypt::Password.create(params["password"])
        )

        redirect "/logins/new"
    end
end

# display the login form (aka "new")
get "/logins/new" do
    view "new_login"
end

# receive the submitted login form (aka "create")
post "/logins/create" do
    puts "params: #{params}"

    # step 1: user with the params["email"] ?
    @user = users_table.where(email: params["email"]).to_a[0]

    if @user
        # step 2: if @user, does the encrypted password match?
        if BCrypt::Password.new(@user[:password]) == params["password"]
            # set encrypted cookie for logged in user
            session["user_id"] = @user[:id]
            redirect "/"
        else
            view "create_login_failed"
        end
    else
        view "create_login_failed"
    end
end

# logout user
get "/logout" do
    # remove encrypted cookie for logged out user
    session["user_id"] = nil
    redirect "/logins/new"
end

# sign up to get text updates
get "/hoods/:id/SMS" do
    puts "params: #{params}"

       account_sid = ENV["TWILIO_ACCOUNT_SID"]
       auth_token = ENV["TWILIO_AUTH_TOKEN"]
       client = Twilio::REST::Client.new(account_sid, auth_token)
       client.messages.create(
       from: "+14243487854",
       to: "+14107036254",
       body: "Thanks for signing up! We'll keep you posted if new neighborhoods get added")

    @trip = trips_table.where(id: params[:id]).to_a[0]
    view "text_signup"
end

###############
