class KbCategory < ApplicationRecord
  
  self.table_name = "kb_categories"
  
  validates_presence_of :title
  
  has_many :articles, :class_name => "KbArticle", :foreign_key => "category_id"
  
  acts_as_nested_set :order => 'title'

end

