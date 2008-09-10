class LemmataController < ResourceController::Base
  before_filter :is_administrator?, :except => [ :index, :show ]
  actions :all, :except => [ :destroy ]

  show.before do
    @semantic_tags = @lemma.semantic_tags
    @tokens = @lemma.tokens.search(params[:query], :page => current_page)
    @morphology_stats = @lemma.tokens.count(:group => :morphtag).map { |k, v| [PROIEL::MorphTag.new(k).descriptions([:major, :minor], false, :style => :abbreviation).join(', ').capitalize, v] }
    # FIXME: find a better way to skip this if impossible to inflect?
    @morphology_stats = nil if @morphology_stats.length == 1 and @morphology_stats.first.first == ''
  end

  update.before do
    if params[:lemma]
      params[:lemma][:variant] = nil if params[:lemma][:variant].blank?
      params[:lemma][:short_gloss] = nil if params[:lemma][:short_gloss].blank?
      params[:lemma][:lemma] = params[:lemma][:lemma].chars.normalize(UNICODE_NORMALIZATION_FORM)
      [:foreign_ids].each do |a|
        params[:lemma][a] = nil if params[:lemma][a].blank?
      end
    end
  end

  create.before do
    if params[:lemma]
      params[:lemma][:variant] = nil if params[:lemma][:variant].blank?
      params[:lemma][:short_gloss] = nil if params[:lemma][:short_gloss].blank?
      params[:lemma][:lemma] = params[:lemma][:lemma].chars.normalize(UNICODE_NORMALIZATION_FORM)
      [:foreign_ids].each do |a|
        params[:lemma][a] = nil if params[:lemma][a].blank?
      end
    end
  end

  private

  def collection
    @lemmata = Lemma.search(params[:query], :page => current_page)
  end
end
