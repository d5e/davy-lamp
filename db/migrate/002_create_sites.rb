class CreateSites < ActiveRecord::Migration
  def self.up
    create_table :sites do |t|
      t.references :user
      t.integer :cycle
      t.integer :last, :default => 0
      t.text :json

      t.timestamps
    end
    execute "alter table sites modify column last int(11) unsigned;"
  end

  def self.down
    drop_table :sites
  end
end
