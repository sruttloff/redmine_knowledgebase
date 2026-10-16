Redmine::WikiFormatting::Macros.register do
  desc 'Knowledgebase article link: {{kb(id)}}'
  macro :kb do |_object, args|
    raise 'Expected one article ID.' unless args.size == 1
    article = KbArticle.visible.find(args.first)
    link_to l(:label_kb_link, kb_id: article.id), controller: 'articles', action: 'show', id: article.id
  end

  desc 'Knowledgebase article link: {{article_id(id)}}'
  macro :article_id do |_object, args|
    raise 'Expected one article ID.' unless args.size == 1
    article = KbArticle.visible.find(args.first)
    link_to l(:label_kb_link, kb_id: article.id), controller: 'articles', action: 'show', id: article.id
  end

  desc 'Knowledgebase article title link: {{article(id)}}'
  macro :article do |_object, args|
    raise 'Expected one article ID.' unless args.size == 1
    article = KbArticle.visible.find(args.first)
    link_to "#{l(:label_kb_link, kb_id: article.id)}: #{article.title}", controller: 'articles', action: 'show', id: article.id
  end

  desc 'Knowledgebase category link: {{category(id)}}'
  macro :category do |_object, args|
    raise 'Expected one category ID.' unless args.size == 1
    raise ActiveRecord::RecordNotFound unless KbArticle.readable_by?
    category = KbCategory.find(args.first)
    link_to category.title, controller: 'categories', action: 'show', id: category.id
  end
end
