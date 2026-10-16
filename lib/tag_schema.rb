# Tags are shared with other Redmine plugins. Only add missing schema; never drop
# shared tables during a Knowledgebase uninstall.
module KnowledgebaseTagSchema
  def self.up(migration)
    migration.instance_exec do
      unless table_exists?(:tags)
        create_table :tags do |t|
          t.string :name
          t.integer :taggings_count, default: 0
        end
      end
      unless table_exists?(:taggings)
        create_table :taggings do |t|
          t.integer :tag_id
          t.integer :taggable_id
          t.string :taggable_type
          t.integer :tagger_id
          t.string :tagger_type
          t.string :context, limit: 128
          t.string :tenant, limit: 128
          t.datetime :created_at
        end
      end
      {tag_id: :integer, taggable_id: :integer, taggable_type: :string,
       tagger_id: :integer, tagger_type: :string, context: :string,
       tenant: :string, created_at: :datetime}.each do |name, type|
        add_column :taggings, name, type unless column_exists?(:taggings, name)
      end
      unless column_exists?(:tags, :taggings_count)
        add_column :tags, :taggings_count, :integer, default: 0
        execute 'UPDATE tags SET taggings_count = (SELECT COUNT(*) FROM taggings WHERE taggings.tag_id = tags.id)'
      end
      add_index :tags, :name, unique: true unless index_exists?(:tags, :name)
      add_index :taggings, :tag_id unless index_exists?(:taggings, :tag_id)
      columns = [:taggable_id, :taggable_type, :context]
      add_index :taggings, columns unless index_exists?(:taggings, columns)
    end
  end
end
