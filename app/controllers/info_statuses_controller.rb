class InfoStatusesController < ApplicationController
  before_filter :find_sentence
  before_filter :is_annotator?, :only => [:edit, :update]

  # GET /annotations/1/info_status
  def show
    set_contrast_options_for(@sentence.source_division)

    respond_to do |format|
      format.html # show.html.erb
    end
  end


  # GET /annotations/1/info_status/edit
  def edit
    set_contrast_options_for(@sentence.source_division)
  end


  # PUT /annotations/1/info_status
  def update
    # If we could trust that Hash#keys and Hash#values always return values in the
    # same order, we could simply use params[:tokens].keys and params[:tokens].values as
    # arguments to the ActiveRecord::Base.update method (like in the example in the
    # standard Rails documentation for the method). But can we...?
    ids, attributes = get_ids_and_attributes_from_params

    new_token_ids = {}
    ids.zip(attributes).each do |id, attr|
      if id.starts_with?('new')
        token = create_prodrop_relation(id, attr)

        # Map the fake new# id to the real id the token got after saving
        new_token_ids[id] = token.id
      else
        token = Token.find(id)
      end
      antecedent_id = attr.delete(:antecedent_id)

      # If the antecedent is a prodrop token, find the real id that has been created for it
      antecedent_id = new_token_ids[antecedent_id] if antecedent_id && antecedent_id.starts_with?('new')

      process_anaphor(token, antecedent_id, attr) if antecedent_id

      attr.delete(:relation)
      attr.delete(:verb_id)
      token.update_attributes!(attr)
    end
  rescue
    render :text => $!, :status => 500
    raise
  else
    render :text => ''
  end


  # POST /annotations/1/info_status/delete_contrast
  def delete_contrast
    Token.delete_contrast(params[:contrast], @sentence.source_division)
  rescue
    render :text => $!, :status => 500
    raise
  else
    render :text => ''
  end


  #########
  protected
  #########

  def find_sentence
    @sentence = Sentence.find(params[:annotation_id])
  end

  def get_ids_and_attributes_from_params
    # Put new and existing tokens into separate arrays to make sure new tokens are saved first
    new_ids_ary = []
    new_attributes_ary = []
    existing_ids_ary = []
    existing_attributes_ary = []

    if params[:tokens]
      params[:tokens].each_pair do |id, values|
        if id.starts_with?('new')
          new_ids_ary << id
        else
          existing_ids_ary << id
        end

        relation = nil
        verb_id = nil
        antecedent_id = nil
        contrast_group = nil
        category = nil
        values.split(';').each do |part|
          case part
          when /^prodrop-(.+?)-token-(\d+)/
            relation = $1
            verb_id = $2
          when /^ant-/: antecedent_id = part.slice('ant-'.length..-1)
          when /^con-/: contrast_group = part.slice('con-'.length..-1)
          when 'null':  # the "category" of a member of a contrast group which is from a non-focussed sentence
          else category = part
          end
        end

        attr = {
          :relation => relation,
          :verb_id => verb_id,
          :antecedent_id => antecedent_id,
          :contrast_group => contrast_group
        }
        # Only set the info status category of the token unless it is null (which will happen if the
        # token is not part of the focussed sentence but is nevertheless included in a contrast group)
        attr[:info_status] = category.tr('-', '_').to_sym if category

        if id.starts_with?('new')
          new_attributes_ary << attr
        else
          existing_attributes_ary << attr
        end
      end
    end

    [new_ids_ary + existing_ids_ary, new_attributes_ary + existing_attributes_ary]
  end

  def create_prodrop_relation(prodrop_id, prodrop_attr)
    relation = prodrop_attr[:relation]
    verb_id = prodrop_attr[:verb_id]

    graph = @sentence.dependency_graph
    verb_node = graph[verb_id]

    verb_token = Token.find(verb_id)
    prodrop_token = @sentence.tokens.create!({
                                               :verse => verb_token.verse,
                                               :token_number => @sentence.max_token_number + 1,
                                               :form => 'PRO-' + relation.upcase,
                                               :relation => relation,
                                               :sort => :prodrop,
                                               :info_status => prodrop_attr[:info_status]
                                             })
    adjust_token_numbers(prodrop_token, verb_token, relation)
    prodrop_node = graph.node_class
    graph.add_node(prodrop_token.id, relation, verb_token.id)
    @sentence.syntactic_annotation = graph
    prodrop_token
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

  def set_contrast_options_for(source_division)
    @contrast_options = ['<option selected="selected"></option>'] + Token.contrast_groups_for(source_division).map(&:to_i).uniq.sort.map do |contrast|
      %Q(<option value="#{contrast}">#{contrast}</option>)
    end
  end

  def process_anaphor(anaphor, antecedent_id, attributes)
    # Remove the anaphor from the old antecedent, if any
    old_antecedent = anaphor.antecedent
    if old_antecedent
      old_antecedent.anaphor_id = nil
      old_antecedent.save!
    end

    # Set the new antecedent
    anaphor.antecedent = Token.find(antecedent_id)

    # Set the distance to the antecedent in terms of tokens and sentences
    anaphor.antecedent_dist_in_words = Token.word_distance_between(anaphor.antecedent, anaphor)
    anaphor.antecedent_dist_in_sentences = Token.sentence_distance_between(anaphor.antecedent, anaphor)
  end
end
