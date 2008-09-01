class DependenciesController < ApplicationController
  before_filter :is_annotator?, :only => [:edit, :update]

  def show 
    @sentence = Sentence.find(params[:annotation_id])

    respond_to do |format|
      format.html # show.html.erb
      format.svg  { send_data @sentence.dependency_graph.visualise(:svg),
        :filename => "#{params[:id]}.svg",
        :disposition => 'inline',
        :type => "image/svg+xml" }
      format.png  { send_data @sentence.dependency_graph.visualise(:png, :font_name => 'Legendum'),
        :filename => "#{params[:id]}.png",
        :disposition => 'inline',
        :type => "image/png" }
    end
  end
  
  def edit 
    @sentence = Sentence.find(params[:annotation_id])

    @tokens = ActiveSupport::JSON.encode(Hash[*@sentence.tokens.collect do |token| 
      [token.id, { 
        :morphtag => Hash[token.morph].merge({
          :language => @sentence.source.language,
          :finite => [:i, :s, :m, :o].include?(token.morph[:mood]),
          :form => token.form, #FIXME: eliminate when lemmata more stable
          :lemma => token.lemma ? token.lemma.lemma : nil,
        }),
        :empty => token.is_empty?,
        :form => token.form,
        :token_number => token.token_number
      } ] 
    end.flatten])

    # If the sentence hasn't been flagged as "annotated", and none of the tokens have 
    # any relation set, it is likely to be a "pristine" sentence, so we'd be better
    # off not sending any information about structure at all.
    if @sentence.is_annotated? || @sentence.tokens.any? { |token| !token.relation.nil? }
      @structure = params[:output]
      @structure ||= ActiveSupport::JSON.encode(@sentence.dependency_structure)
    else
      @structure = params[:output]
      @structure ||= ActiveSupport::JSON.encode({})
    end
  end

  # Saves changes to relations and has the user review the new structure.
  def update 
    @sentence = Sentence.find(params[:annotation_id])

    if @sentence.is_reviewed? and not user_is_reviewer?
      flash[:error] = 'You do not have permission to update reviewed sentences'
      redirect_to :action => 'edit', :wizard => params[:wizard], :annotation_id => params[:annotation_id]
      return
    end

    unless params[:output].blank?
      # Convert output to a more flexible representation. IDs will match those in
      # the database, except for any new empty dependency nodes, which will have
      # IDs on the form 'newX'.
      @sentence.syntactic_annotation = PROIEL::ValidatingDependencyGraph.new_from_editor(ActiveSupport::JSON.decode(params[:output]))
      @sentence.save!
    
      if params[:wizard]
        redirect_to :controller => :wizard, :action => :save_dependencies, :wizard => params[:wizard]
      else
        redirect_to :action => 'show'
      end
    else
      flash[:error] = 'Invalid dependency structure'
      redirect_to :action => 'edit', :wizard => params[:wizard]
    end
  rescue ActiveRecord::RecordInvalid => invalid 
    flash[:error] = invalid.record.errors.full_messages.join('<br>')
    redirect_to :action => 'edit', :wizard => params[:wizard], :output => params[:output]
  end
end
