class LemmataController < ResourceController::Base
  before_filter :is_administrator?, :except => [ :index, :show ]
  actions :all, :except => [ :destroy ]

  show.before do
    @tokens = @lemma.tokens.search(params.slice(:source, :form, :exact), params[:page])
  end

  update.before do
    if params[:lemma]
      params[:lemma][:variant] = nil if params[:lemma][:variant] == ''
      params[:lemma][:short_gloss] = nil if params[:lemma][:short_gloss] == ''
    end
  end

  create.before do
    if params[:lemma]
      params[:lemma][:variant] = nil if params[:lemma][:variant] == ''
      params[:lemma][:short_gloss] = nil if params[:lemma][:short_gloss] == ''
    end
  end

  private

  def collection
    @lemmata = Lemma.search(params.slice(:lemma, :exact, :language, :major, :minor), params[:page])
  end
end
