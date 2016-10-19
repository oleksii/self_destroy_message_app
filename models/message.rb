class Message
  include DataMapper::Resource

  property :id, Serial
  property :text, Text
  property :method, String
  property :showed, Boolean
  property :password, String
  property :created_at, DateTime
  property :updated_at, DateTime

  validates_presence_of :text
  validates_presence_of :method
  validates_presence_of :password

  def persisted? 
    self.id 
  end

  def expired?
    time = Time.now

    time - self.created_at.to_time >= 100
  end

  def should_by_destroyed?
    self.method == 'time' && self.expired? || self.method == 'view' && self.showed
  end
end

DataMapper.finalize 
