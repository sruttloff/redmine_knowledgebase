class CategoriesController < KnowledgebaseController
  before_action :get_category, only: [:show, :edit, :update, :destroy]

  def index
    redirect_to knowledgebase_path
  end

  def show
    @articles = @category.articles.includes(:category).to_a
  end

  def new
    @category = KbCategory.new
    @parent_id = params[:parent_id]
  end

  def create
    @category = KbCategory.new(category_params)
    @parent_id = params[:parent_id]
    assign_parent
    if @category.save
      flash[:notice] = l(:label_category_created, title: @category.title)
      redirect_to category_path(@category)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @parent_id = @category.parent_id
  end

  def update
    @category.assign_attributes(category_params)
    @parent_id = params[:parent_id]
    assign_parent
    if @category.save
      flash[:notice] = l(:label_category_updated)
      redirect_to category_path(@category)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Never remove a subtree that still contains articles.
    if KbArticle.where(category_id: @category.self_and_descendants.select(:id)).exists?
      @articles = @category.articles.to_a
      flash.now[:error] = l(:label_category_not_empty_cannot_delete)
      render :show, status: :unprocessable_entity
    else
      @category.destroy!
      flash[:notice] = l(:label_category_deleted)
      redirect_to knowledgebase_path
    end
  end

  private

  def get_category
    @category = KbCategory.find(params[:id])
  end

  def assign_parent
    if params[:root_category] == 'yes' || KbCategory.count.zero?
      @category.parent = nil
    else
      @category.parent = KbCategory.find(params[:parent_id])
    end
  end

  def category_params
    params.require(:category).permit(:title, :description)
  end
end
