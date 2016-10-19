module UrlHelpers
  def message_path(message)
    "/messages/#{message.id}"
  end

  def new_message_path
    "/messages/new"
  end

  def edit_message_path(message)
    "/messages/#{message.id}/edit" 
  end

  def messages_path
    "/messages"
  end

  def link_to(text, path, options = {})
    %Q{<a href='#{path}' class='#{options[:class]}' data-method='#{options[:method]}'>#{text}</a>}
  end
end
