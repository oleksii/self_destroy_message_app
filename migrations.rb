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

migrate_up!
