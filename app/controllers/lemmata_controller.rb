class LemmataController < ResourceController::Base
  before_filter :is_reviewer?, :except => [:index, :show]
  before_filter :find_parents
  actions :all, :except => [ :destroy ]

  show.before do
    @semantic_tags = @lemma.semantic_tags
    @tokens = @lemma.tokens.search(params[:query], :page => current_page)
    @morphology_stats = @lemma.tokens.count(:group => :morphology).map { |k, v| [k.abbreviated_summary.capitalize, v] }
    @mergeable_lemmata = @lemma.mergeable_lemmata
  end

  update.before do
    params[:lemma][:lemma] = params[:lemma][:lemma].mb_chars.normalize(UNICODE_NORMALIZATION_FORM) if params[:lemma]
  end

  create.before do
    params[:lemma][:lemma] = params[:lemma][:lemma].mb_chars.normalize(UNICODE_NORMALIZATION_FORM) if params[:lemma]
  end

  def merge
    @lemma = Lemma.find(params[:id])
    @other_lemma = Lemma.find(params[:other_id])
    @lemma.merge!(@other_lemma)
    flash[:notice] = "Lemmata sucessfully merged"
    redirect_to @lemma
  end

  protected

  def find_parents
    @parent = @part_of_speech = PartOfSpeech.find(params[:part_of_speech_id]) if params[:part_of_speech_id]
  end

  private

  def collection
    @lemmata = (@parent ? @parent.lemmata : Lemma).search(params[:query], :page => current_page)
  end
end
