class DependenciesController < ApplicationController
  before_filter :is_annotator?, :only => [:edit, :update]

  def show 
    @sentence = Sentence.find(params[:annotation_id])

    graph_options = { :fontname => 'Legendum' }
    graph_options[:linearized] = user_preferences[:graph_method] == "linearized"

    respond_to do |format|
      format.html # show.html.erb
      format.svg  { send_data @sentence.dependency_graph.visualize(:svg, graph_options),
        :filename => "#{params[:id]}.svg", :disposition => 'inline', :type => "image/svg+xml" }
      format.png  { send_data @sentence.dependency_graph.visualize(:png, graph_options),
        :filename => "#{params[:id]}.png", :disposition => 'inline', :type => "image/png" }
    end
  end
  
  def edit 
    @sentence = Sentence.find(params[:annotation_id])

    @tokens = Hash[*@sentence.dependency_tokens.collect do |token|
      [token.id, { 
        :morphtag => Hash[token.morph].merge({
          :language => @sentence.source.language,
          :finite => [:i, :s, :m, :o].include?(token.morph[:mood]),
          :form => token.form,
          :lemma => token.lemma ? token.lemma.lemma : nil,
        }),
        :empty => token.is_empty? ? token.empty_token_sort : false,
        :form => token.form,
        :token_number => token.token_number
      } ] 
    end.flatten]

    @structure = (params[:output] and ActiveSupport::JSON.decode(params[:output])) || (@sentence.has_dependency_annotation? ? @sentence.dependency_graph.to_h : {})

    @relations = PROIEL::RELATIONS.values.sort_by { |v| v.code.to_s }
  end

  # Saves changes to relations and has the user review the new structure.
  def update 
    @sentence = Sentence.find(params[:annotation_id])

    if @sentence.is_reviewed? and not user_is_reviewer?
      flash[:error] = 'You do not have permission to update reviewed sentences'
      redirect_to :action => 'edit', :wizard => params[:wizard], :annotation_id => params[:annotation_id]
      return
    end

    unless params[:output].blank? || ActiveSupport::JSON.decode(params[:output]).blank?
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
