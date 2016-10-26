require 'sinatra/base'
require 'bundler' 
require './url_helpers'
require 'openssl'
require 'base64'
 
Bundler.require 
$: << File.dirname(__FILE__) + "/models"
require 'model'
require 'sinatra/flash'
require './message_params'
require 'warden'

configure :development do
  DataMapper.setup(:default, 'postgres://sinatra:pass@localhost/messages')
#  DataMapper.auto_migrate!
#  DataMapper.auto_upgrade!
end

configure :production do
  DataMapper.setup(:default, ENV['DATABASE_URL'])
  DataMapper.auto_migrate!
  DataMapper.auto_upgrade!
end

class MessageGhost < Sinatra::Base
  #enable :sessions
  use Rack::Session::Cookie, secret: "MY_SECRET"
  register Sinatra::Flash
  helpers UrlHelpers

  get '/' do
    redirect messages_path
  end

  get '/messages' do #index
    check_authentication

    @messages = current_user.messages.all
    @message_link = message_link

    #raise env['warden'].inspect
    erb :index
  end

  get '/messages/new' do #new
    check_authentication

    @message = Message.new

    erb :form
  end

  get '/messages/:id' do #show
    @message = Message.first(id: message_id)

    if @message == nil

      erb :blank
    else
      if @message.should_by_destroyed? 
        @message.destroy

        erb :blank 
      elsif params[:message] != nil && message_params.password == @message.password
        @message_descrypted = message_descrypted(@message)

        @message.update showed: true unless @message.method == 'time'

        erb :show
      else 
        erb :ask_pass
      end
    end
  end

  post "/messages" do #create
    check_authentication

    message = current_user.messages.new
    message.text = message_encrypted(message_params)
    message.password = message_params.password
    message.method = message_params.method
    message.save

    if message.saved?
      flash[:success] = "the message was created"

      redirect messages_path
    elsif message.errors
      flash[:errors] = message.errors.full_messages
      
      redirect new_message_path
    end
  end

  get "/messages/:id/edit" do #edit
    check_authentication

    @message = Message.get message_id, current_user.id
    @message_descrypted = message_descrypted(@message)

    erb :edit
  end

  put "/messages/:id" do #update
    check_authentication

    message = Message.get message_id, current_user.id

    if message.update text: message_encrypted(message_params), password: message_params.password, method: message_params.method
      flash[:success] = "the message was updated"

      redirect messages_path
    elsif message.errors
      flash[:errors] = message.errors.full_messages
      
      redirect edit_message_path(message)
    end

  end

  #delete "/messages/:id" do #destroy
  #  @message = current_user.messages.get message_id
  #  @message.destroy

  #  redirect messages_path
  #end

######## Sign up part #######

  get '/signup' do

    erb '/signup'.to_sym
  end

  post '/signup' do
    if User.get params[:email]

      redirect '/login'.to_sym
    else
      user = User.new(username: params[:user][:username], password: params[:user][:password])
      user.save

      if user.saved?

        redirect '/login'.to_sym
      else

        redirect '/signup'.to_sym
      end
    end
  end


######## Sign in part #####

  get "/login" do

    erb '/login'.to_sym
  end

  post "/session" do
    warden_handler.authenticate!

    if warden_handler.authenticated?
      flash[:success] = "Successfully logged in"

      redirect messages_path
    else
      redirect "/login"
    end
  end

  get "/logout" do
    warden_handler.logout

    redirect '/login'
  end

  post "/unauthenticated" do
    flash[:errors] = env['warden.options'][:message] || "Try again"

    redirect "/login"
  end

# Warden configuration code

  use Warden::Manager do |manager|
    manager.default_strategies :password
    manager.failure_app = self
    manager.serialize_into_session {|user| user.id}
    manager.serialize_from_session {|id| User.get(id)}
  end

  Warden::Manager.before_failure do |env,opts|
    env['REQUEST_METHOD'] = 'POST'
  end

  Warden::Strategies.add(:password) do
    def valid?
      params['user']['username'] && params['user']['password']
    end

    def authenticate!
      user = User.first(username: params['user']['username'])

      if user && user.authenticate(params['user']['password'])
        success!(user)
      else
        fail!("Could not log in")
      end
    end
  end

  def warden_handler
    env['warden']
  end

  def check_authentication
    unless warden_handler.authenticated?
      redirect '/login'
    end
  end

  def current_user
    warden_handler.user
  end

###### end of login part #######

  protected
    def message_id
      params[:id]
    end
    
    def message_params
      MessageParams.new(params[:message])
    end

    def message_encrypted(message_params)
      unless message_params.text.empty? && message_params.password.empty?
        AESCrypt.encrypt(message_params.text, message_params.password)
      end
    end

    def message_descrypted(message)
      AESCrypt.decrypt(message.text, message.password)
    end

    def message_link
      'http://' + request.env["HTTP_HOST"]
    end
end
