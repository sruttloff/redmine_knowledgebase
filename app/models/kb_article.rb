class KbArticle < ApplicationRecord
  self.table_name = 'kb_articles'

  belongs_to :project, optional: true
  belongs_to :category, class_name: 'KbCategory', inverse_of: :articles
  belongs_to :author, class_name: 'User'
  belongs_to :updater, class_name: 'User', optional: true
  validates :title, presence: true, length: {maximum: 255}

  acts_as_taggable
  acts_as_attachable
  has_many :viewings, as: :viewed, class_name: 'KbViewing', dependent: :delete_all
  has_many :ratings, as: :rated, class_name: 'KbRating', dependent: :delete_all
  has_many :comments, -> { order(:created_on) }, as: :commented, dependent: :destroy

  scope :visible, ->(user = User.current) { readable_by?(user) ? all : none }

  def self.readable_by?(user = User.current)
    Setting.plugin_redmine_knowledgebase['knowledgebase_anonymous_access'].to_i == 1 ||
      user.allowed_to?({controller: 'articles', action: 'show'}, nil, global: true)
  end

  acts_as_searchable columns: ['kb_articles.title', 'kb_articles.content'], date_column: 'kb_articles.created_at'
  acts_as_event title: ->(article) { "#{::I18n.t(:label_title_articles)} ##{article.id}: #{article.title}" },
                description: :content, datetime: :created_at, type: 'articles',
                url: ->(article) { {controller: 'articles', action: 'show', id: article.id} }

  def visible?(user = User.current)
    self.class.readable_by?(user)
  end

  def attachments_visible?(user = User.current)
    visible?(user)
  end

  def attachments_editable?(user = User.current)
    visible?(user) && user.logged? &&
      user.allowed_to?({controller: 'articles', action: 'update'}, nil, global: true)
  end
  alias_method :attachments_deletable?, :attachments_editable?

  # Knowledgebase articles are global, including their attachments and comments.
  def project
    nil
  end

  def view(ip, viewer = nil)
    viewer = nil unless viewer&.logged?
    with_lock do
      existing = viewings.where(ip: ip)
      existing = existing.or(viewings.where(viewer_id: viewer.id)) if viewer
      viewings.create!(ip: ip, viewer: viewer) unless existing.exists?
    end
  end

  def view_count
    viewings.size
  end

  def rate(value)
    ratings.create!(rating: value)
  end

  def rated_count
    ratings.size
  end

  def rating_average
    if ratings.loaded?
      ratings.empty? ? 0 : (ratings.sum(&:rating) / ratings.size).round(2)
    else
      ratings.average(:rating)&.round(2) || 0
    end
  end
end
