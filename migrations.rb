require 'dm-migrations/migration_runner'

migration 1, :create_messages_table do
  up do
    create_table :messages do
      column :id,   Integer, :serial => true
      column :text, Text
      column :method, String
      column :password, String
      column :showed, Boolean, :default => false
      column :created_at, DateTime
      column :updated_at, DateTime
    end
  end

  down do
    drop_table :messages
  end
end

migration 2, :create_users_table do
  up do
    create_table :users do
      column :id, Integer, :serial => true, :key => true
      column :username, String
      column :password, BCryptHash
      column :created_at, DateTime
      column :updated_at, DateTime
    end
  end

  down do
    drop_table :users
  end
end

migrate_up!
