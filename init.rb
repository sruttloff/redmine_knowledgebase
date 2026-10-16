# The plugin's lib/ files don't follow Zeitwerk naming conventions.
# They are explicitly required below. Ignore them from autoloading.
Rails.autoloaders.main.ignore(File.join(__dir__, 'lib'))

require 'redmine'
require 'acts-as-taggable-on'
require 'awesome_nested_set'

#Register KB macro
load File.join(__dir__, 'lib/macros.rb')

Redmine::Plugin.register :redmine_knowledgebase do
  name        'Knowledgebase'
  author      'Alex Bevilacqua; SaaS-Secure.com, S. Ruttloff'
  description 'A plugin for Redmine that adds knowledgebase functionality'
  url         'https://github.com/sruttloff/redmine_knowledgebase'
  author_url  'https://www.saas-secure.com/'
  version     '3.0.0'

  requires_redmine :version_or_higher => '6.1.0'

  settings :default => {
    'knowledgebase_anonymous_access' => "1",
    'knowledgebase_sort_category_tree' => "1",
    'knowledgebase_show_category_totals' => "1",
    'knowledgebase_summary_limit' => "5"
  }, :partial => 'settings/knowledgebase_settings'

  #Global permissions
  project_module :knowledgebase do
    permission :view_articles, {
      :knowledgebase => :index,
      :articles      => [:show, :tagged],
      :categories    => [:index, :show]
    }
    permission :comment_and_rate_articles, {
      :knowledgebase => :index,
      :articles      => [:show, :tagged, :rate, :comment, :add_comment],
      :categories    => [:index, :show]
    }
    permission :create_articles, {
      :knowledgebase => :index,
      :articles      => [:show, :tagged, :new, :create, :add_attachment, :preview],
      :attachments   => :upload,
      :categories    => [:index, :show]
    }
    permission :edit_articles, {
      :knowledgebase => :index,
      :articles      => [:show, :tagged, :edit, :update, :add_attachment, :preview],
      :attachments   => :upload,
      :categories    => [:index, :show]
    }
    permission :manage_articles, {
      :knowledgebase => :index,
      :articles      => [:show, :new, :create, :edit, :update, :destroy, :add_attachment,
                         :preview, :comment, :add_comment, :destroy_comment, :tagged, :rate],
      :attachments   => :upload,
      :categories    => [:index, :show]
    }
    permission :manage_articles_comments, {
      :knowledgebase => :index,
      :articles      => [:show, :comment, :add_comment, :destroy_comment],
      :categories    => [:index, :show]
    }
    permission :create_article_categories, {
      :knowledgebase => :index,
      :categories    => [:index, :show, :new, :create]
    }
    permission :manage_article_categories, {
      :knowledgebase => :index,
      :categories    => [:index, :show, :new, :create, :edit, :update, :destroy]
    }
  end

  menu :top_menu, :knowledgebase, { :controller => 'knowledgebase', :action => 'index' }, :caption => :knowledgebase_title,
	:if =>  Proc.new {
		User.current.allowed_to?({ :controller => 'knowledgebase', :action => 'index' }, nil, :global => true) ||
		Setting['plugin_redmine_knowledgebase']['knowledgebase_anonymous_access'].to_i == 1
	}

  Redmine::Search.available_search_types << 'kb_articles' unless Redmine::Search.available_search_types.include?('kb_articles')
end

Redmine::Acts::Attachable::ObjectTypeConstraint.register_object_type('kb_articles')
