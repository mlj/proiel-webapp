class DependenciesController < ApplicationController
  before_filter :is_annotator?, :only => [:edit, :update]

  def show 
    @sentence = Sentence.find(params[:annotation_id])

    respond_to do |format|
      format.html # show.html.erb
      format.png  { send_data @sentence.dependency_graph.visualise(:png),
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
        :empty => token.empty?,
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

    if @sentence.is_reviewed? and not current_user.has_role?(:reviewer)
      flash[:error] = 'You do not have permission to update reviewed sentences'
      redirect_to :action => 'edit', :wizard => params[:wizard], :annotation_id => params[:annotation_id]
      return
    end

    if params[:output] and params[:output] != ''
      s = ActiveSupport::JSON.decode(params[:output])

      # Extract a list of token IDs mentioned in the data
      affected_tokens = (rec = lambda do |subtree, result|
        return result if subtree.nil?

        subtree.each_pair do |id, values|
          result << id.to_i #TODO: this inserts 0's for empty tokens now
          result = rec[values['dependents'], result]
        end

        return result
      end)[s, []]

      removed_tokens = @sentence.tokens.collect(&:id) - affected_tokens

      Token.transaction(session[:user]) do
        # Since the new analysis may overwrite an old one, we need to do some housekeeping
        # first. To ensure that the history appears atomic, each token must be updated only
        # once, and each token has to be touched.
        # 
        # The new analysis may be a partial analysis. If the old analysis had greater coverage,
        # we must clear the information from the old analysis and ensure that only the affected
        # tokens have their history updated.
        @sentence.tokens.reject { |token| !removed_tokens.include?(token.id) }.each do |token|
          if token.form.nil?
            # This is an empty token which apparently no longer takes part in the analysis.
            Token.destroy(token)
          else
            token.clear_dependencies!
          end
        end

        new_ids = {}
        @sentence.update_dependencies!(s, new_ids)

        # Deal with slashes. First extract the slashes from the list of
        # updates and merge in new IDs for new empty nodes.
        slashes = (rec = lambda do |subtree, result|
          return result if subtree.nil?

          subtree.each_pair do |id, values|
            result += values['slashes'].collect { |slash| [ id[/^new/] ? new_ids[id] : id.to_i, 
                                                            slash[/^new/] ? new_ids[slash] : slash.to_i] } if values['slashes']
            result = rec[values['dependents'], result]
          end

          return result
        end)[s, []]

        @sentence.update_slashes!(slashes)

        # Save the sentence just to make validation happen
        @sentence.save!
      end
    
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
