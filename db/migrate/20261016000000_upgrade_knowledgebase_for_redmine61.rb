require_relative '../../lib/tag_schema'

class UpgradeKnowledgebaseForRedmine61 < ActiveRecord::Migration[6.1]
  def up
    KnowledgebaseTagSchema.up(self)
    change_column :viewings, :ip, :string, limit: 45
  end

  def down
    # Shared tag schema and IPv6 support are deliberately retained.
  end
end
