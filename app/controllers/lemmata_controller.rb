class LemmataController < InheritedResources::Base
  actions :all, :except => [:destroy]

  before_filter :is_reviewer?, :except => [:index, :show]

  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found

  def show
    @lemma = Lemma.find(params[:id])
    @semantic_tags = @lemma.semantic_tags
    @tokens = @lemma.tokens.search(params[:query], :page => current_page)
    @mergeable_lemmata = @lemma.mergeable_lemmata

    show!
  end

  def update
    params[:lemma][:lemma] = params[:lemma][:lemma].mb_chars.normalize(UNICODE_NORMALIZATION_FORM) if params[:lemma]

    update!
  end

  def create
    params[:lemma][:lemma] = params[:lemma][:lemma].mb_chars.normalize(UNICODE_NORMALIZATION_FORM) if params[:lemma]

    create!
  end

  def merge
    @lemma = Lemma.find(params[:id])
    @other_lemma = Lemma.find(params[:other_id])

    if @lemma.mergable?(@other_lemma)
      @lemma.merge!(@other_lemma)

      flash[:notice] = "Lemmata sucessfully merged"
      redirect_to @lemma
    else
      flash[:error] = "Lemmata cannot be merged because base form, language or part of speech do not match"
      redirect_to :action => 'show'
    end
  end

  private

  def collection
    @lemmata = Lemma.search(params[:query], :page => current_page)
  end
end
