class KbCategory < ApplicationRecord

  self.table_name = "kb_categories"

  validates :title, presence: true, length: {maximum: 255}

  has_many :articles, :class_name => "KbArticle", :foreign_key => "category_id", inverse_of: :category

  acts_as_nested_set :order => 'title'

  validate :parent_outside_subtree

  private

  def parent_outside_subtree
    if persisted? && parent_id && self_and_descendants.exists?(id: parent_id)
      errors.add(:parent_id, :invalid)
    end
  end

end
