require_relative '../../lib/tag_schema'

class AddTagsAndTaggings < ActiveRecord::Migration[6.1]
  def up
    KnowledgebaseTagSchema.up(self)
  end

  def down
    execute "DELETE FROM taggings WHERE taggable_type = 'KbArticle'"
    execute 'UPDATE tags SET taggings_count = (SELECT COUNT(*) FROM taggings WHERE taggings.tag_id = tags.id)'
  end
end
