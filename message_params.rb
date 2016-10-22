class MessageParams
  attr_accessor :text, :password, :method, :viewed

  def initialize(params)
    params.each { |k, v| public_send("#{k}=", v) }
  end
end
