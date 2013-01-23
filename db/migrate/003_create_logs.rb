class CreateLogs < ActiveRecord::Migration
  def self.up
    create_table :logs do |t|
      t.references :site
      t.string :state
      t.text :error
      t.float :lag

      t.timestamps
    end
    execute "alter table logs modify state char(8);"
  end

  def self.down
    drop_table :logs
  end
end
