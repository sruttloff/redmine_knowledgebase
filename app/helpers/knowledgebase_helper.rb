module KnowledgebaseHelper
  include ActsAsTaggableOn::TagsHelper

  def link_to_if_authorized_globally(name, options = {}, html_options = nil)
    link_to(name, options, html_options) if authorized_globally(options[:controller], options[:action])
  end

  def authorized_globally(controller, action)
    User.current.logged? && User.current.allowed_to?({controller: controller, action: action}, nil, global: true)
  end

  def format_article_summary(article, format, options = {})
    output = case format
    when 'newest', 'updated'
      category = link_to(article.category.title, category_path(article.category_id))
      time = format == 'newest' ? article.created_at : article.updated_at
      # Escape both the translation and its user-controlled substitutions.
      template = ERB::Util.html_escape(l("label_summary_#{format}_articles".to_sym, ago: time_ago_in_words(time), category: '%CATEGORY%'))
      template.gsub('%CATEGORY%', category).html_safe
    when 'popular'
      l(:label_summary_popular_articles, count: article.view_count, created: format_time(article.created_at))
    when 'toprated'
      l(:label_summary_toprated_articles, rating_avg: article.rating_average, rating_max: 5, count: article.rated_count)
    else
      truncate(article.summary.to_s, length: options[:truncate] || 100)
    end
    content_tag(:div, output, class: 'summary')
  end

  def sort_categories?
    Setting.plugin_redmine_knowledgebase['knowledgebase_sort_category_tree'].to_i == 1
  end

  def show_category_totals?
    Setting.plugin_redmine_knowledgebase['knowledgebase_show_category_totals'].to_i == 1
  end

  def updated_by(updated, updater)
    template = ERB::Util.html_escape(l(:label_updated_who, updater: '%USER%', age: '%AGE%'))
    template.gsub('%USER%', link_to_user(updater)).gsub('%AGE%', time_tag(updated)).html_safe
  end

  def create_preview_link
    link_to l(:label_preview), '#', class: 'icon icon-preview',
      onclick: "event.preventDefault(); const form = document.getElementById('articles-form'); const data = new FormData(form); data.delete('_method'); data.delete('authenticity_token'); fetch('#{escape_javascript(preview_articles_path)}', {method: 'POST', body: data, headers: {'X-CSRF-Token': document.querySelector('meta[name=csrf-token]').content}}).then(r => {if (!r.ok) throw new Error(r.status); return r.text();}).then(html => {document.getElementById('preview').innerHTML = html;}).catch(() => {document.getElementById('preview').textContent = '#{escape_javascript(l(:label_preview_error))}';});"
  end
end
