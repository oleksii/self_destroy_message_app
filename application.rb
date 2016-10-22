require 'sinatra/base'
require 'bundler' 
require './url_helpers'
require 'openssl'
require 'base64'
 
Bundler.require 
require './models/message' 
require 'sinatra/flash' 
require './message_params'

configure :development do 
 DataMapper.setup(:default, 'postgres://sinatra:pass@localhost/messages') 
end

configure :production do 
 DataMapper.setup(:default, ENV['DATABASE_URL']) 
 DataMapper.auto_migrate!
 DataMapper.auto_upgrade!
end

class MessageGhost < Sinatra::Base
  register Sinatra::Flash

  enable :sessions

  helpers UrlHelpers

  get '/' do
    redirect messages_path
  end

  get '/messages' do #index
    @messages = Message.all
    @message_link = message_link

    erb :index
  end

  get '/messages/new' do #new
    @message = Message.new

    erb :form
  end

  get '/messages/:id' do #show
    @message = Message.get message_id
    if @message #to avoid 500 after new template loaded
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
    message = Message.new
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
    @message = Message.get message_id
    @message_descrypted = message_descrypted(@message)

    erb :edit
  end

  put "/messages/:id" do #update
    message = Message.get message_id

    if message.update text: message_encrypted(message_params), password: message_params.password, method: message_params.method
      flash[:success] = "the message was updated"

      redirect messages_path
    elsif message.errors
      flash[:errors] = message.errors.full_messages
      
      redirect edit_message_path(message)
    end

  end

  delete "/messages/:id" do #destroy
    @message = Message.get message_id
    @message.destroy

    redirect messages_path
  end

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
