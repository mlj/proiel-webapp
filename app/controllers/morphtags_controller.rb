# Controls modification of morphtags on a per sentence basis.
class MorphtagsController < ApplicationController
  before_filter :is_annotator?, :only => [:edit, :update]

  # Returns potential renderings of transliterated lemmata.
  def auto_complete_for_morphtags_lemma
    @transliterations, c = Language.find_lemma_completions(params[:morphtags][:language], params[:morphtags][:lemma])
    @completions = c.map(&:export_form).sort.uniq

    render :partial => "transliterations/input"
  end

  def show
    @sentence = Sentence.find(params[:sentence_id])
  end

  def edit
    @sentence = Sentence.find(params[:sentence_id])
  end

  def update
    @sentence = Sentence.find(params[:sentence_id])

    if @sentence.is_reviewed? and not user_is_reviewer?
      flash[:error] = 'You do not have permission to update reviewed sentences'
      redirect_to :action => 'edit', :wizard => params[:wizard], :sentence_id => params[:sentence_id]
      return
    end

    Token.transaction do
      params.keys.select { |key| key[/^morph-features-/] }.each do |key|
        token_id = key.sub(/^morph-features-/, '')
        token = Token.find(token_id)
        x, y, z, w = params[key].split(/,\s*/) #FIXME
        token.morph_features = MorphFeatures.new([x,y,z].join(','), w)
      end
    end

    if params[:wizard]
      redirect_to :controller => :wizard, :action => :edit_dependencies, :wizard => true
    else
      redirect_to @sentence
    end
  rescue ActiveRecord::RecordInvalid => invalid
    flash[:error] = invalid.record.errors.full_messages
    # FIXME: nasty way of ensuring that "edit" respects our current settings
    uf = {}
    params.keys.select { |key| key[/^morph-features-/] }.each do |key|
      uf[key] = params[key]
    end
    redirect_to uf.merge({ :action => 'edit', :wizard => params[:wizard] })
  end
end
