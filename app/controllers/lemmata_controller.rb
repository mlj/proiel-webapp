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
    params[:lemma][:lemma] = params[:lemma][:lemma].mb_chars.normalize(UNICODE_NORMALIZATION_FORM) if params[:lemma]
  end

  create.before do
    params[:lemma][:lemma] = params[:lemma][:lemma].mb_chars.normalize(UNICODE_NORMALIZATION_FORM) if params[:lemma]
  end

  private

  def collection
    @lemmata = Lemma.search(params[:query], :page => current_page)
  end
end
