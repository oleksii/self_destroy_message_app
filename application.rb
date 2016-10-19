require 'sinatra/base'
require './url_helpers'
require 'bundler' 
require 'openssl'
require 'base64'
 
Bundler.require 
require './models/message' 
 
DataMapper.setup(:default, 'postgres://sinatra:pass@localhost/messages') 

class MessageGhost < Sinatra::Base

  helpers UrlHelpers

  get '/' do
    redirect message_path
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
      elsif params[:message] != nil && message_password == @message.password
        @message_descrypted = message_descrypted(@message)

        @message.update showed: true unless @message.method == 'time'

        erb :show
      else 
        erb :ask_pass
      end
    end
  end

  post "/messages" do #create
    Message.create text: message_encrypted, password: message_password, method: message_method

    redirect messages_path
  end

  get "/messages/:id/edit" do #edit
    @message = Message.get message_id
    @message_descrypted = message_descrypted(@message)

    erb :edit
  end

  put "/messages/:id" do #update
    @message = Message.get message_id
    @message.update text: message_encrypted, password: message_password, method: message_method

    redirect messages_path
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

    def message_text
      params[:message][:text]
    end

    def message_method
      params[:message][:method]
    end

    def message_showed
      params[:message][:showed]
    end

    def message_password
      params[:message][:password]
    end
    
    def message_encrypted
      AESCrypt.encrypt(message_text, message_password)
    end

    def message_descrypted(message)
      AESCrypt.decrypt(message.text, message.password)
    end

    def message_link
      'http://' + request.env["HTTP_HOST"]
    end
end
