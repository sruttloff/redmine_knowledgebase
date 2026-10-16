# Run with: bundle exec rails runner plugins/redmine_knowledgebase/test/compatibility_smoke.rb
# All database changes are rolled back; no existing user's password is changed.
require 'nokogiri'
require 'securerandom'
require 'tmpdir'
require 'fileutils'
STDOUT.sync = true
raise 'Use a development or test installation' unless Rails.env.development? || Rails.env.test?
ActionMailer::Base.perform_deliveries = false
checks = 0
check = ->(condition, message) { raise("FAIL: #{message}") unless condition; checks += 1; puts "PASS: #{message}" }
original_user = User.current
original_settings = Setting.plugin_redmine_knowledgebase.dup
original_storage = Attachment.storage_path
test_storage = Dir.mktmpdir('kb-smoke-attachments-')
Attachment.storage_path = test_storage
begin
  ActiveRecord::Base.transaction do
    suffix = SecureRandom.hex(5)
    begin
    password = SecureRandom.base64(24)
    admin = User.new(login: "kb-admin-#{suffix}", firstname: 'KB', lastname: 'Admin', mail: "kb-admin-#{suffix}@example.invalid", admin: true, language: 'en')
    admin.password = admin.password_confirmation = password
    admin.save!
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host! 'localhost'
    session.get '/login'
    csrf = Nokogiri::HTML(session.response.body).at_css('input[name="authenticity_token"]')['value']
    session.post '/login', params: {username: admin.login, password: password, authenticity_token: csrf}
    check.call(session.response.redirect?, 'temporary administrator logs in')
    token = nil
    request = lambda do |method, path, params = {}, status = 200|
      session.public_send(method, path, params: params.merge(authenticity_token: token))
      actual = session.response.status
      if actual >= 500
        error_doc = Nokogiri::HTML(session.response.body)
        puts error_doc.at_css('.exception-message')&.text || error_doc.at_css('h1')&.text
      end
      check.call(actual == status, "#{method.upcase} #{path}: expected #{status}, got #{actual}")
      doc = Nokogiri::HTML(session.response.body)
      token = doc.at_css('meta[name="csrf-token"]')&.[]('content') || token
      doc
    end
    request.call(:get, '/knowledgebase')
    request.call(:get, '/knowledgebase/categories', {}, 302)
    request.call(:get, '/knowledgebase/categories/new')
    request.call(:post, '/knowledgebase/categories', {root_category: 'yes', category: {title: '', description: 'invalid'}}, 422)
    root_title = "KB smoke root #{suffix}"
    request.call(:post, '/knowledgebase/categories', {root_category: 'yes', category: {title: root_title, description: '**Root**'}}, 302)
    root = KbCategory.find_by!(title: root_title)
    child_title = "KB smoke child #{suffix}"
    request.call(:post, '/knowledgebase/categories', {parent_id: root.id, category: {title: child_title}}, 302)
    child = KbCategory.find_by!(title: child_title)
    check.call(child.parent_id == root.id, 'subcategory persists under parent')
    request.call(:get, "/knowledgebase/categories/#{root.id}")
    request.call(:get, "/knowledgebase/categories/#{child.id}/edit")
    request.call(:patch, "/knowledgebase/categories/#{root.id}", {parent_id: child.id, category: {title: root_title}}, 422)
    check.call(root.reload.parent_id.nil?, 'cyclic category move rejected without changing tree')
    request.call(:patch, "/knowledgebase/categories/#{child.id}", {root_category: 'yes', category: {title: child_title}}, 302)
    check.call(child.reload.parent_id.nil?, 'subcategory can become a root')
    request.call(:patch, "/knowledgebase/categories/#{child.id}", {parent_id: root.id, category: {title: child_title}}, 302)
    request.call(:get, "/knowledgebase/articles/new?category_id=#{child.id}")
    article_params = {category_id: child.id, article: {title: "KB searchable #{suffix}", summary: '<script>alert(1)</script>', content: '**Verified article**', tag_list: "kb-smoke-#{suffix}, Redmine 6.1"}}
    request.call(:post, '/knowledgebase/articles/preview', article_params)
    request.call(:post, '/knowledgebase/articles', {category_id: child.id, article: {title: ''}}, 422)
    request.call(:post, '/knowledgebase/articles', article_params, 302)
    article = KbArticle.find_by!(title: article_params[:article][:title])
    path = "/knowledgebase/articles/#{article.id}"
    check.call(article.tag_list.size == 2, 'tags persist using shared modern schema')
    doc = request.call(:get, "/knowledgebase/articles/#{article.id}/edit")
    check.call(doc.at_css('#article_tag_list')['value'] == article.tag_list.to_s, 'edit form preserves tag delimiters')
    doc = request.call(:get, path)
    check.call(doc.css('#content script').none? { |script| script.text.include?('alert(1)') }, 'plain summary HTML is escaped')
    request.call(:get, path)
    check.call(article.viewings.count == 1, 'repeat views are counted once per user/IP')
    request.call(:get, '/knowledgebase/articles/tagged', {id: "kb-smoke-#{suffix}"})
    check.call(session.response.body.include?(article.title), 'tag filtering finds article')
    request.call(:get, "#{path}/edit")
    request.call(:patch, path, {category_id: child.id, article: {title: article.title, summary: 'Updated summary', content: 'Updated content', tag_list: article.tag_list.to_s, author_id: -1}}, 302)
    check.call(article.reload.tag_list.size == 2, 'editing does not merge separate tags')
    check.call(article.reload.author_id == admin.id && article.updater_id == admin.id, 'update records updater and protects author')
    request.call(:post, "#{path}/rate", {rating: 5}, 302)
    request.call(:post, "#{path}/rate", {rating: 3}, 302)
    check.call(article.rating_average == 4 && article.rated_count == 2, 'rating average and count persist')
    request.call(:post, "#{path}/rate", {rating: 99}, 422)
    request.call(:post, "#{path}/rate", {rating: '3x'}, 422)
    request.call(:post, "#{path}/add_comment", {comment: {comments: ''}}, 422)
    request.call(:post, "#{path}/add_comment", {comment: {comments: 'Test comment'}}, 302)
    check.call(article.comments.count == 1 && article.reload.comments_count == 1, 'comment and counter persist')
    comment = article.comments.first
    request.call(:get, path)
    request.call(:post, "#{path}/destroy_comment", {comment_id: comment.id}, 302)
    check.call(article.comments.count.zero? && article.reload.comments_count.zero?, 'comment deletion updates counter')
    User.current = admin
    article.view('2001:db8:0000:0000:0000:0000:0000:0001')
    check.call(article.viewings.count == 2, 'full IPv6 address supported')
    check.call(KbArticle.search_result_ranks_and_ids([suffix], admin).any? { |_, id| id == article.id }, 'global search includes article')
    check.call(article.event_url[:id] == article.id, 'search result URL points to correct article')
    request.call(:get, '/search', {q: suffix, kb_articles: '1', all_words: '1'})
    check.call(session.response.body.include?("/knowledgebase/articles/#{article.id}"), 'global search renders clickable result')
    macros = "{{kb(#{article.id})}} {{article_id(#{article.id})}} {{article(#{article.id})}} {{category(#{child.id})}}"
    doc = request.call(:post, '/knowledgebase/articles/preview', {article: {content: macros}})
    check.call(doc.css("a[href='/knowledgebase/articles/#{article.id}']").size == 3 && doc.css("a[href='/knowledgebase/categories/#{child.id}']").size == 1, 'all four wiki macros render visible links in preview')
    doc = request.call(:get, '/knowledgebase')
    check.call(!session.response.body.include?('translation missing'), 'overview translations resolve')
    request.call(:delete, "/knowledgebase/categories/#{root.id}", {}, 422)
    check.call(KbCategory.exists?(root.id) && KbArticle.exists?(article.id), 'non-empty subtree cannot be deleted')
    request.call(:get, '/settings/plugin/redmine_knowledgebase')
    %w[en de].each do |locale|
      admin.update_columns(language: locale)
      request.call(:get, path)
      check.call(!session.response.body.include?('translation missing'), "#{locale} article renders complete translations")
    end
    request.call(:get, '/knowledgebase/articles/999999999', {}, 404)
    request.call(:get, '/knowledgebase/categories/999999999', {}, 404)
    # Test reads and writes without an authenticated user.
    anonymous = ActionDispatch::Integration::Session.new(Rails.application)
    anonymous.host! 'localhost'
    anonymous.get path
    check.call(anonymous.response.status == 200, 'anonymous article reads allowed by default setting')
    anonymous.get '/knowledgebase/articles/tagged', params: {id: "kb-smoke-#{suffix}"}
    check.call(anonymous.response.status == 200, 'anonymous tag browsing uses same read policy')
    anonymous.get "#{path}/edit"
    check.call(anonymous.response.status == 302, 'anonymous editing requires login')
    Setting.plugin_redmine_knowledgebase = original_settings.merge('knowledgebase_anonymous_access' => '0')
    anonymous.get path
    check.call(anonymous.response.status == 302, 'disabled anonymous reads require login')
    User.current = User.anonymous
    check.call(!article.attachments_visible? && !article.attachments_deletable?, 'attachment permissions follow article access')
    check.call(KbArticle.visible.none?, 'hidden articles excluded from search scope')
    # A normal member with view permission cannot write, rate, moderate or delete.
    member = User.new(login: "kb-reader-#{suffix}", firstname: 'KB', lastname: 'Reader', mail: "kb-reader-#{suffix}@example.invalid")
    member.password = member.password_confirmation = password
    member.save!
    role = Role.create!(name: "KB reader #{suffix}", permissions: [:view_articles])
    project = Project.create!(name: "KB permissions #{suffix}", identifier: "kb-permissions-#{suffix}")
    membership = Member.create!(project: project, user: member, roles: [role])
    reader = ActionDispatch::Integration::Session.new(Rails.application)
    reader.host! 'localhost'
    reader.get '/login'
    reader_csrf = Nokogiri::HTML(reader.response.body).at_css('input[name="authenticity_token"]')['value']
    reader.post '/login', params: {username: member.login, password: password, authenticity_token: reader_csrf}
    reader.get path
    check.call(reader.response.status == 200, 'non-admin reader can read with anonymous access disabled')
    reader_csrf = Nokogiri::HTML(reader.response.body).at_css('meta[name="csrf-token"]')['content']
    [[:get, "#{path}/edit", {}], [:post, "#{path}/rate", {rating: 5}],
     [:post, "#{path}/add_comment", {comment: {comments: 'Forbidden'}}],
     [:delete, path, {}], [:get, '/knowledgebase/categories/new', {}]].each do |method, route, params|
      reader.public_send(method, route, params: params.merge(authenticity_token: reader_csrf))
      check.call(reader.response.status == 403, "reader cannot #{method} #{route}")
    end
    role.update!(permissions: [:view_articles, :comment_and_rate_articles])
    reader.post "#{path}/rate", params: {rating: 4, authenticity_token: reader_csrf}
    check.call(reader.response.status == 302, 'comment/rate permission allows rating for non-admin')
    reader.post "#{path}/add_comment", params: {comment: {comments: 'Allowed member comment'}, authenticity_token: reader_csrf}
    check.call(reader.response.status == 302, 'comment/rate permission allows comment for non-admin')
    reader.post "#{path}/destroy_comment", params: {comment_id: article.comments.last.id, authenticity_token: reader_csrf}
    check.call(reader.response.status == 403, 'commenting permission does not permit comment deletion')
    User.current = User.find(member.id)
    check.call(!article.attachments_deletable?, 'commenting permission does not permit attachment deletion')
    role.update!(permissions: [:view_articles, :manage_articles])
    reader.get "#{path}/edit"
    check.call(reader.response.status == 200, 'manage permission allows editing for non-admin')
    reader.post "#{path}/destroy_comment", params: {comment_id: article.comments.last.id, authenticity_token: reader_csrf}
    check.call(reader.response.status == 302, 'manage permission allows moderation for non-admin')
    role.update!(permissions: [:view_articles, :create_articles])
    payload = "Knowledgebase attachment #{suffix} with Unicode: ÄÖÜ äöü ß"
    reader.post '/uploads.js?filename=kb-smoke.txt', params: payload,
      headers: {'Content-Type' => 'application/octet-stream', 'X-CSRF-Token' => reader_csrf, 'X-Requested-With' => 'XMLHttpRequest'}
    check.call(reader.response.status == 200, "create-only permission permits actual Redmine upload (got #{reader.response.status})")
    upload_token = Attachment.where(author: member).order(:id).last!.token
    reader.post '/knowledgebase/articles', params: {authenticity_token: reader_csrf, category_id: child.id,
      article: {title: "KB attachment #{suffix}"}, attachments: {'1' => {token: upload_token, filename: 'kb-smoke.txt'}}}
    check.call(reader.response.status == 302, 'non-admin creates article with uploaded attachment token')
    uploaded_article = KbArticle.find_by!(title: "KB attachment #{suffix}")
    attachment = uploaded_article.attachments.first!
    check.call(File.binread(attachment.diskfile) == payload.b, 'attachment bytes persist unchanged')
    reader.get "/attachments/download/#{attachment.id}/kb-smoke.txt"
    check.call(reader.response.status == 200 && reader.response.body.b == payload.b, 'reader can download article attachment')
    reader.get "/attachments/kb_articles/#{uploaded_article.id}/edit"
    check.call(reader.response.status == 404, 'create-only permission cannot edit existing attachments')
    anonymous.get "/attachments/download/#{attachment.id}/kb-smoke.txt"
    check.call(anonymous.response.status != 200, 'hidden article attachment cannot be downloaded anonymously')
    role.update!(permissions: [:view_articles, :edit_articles])
    reader.get "/attachments/kb_articles/#{uploaded_article.id}/edit"
    check.call(reader.response.status == 200, 'edit permission can edit attachment metadata')
    reader.post "/knowledgebase/articles/#{uploaded_article.id}/add_attachment",
      params: {authenticity_token: reader_csrf, attachments: {'1' => {token: 'missing-token'}}}
    check.call(reader.response.status == 422, 'missing upload token shows validation error instead of server error')
    uploaded_article.destroy!
    Setting.plugin_redmine_knowledgebase = original_settings
    request.call(:delete, path, {}, 302)
    check.call(!KbArticle.exists?(article.id) && KbRating.where(rated_id: article.id, rated_type: 'KbArticle').none? && KbViewing.where(viewed_id: article.id, viewed_type: 'KbArticle').none?, 'article deletion removes dependent ratings and views')
    request.call(:delete, "/knowledgebase/categories/#{root.id}", {}, 302)
    check.call(!KbCategory.exists?(child.id), 'empty subtree deletion removes descendants')
    raise ActiveRecord::Rollback
    ensure
      # Uploads normally commit before article requests. In this outer test
      # transaction they roll back together, so there is nothing to reattach.
      ActiveRecord::Base.connection.current_transaction.records.grep(KbArticle).each do |record|
        record.saved_attachments.clear if record.title.to_s.include?(suffix)
      end
    end
  end
ensure
  Attachment.storage_path = original_storage
  FileUtils.remove_entry(test_storage) if File.directory?(test_storage)
  Setting.clear_cache
  User.current = original_user
end
puts "#{checks} checks passed; all temporary database records rolled back."
