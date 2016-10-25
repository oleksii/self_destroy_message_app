class Message
  include DataMapper::Resource

  property :id, Serial
  property :text, Text
  property :method, String
  property :showed, Boolean
  property :password, String 
  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :user, :key => true

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

class User
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :username, String
  property :password, BCryptHash

  has n, :messages

  def authenticate(attempted_password)
    if self.password == attempted_password
      true
    else
      false
    end
  end
end

DataMapper.finalize 
