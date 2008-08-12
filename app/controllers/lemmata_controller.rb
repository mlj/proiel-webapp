class LemmataController < ResourceController::Base
  before_filter :is_administrator?, :except => [ :index, :show ]
  actions :all, :except => [ :destroy ]

  show.before do
    @tokens = @lemma.tokens.search(params[:query], :page => current_page)
  end

  update.before do
    if params[:lemma]
      params[:lemma][:variant] = nil if params[:lemma][:variant].blank?
      params[:lemma][:short_gloss] = nil if params[:lemma][:short_gloss].blank?
    end
  end

  create.before do
    if params[:lemma]
      params[:lemma][:variant] = nil if params[:lemma][:variant].blank?
      params[:lemma][:short_gloss] = nil if params[:lemma][:short_gloss].blank?
    end
  end

  private

  def collection
    @lemmata = Lemma.search(params[:query], :page => current_page)
  end
end
