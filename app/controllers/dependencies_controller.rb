class DependenciesController < ApplicationController
  before_filter :is_annotator?, :only => [:edit, :update]

  def show
    @sentence = Sentence.includes(:tokens => [:lemma]).find(params[:sentence_id])
    mode = user_preferences[:graph_method] ? user_preferences[:graph_method].to_sym : :unsorted
    visualizer = GraphvizVisualizer.instance

    respond_to do |format|
      format.svg  { send_data visualizer.generate(@sentence, :format => :svg, :fontname => 'Legendum', :mode => mode), :filename => "#{params[:id]}.svg", :disposition => 'inline', :type => :svg }
      format.png  { send_data visualizer.generate(@sentence, :format => :png, :fontname => 'Legendum', :mode => mode).force_encoding('BINARY'), :filename => "#{params[:id]}.png", :disposition => 'inline', :type => :png }
      format.dot  { send_data visualizer.generate(@sentence, :format => :dot, :mode => mode), :filename => "#{params[:id]}.dot", :disposition => 'inline', :type => :dot }
    end
  end

  def edit
    @sentence = Sentence.includes(:source_division => [:source]).find(params[:sentence_id])
    @source_division = @sentence.try(:source_division)
    @source = @source_division.try(:source)
  end

  # Saves changes to relations and has the user review the new structure.
  def update
    @sentence = Sentence.find(params[:sentence_id])

    if @sentence.is_reviewed? and not user_is_reviewer?
      flash[:error] = 'You do not have permission to update reviewed sentences'
      redirect_to :action => 'edit', :wizard => params[:wizard], :sentence_id => params[:sentence_id]
      return
    end

    # FIXME: calling ActiveSupport::JSON.decode can trigger a max nesting
    # level error because our hashes can be very deeply nested and there is
    # no way to pass an option to disable the nesting-level check to the
    # JSON library through multi_json. The work around is to call the json
    # gem directly and hope for the best.
    #unless params[:output].blank? || ActiveSupport::JSON.decode(params[:output], :max_nesting => false).blank?
    unless params[:output].blank? || JSON.parse(params[:output], :max_nesting => false).blank?
      # Start a new transaction. Unfortunately, this hacky approach is
      # vital if validation is going to have any effect.
      # synctactic_annotation= will update a number of non-Sentence
      # rows, e.g. Token and SlashEdge, but validation takes place
      # only when sentence.save! is executed. A roll-back in
      # sentence.save! won't have any effect unless the transaction
      # also includes syntactic_annotation=.
      Token.transaction do
        # Convert output to a more flexible representation. IDs will match those in
        # the database, except for any new empty dependency nodes, which will have
        # IDs on the form 'newX'.
        # FIXME: see FIXME above
        #@sentence.syntactic_annotation = Proiel::DependencyGraph.new_from_editor(ActiveSupport::JSON.decode(params[:output]))
        @sentence.syntactic_annotation = Proiel::DependencyGraph.new_from_editor(JSON.parse(params[:output], :max_nesting => false))
        @sentence.save!
      end

      @sentence.set_annotated!(current_user)

      if params[:wizard]
        redirect_to :controller => :wizard, :action => :save_dependencies, :wizard => true
      else
        redirect_to @sentence
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
