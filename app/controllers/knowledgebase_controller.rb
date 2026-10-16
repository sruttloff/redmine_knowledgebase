class KnowledgebaseController < ApplicationController
  before_action :authorize_knowledgebase
  rescue_from ActiveRecord::RecordNotFound do
    render_404
  end

  def index
    summary_limit = Setting.plugin_redmine_knowledgebase['knowledgebase_summary_limit'].to_i.clamp(1, 100)
    @categories = KbCategory.all
    @articles_newest = KbArticle.includes(:category).order(created_at: :desc).limit(summary_limit)
    @articles_updated = KbArticle.includes(:category).where('created_at <> updated_at').order(updated_at: :desc).limit(summary_limit)
    @articles_popular = KbArticle.includes(:viewings).sort_by { |article| [-article.view_count, article.id] }.first(summary_limit)
    @articles_toprated = KbArticle.includes(:ratings).sort_by { |article| [-article.rating_average, -article.rated_count, article.id] }.first(summary_limit)
    @tags = KbArticle.tag_counts_on(:tags)
  end

  private

  def authorize_knowledgebase
    if %w[index show tagged].include?(action_name)
      authorize_global unless Setting.plugin_redmine_knowledgebase['knowledgebase_anonymous_access'].to_i == 1
    elsif User.current.logged?
      authorize_global
    else
      deny_access
    end
  end
end
