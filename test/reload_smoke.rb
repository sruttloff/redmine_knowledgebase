# Run with bundle exec rails runner plugins/redmine_knowledgebase/test/reload_smoke.rb
# Isolate reinitialization to this plugin; other installed plugins have their own hooks.
raise 'Use development or test' unless Rails.env.development? || Rails.env.test?
STDOUT.sync = true
Redmine::PluginLoader.singleton_class.prepend(Module.new do
  def directories
    super.select { |directory| File.basename(directory.to_s) == 'redmine_knowledgebase' }
  end
end)
3.times do |iteration|
  Rails.application.reloader.reload!
  [KbArticle, KbCategory, KbViewing, KbRating].each(&:count)
  raise 'Wrong rating association' unless KbArticle.reflect_on_association(:ratings).klass == KbRating
  raise 'Wrong viewing association' unless KbArticle.reflect_on_association(:viewings).klass == KbViewing
  raise 'Duplicate search type' unless Redmine::Search.available_search_types.count('kb_articles') == 1
  raise 'Missing attachment route registration' unless Redmine::Acts::Attachable::ObjectTypeConstraint.object_types.include?('kb_articles')
  raise 'Missing wiki macro' unless Redmine::WikiFormatting::Macros.available_macros.key?(:kb)
  puts "PASS: reload #{iteration + 1}: models, associations, single search registration, attachment routes and macros"
end
