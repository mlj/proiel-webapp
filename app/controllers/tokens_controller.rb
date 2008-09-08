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
    @tokens = (@parent ? @parent.tokens : Token).search(params[:query], :page => current_page, :include => [:lemma])
  end

  show.before do
    @semantic_tags = @token.semantic_tags
    # Add semantic tags from lemma not present in the token's semantic tags.
    @semantic_tags += @token.lemma.semantic_tags.reject { |tag| @semantic_tags.map(&:semantic_attribute).include?(tag.semantic_attribute) } if @token.lemma
  end

  update.before do
    if params[:token]
      if params[:token][:presentation_form].blank?
        params[:token][:presentation_form] = nil
      else
        params[:token][:presentation_form] = params[:token][:presentation_form].chars.normalize(UNICODE_NORMALIZATION_FORM)
      end
      params[:token][:morphtag] = nil if params[:token][:morphtag].blank?
      params[:token][:lemma_id] = nil if params[:token][:lemma_id].blank?
      params[:token][:form] = params[:token][:form].chars.normalize(UNICODE_NORMALIZATION_FORM)
    end
  end
end
