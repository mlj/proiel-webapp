# Controls modification of morphtags on a per sentence basis.
class MorphtagsController < ApplicationController
  before_filter :is_annotator?, :only => [:edit, :update]

  # Returns potential renderings of transliterated lemmata.
  def auto_complete_for_morphtags_lemma
    search = params[:morphtags][:lemma]

    # Perform transliteration
    if !params[:morphtags][:language].blank? and TRANSLITERATORS.has_key?(params[:morphtags][:language].to_sym)
      xliterator = Logos::TransliteratorFactory::get_transliterator(TRANSLITERATORS[params[:morphtags][:language].to_sym])
      @results = xliterator.transliterate_string(search)

      completion_candidates = @results
    else
      @results = []

      completion_candidates = [params[:morphtags][:lemma]]
    end

    # Auto-complete lemmata
    completions = completion_candidates.collect do |result|
      Lemma.find_completions(result, params[:morphtags][:language]).map(&:export_form)
    end.flatten

    @completions = completions.sort.uniq
    @transliterations = @results.sort.uniq

    render :partial => "transliterations/input"
  end

  def show
    @sentence = Sentence.find(params[:annotation_id])
  end

  def edit
    @sentence = Sentence.find(params[:annotation_id])
    @language_code = @sentence.language.iso_code

    @tags = @sentence.morphtaggable_tokens.inject({}) do |tags, token|
      tags[token.id] = {}

      result, tags[token.id][:pick], *tags[token.id][:suggestions] = token.invoke_tagger

      # Figure out which morph+lemma-tag to use as the displayed value. Anything
      # already set in the editor or, if nothing there, in the morphtag field
      # trumphs whatever the tagger may decide to spew out. To have the state set
      # correctly, we pretend we don't have any data from the editor first, and
      # then check to see if any values given are different from what we determined
      # to be our choice. If it is different, then set to "annotated".
      if token.morphtag and token.lemma_id
        tags[token.id][:set] = token.morph_lemma_tag
        tags[token.id][:state] = :mannotated
      elsif tags[token.id][:pick]
        tags[token.id][:set] = tags[token.id][:pick]
        tags[token.id][:state] = :mguessed
      else
        if token.morphtag and not token.lemma_id
          tags[token.id][:set] = token.morph_lemma_tag 
        else
          tags[token.id][:set] = nil
        end
        tags[token.id][:state] = :munannotated
      end

      if x = params["morphtag-#{token.id}".to_sym] and y = params["lemma-#{token.id}".to_sym]
        xy = PROIEL::MorphLemmaTag.new("#{x}:#{y}")
        if tags[token.id][:set] != xy
          tags[token.id][:set] = xy
          tags[token.id][:state] = :mannotated
        end
      end

      tags
    end

    respond_to do |format|
      format.html { render :layout => false if request.xhr? } 
      format.js { render :layout => false }
    end
  end

  def update
    @sentence = Sentence.find(params[:annotation_id])

    if @sentence.is_reviewed? and not user_is_reviewer?
      flash[:error] = 'You do not have permission to update reviewed sentences'
      redirect_to :action => 'edit', :wizard => params[:wizard], :annotation_id => params[:annotation_id]
      return
    end

    Token.transaction do
      # Cycle the parameters and check whether this one originated with us 
      # or with them...
      params.keys.reject { |key| !(key =~ /^morphtag-/) }.each do |key|
        token_id = key.sub(/^morphtag-/, '')
        new_morphtag = PROIEL::MorphTag.new(ActiveSupport::JSON.decode(params[key]))
        new_lemma = params['lemma-' + token_id]

        ml = PROIEL::MorphLemmaTag.new("#{new_morphtag.to_s}:#{new_lemma}")

        token = Token.find(token_id)
        token.set_morph_lemma_tag!(ml) if token.morph_lemma_tag != ml
      end
    end

    if params[:wizard]
      redirect_to :controller => :wizard, :action => :save_morphtags, :wizard => params[:wizard]
    else
      redirect_to :action => 'show'
    end
  rescue ActiveRecord::RecordInvalid => invalid 
    flash[:error] = invalid.record.errors.full_messages
    # FIXME: ensure that "edit" respects our current settings?
    redirect_to :action => 'edit', :wizard => params[:wizard]
  end
end
