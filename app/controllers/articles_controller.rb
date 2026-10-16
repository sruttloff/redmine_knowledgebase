class ArticlesController < KnowledgebaseController
  helper :attachments
  include AttachmentsHelper
  before_action :get_article, only: [:show, :edit, :update, :rate, :comment, :add_comment, :destroy, :destroy_comment, :add_attachment]

  def new
    @article = KbArticle.new(category_id: params[:category_id])
  end

  def create
    @article = KbArticle.new(article_params)
    @article.category_id = params[:category_id]
    @article.author = User.current
    @article.save_attachments(params[:attachments])
    if @article.save
      render_attachment_warning_if_needed(@article)
      flash[:notice] = l(:label_article_created, title: @article.title)
      redirect_to category_path(@article.category_id)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @article.view(request.remote_addr, User.current)
    @comments = @article.comments.includes(:author)
  end

  def edit
  end

  def update
    @article.assign_attributes(article_params)
    @article.category_id = params[:category_id]
    @article.updater = User.current
    @article.save_attachments(params[:attachments])
    if @article.save
      render_attachment_warning_if_needed(@article)
      flash[:notice] = l(:label_article_updated)
      redirect_to article_path(@article)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def rate
    rating = params[:rating].to_s
    return head :unprocessable_entity unless /\A[1-5]\z/.match?(rating)
    @article.rate(rating.to_i)
    redirect_to article_path(@article)
  end

  def comment
    @article_id = @article.id
    respond_to do |format|
      format.js
      format.html { redirect_to article_path(@article, anchor: 'add-comment') }
    end
  end

  def add_comment
    @comment = @article.comments.build(comment_params)
    @comment.author = User.current
    if @comment.save
      flash[:notice] = l(:label_comment_added)
      redirect_to article_path(@article, anchor: 'comments')
    else
      @comments = @article.comments.includes(:author).to_a.reject(&:new_record?)
      render :show, status: :unprocessable_entity
    end
  end

  def destroy_comment
    @article.comments.find(params[:comment_id]).destroy!
    redirect_to article_path(@article)
  end

  def destroy
    @article.destroy!
    flash[:notice] = l(:label_article_removed)
    redirect_to knowledgebase_path
  end

  def add_attachment
    @article.save_attachments(params[:attachments])
    if @article.save
      render_attachment_warning_if_needed(@article)
      redirect_to article_path(@article)
    else
      @comments = @article.comments.includes(:author)
      render :show, status: :unprocessable_entity
    end
  end

  def tagged
    @tag = params[:id].to_s
    @list = KbArticle.visible.tagged_with(@tag).includes(:category)
  end

  def preview
    @article = KbArticle.new(article_params)
    @summary = @article.summary
    @content = @article.content
    render layout: false
  end

  private

  def article_params
    params.require(:article).permit(:title, :summary, :content, :tag_list)
  end

  def comment_params
    params.require(:comment).permit(:comments)
  end

  def get_article
    @article = KbArticle.find(params[:id] || params[:article_id])
  end
end
