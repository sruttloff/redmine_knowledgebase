class AddRatingsToArticles < ActiveRecord::Migration[4.2]
  def self.up
    create_table :ratings do |t|
      t.integer :rated_id
      t.string  :rated_type
      t.decimal :rating
    end
    add_index :ratings, [:rated_type, :rated_id]
  end

  def self.down
    drop_table :ratings
  end
end
