class TokensController < ResourceController::Base
  actions :all, :except => [ :new, :create, :destroy ]
  before_filter :is_reviewer?
  before_filter :is_administrator?, :only => [ :edit, :update ]
  before_filter :find_parents

  protected

  def find_parents
    @parent = @source = Source.find(params[:source_id]) unless params[:source_id].blank?
  end

  private

  def collection
    @tokens = (@parent ? Token.by_source(@source) : Token).search(params[:query], :page => current_page, :include => [:lemma])
  end

  show.before do
    @semantic_tags = @token.semantic_tags
    # Add semantic tags from lemma not present in the token's semantic tags.
    @semantic_tags += @token.lemma.semantic_tags.reject { |tag| @semantic_tags.map(&:semantic_attribute).include?(tag.semantic_attribute) } if @token.lemma
  end

  update.before do
    if params[:token]
      params[:token][:presentation_form] = params[:token][:presentation_form].mb_chars.normalize(UNICODE_NORMALIZATION_FORM) if params[:token][:presentation_form]
      params[:token][:form] = params[:token][:form].mb_chars.normalize(UNICODE_NORMALIZATION_FORM)
    end
  end

  public

  def dependency_alignment_group
    @token = Token.find(params[:id])
    alignment_set, edge_count = @token.dependency_alignment_set

    render :json => { :alignment_set => alignment_set.map(&:id), :edge_count => edge_count }
  end
end
