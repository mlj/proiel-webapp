class InfoStatusesController < ApplicationController
  before_action :find_sentence
  before_action :is_annotator?, :only => [:edit, :update]

  # GET /sentences/1/info_status/edit
  def edit
    @source_division = @sentence.source_division
    @source = @source_division.source

    s = @source_division.contrast_groups.map(&:to_i).sort.uniq.map do |contrast|
      %Q(<option value="#{contrast}">#{contrast}</option>)
    end.join
    @contrast_options = ('<option selected="selected"></option>' + s).html_safe
  end

  # PUT /sentences/1/info_status
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
      antecedent_id = attr[:antecedent_id]


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
    render :text => new_token_ids.to_json
  end

  # POST /sentences/1/info_status/delete_contrast
  def delete_contrast
    @sentence.source_division.delete_contrast_group!(params[:contrast])
  rescue
    render :text => $!, :status => 500
    raise
  else
    render :text => ''
  end

  # POST /sentences/1/info_status/delete_contrast
  def delete_prodrop
    t = Token.find(params[:prodrop_id])
    t.destroy
  rescue
    render :text => $!, :status => 500
    raise
  else
    render :text => ''
  end

  protected

  def find_sentence
    @sentence = Sentence.find(params[:sentence_id])
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
          when /^ant-/
            antecedent_id = part.slice('ant-'.length..-1)
          when /^con-/
            contrast_group = part.slice('con-'.length..-1)
          when 'null'
            # the "category" of a member of a contrast group which is from a non-focussed sentence
          else
            category = part
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
        attr[:information_status_tag] = category.tr('-', '_') if category

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
    @sentence.append_new_token!(
      :head_id => prodrop_attr[:verb_id],
      :relation_tag => prodrop_attr[:relation],
      :empty_token_sort => 'P',
      :information_status_tag => prodrop_attr[:information_status]).tap do

      # This is needed after saving a new graph node to the database
      # in order to make sure that the new node is included in the
      # tokens.takes_syntax collection. Otherwise, the node
      # will be deleted the next time we run syntactic_annotation=
      # (e.g., if we try to create more than one prodrop token as part
      # of the same save operation).
      @sentence.tokens.reload
    end
  end

  def process_anaphor(anaphor, antecedent_id, attributes)
    # Set the new antecedent
    anaphor.antecedent = Token.find(antecedent_id)
  end
end
