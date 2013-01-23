class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :password  # sha-hash, 160 bit as hex-string, 40 chars
      t.string :salt      # ascii-salt, 8 byte (only use ~ 100 safe cross-charset characters of utf7)
      t.text :emails_alert
      t.text :emails_critical
      t.text :json

      t.timestamps
    end
    execute "alter table users modify column password char(40);"
    execute "alter table users modify column salt char(8);"
  end

  def self.down
    drop_table :users
  end
end
