class KbArticle < ApplicationRecord

  self.table_name = "kb_articles"

  validates_presence_of :title
  validates_presence_of :category_id

  belongs_to :project # XXX association added to allow searching to work
  belongs_to :category, :class_name => "KbCategory"
  belongs_to :author,   :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :updater,  :class_name => 'User', :foreign_key => 'updater_id'

  acts_as_viewed
  acts_as_rated :no_rater => true
  acts_as_taggable
  acts_as_attachable

  scope :visible, lambda { |*args|
    user = args.first || User.current
    if Setting['plugin_redmine_knowledgebase']['knowledgebase_anonymous_access'].to_i == 1 ||
       user.allowed_to?(:view_articles, nil, :global => true)
      where(nil)
    else
      none
    end
  }

  acts_as_searchable :columns => [ "kb_articles.title", "kb_articles.content"],
                     :date_column => "kb_articles.created_at"

  acts_as_event :title => Proc.new { |o| "#{l(:label_title_articles)} ##{o.id}: #{o.title}" },
                :description => Proc.new { |o| "#{o.content}" },
                :datetime => :created_at,
                :type => 'articles',
                :url => Proc.new { |o| {:controller => 'articles', :action => 'show', :id => nil, :article_id => o.id} }

  has_many :comments, -> { order(:created_on) }, :as => :commented, :dependent => :delete_all

  # This overrides the instance method in acts_as_attachable
  def attachments_visible?(user=User.current)
    true
  end

  def attachments_deletable?(user=User.current)
    user.logged?
  end

  # XXX this is required by acts_as_attachable. Without this, trying to download
  # a file throws the following:
  # "NoMethodError (undefined method 'project' for #(ActiveRecord::Associations::BelongsToPolymorphicAssociation))"
  def project
    nil
  end

end

