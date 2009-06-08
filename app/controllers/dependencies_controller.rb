class DependenciesController < ApplicationController
  before_filter :is_annotator?, :only => [:edit, :update]

  def show 
    @sentence = Sentence.find(params[:sentence_id])

    graph_options = { :fontname => 'Legendum' }
    graph_options[:linearized] = user_preferences[:graph_method] == "linearized"

    respond_to do |format|
      format.svg  { send_data @sentence.dependency_graph.visualize(:svg, graph_options),
        :filename => "#{params[:id]}.svg", :disposition => 'inline', :type => :svg }
      format.png  { send_data @sentence.dependency_graph.visualize(:png, graph_options),
        :filename => "#{params[:id]}.png", :disposition => 'inline', :type => :png }
    end
  end
  
  def edit 
    @sentence = Sentence.find(params[:sentence_id])
  end

  # Saves changes to relations and has the user review the new structure.
  def update 
    @sentence = Sentence.find(params[:sentence_id])

    if @sentence.is_reviewed? and not user_is_reviewer?
      flash[:error] = 'You do not have permission to update reviewed sentences'
      redirect_to :action => 'edit', :wizard => params[:wizard], :sentence_id => params[:sentence_id]
      return
    end

    unless params[:output].blank? || ActiveSupport::JSON.decode(params[:output]).blank?
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
        @sentence.syntactic_annotation = PROIEL::ValidatingDependencyGraph.new_from_editor(ActiveSupport::JSON.decode(params[:output]))
        @sentence.save!
      end
    
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
