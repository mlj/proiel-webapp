class InfoStatusesController < ApplicationController
  before_filter :is_annotator?, :only => [:edit, :update]

  # GET /annotations/1/info_status
  def show
    @sentence = Sentence.find(params[:annotation_id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end


  # GET /annotations/1/info_status/edit
  def edit
    @sentence = Sentence.find(params[:annotation_id])
    @contrast_options = ['<option></option>'] + Token.contrast_groups_for(@sentence.chapter).map(&:to_i).uniq.map do |contrast|
      %Q(<option value="#{contrast}">#{contrast}</option>)
    end
  end


  # PUT /annotations/1/info_status
  def update
    @sentence = Sentence.find(params[:annotation_id])

    # If we could trust that Hash#keys and Hash#values always return values in the
    # same order, we could simply use params[:tokens].keys and params[:tokens].values as
    # arguments to the ActiveRecord::Base.update method (like in the example in the
    # standard Rails documentation for the method). But can we...?
    ids, attributes = get_ids_and_attributes_from_params
    ids.zip(attributes).each do |id, attr|
      if(id.starts_with?('new'))
        create_prodrop_relation(id, attr)
      else
        antecedent_id = attr.delete(:antecedent_id)
        if antecedent_id
          # Remove the anaphor from the old antecedent, if any
          old_antecedent = Token.find(id).antecedent
          if old_antecedent
            old_antecedent.anaphor_id = nil
            old_antecedent.save!
          end

          # Set the anaphor id on the new antecedent
          Token.find(antecedent_id).update_attribute(:anaphor_id, id)
        end

        # Update the remaining attributes
        Token.find(id).update_attributes!(attr)

      end
    end
  rescue
    render :text => $!, :status => 500
    raise
  else
    render :text => ''
  end


  #########
  protected
  #########

  def get_ids_and_attributes_from_params
    ids_ary = []
    attributes_ary = []

    if params[:tokens]
      params[:tokens].each_pair do |id, values|
        ids_ary << id

        antecedent_id = nil
        contrast_group = nil
        category = nil
        values.split(';').each do |part|
          case part
          when /^ant-/: antecedent_id = part.slice('ant-'.length..-1)
          when /^con-/: contrast_group = part.slice('con-'.length..-1)
          when 'null':  # the "category" of a member of a contrast group which is from a non-focussed sentence
          else category = part
          end
        end

        attributes_ary << {
          :antecedent_id => antecedent_id,
          :contrast_group => contrast_group
        }
        # Only set the info status category of the token unless it is null (which will happen if the
        # token is not part of the focussed sentence but is nevertheless included in a contrast group)
        attributes_ary.last[:info_status] = category.tr('-', '_').to_sym if category
      end
    end

    [ids_ary, attributes_ary]
  end

  def create_prodrop_relation(prodrop_id, prodrop_attr)
    prodrop_attr[:info_status].to_s =~ /(.+?);prodrop_(.+?)_token_(\d+)/
    info_status = $1
    relation = $2
    verb_id = $3.to_i

    graph = @sentence.dependency_graph
    verb_node = graph[verb_id]

    verb_token = Token.find(verb_id)
    prodrop_token = @sentence.tokens.create!({
                                               :verse => verb_token.verse,
                                               :token_number => @sentence.max_token_number + 1,
                                               :form => 'PRO-' + relation.upcase,
                                               :relation => relation,
                                               :sort => :prodrop,
                                               :info_status => info_status
                                             })
    adjust_token_numbers(prodrop_token, verb_token, relation)
    prodrop_node = graph.node_class
    graph.add_node(prodrop_token.id, relation, verb_token.id)
    @sentence.syntactic_annotation = graph
  end

  # Moves a new prodrop token to the correct position in the token_number sequence
  def adjust_token_numbers(prodrop_token, verb_token, relation)
    new_token_number = verb_token.token_number + (relation == 'sub' ? 0 : 1)

    # Move all later tokens one step to the right
    @sentence.tokens.reverse.each do |token|
      if token.token_number >= new_token_number
        token.token_number += 1
        token.save!
      else
        break
      end
    end

    # Insert the prodrop token in the correct position
    prodrop_token.token_number = new_token_number
    prodrop_token.save!
  end
end
