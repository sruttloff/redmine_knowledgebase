class AddViewingTables < ActiveRecord::Migration[4.2]
  def self.up
    create_table :viewings do |t|
      t.integer :viewer_id
      t.integer :viewed_id
      t.string  :viewed_type
      t.string  :ip, limit: 24
      t.datetime :created_at
    end
    add_index :viewings, :viewer_id
    add_index :viewings, [:viewed_type, :viewed_id]
  end

  def self.down
    drop_table :viewings
  end
end
