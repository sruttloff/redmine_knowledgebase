get '/knowledgebase', to: 'knowledgebase#index', as: :knowledgebase
scope '/knowledgebase' do
  # Redmine's attachment controller uses polymorphic URLs for its container.
  get 'articles/:id', to: 'articles#show', as: :kb_article, constraints: {id: /\d+/}
  resources :categories
  resources :articles, except: :index do
    collection do
      get :tagged
      post :preview
    end
    member do
      get :comment
      post :add_comment
      post :destroy_comment
      post :rate
      post :add_attachment
    end
  end
end
