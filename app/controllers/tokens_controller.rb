#--
#
# Copyright 2009-2016 University of Oslo
# Copyright 2009-2017 Marius L. Jøhndal
#
# This file is part of the PROIEL web application.
#
# The PROIEL web application is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.
#
# The PROIEL web application is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the PROIEL web application.  If not, see
# <http://www.gnu.org/licenses/>.
#
#++

class TokensController < ApplicationController
  respond_to :html
  before_action :is_administrator?, :only => [:edit, :update]

  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found

  def show
    @token = Token.includes(:sentence => [:source_division => [:source]]).find(params[:id])

    if @token.nil?
      raise ActiveRecord::RecordNotFound
    else
      @sentence = @token.sentence
      @source_division = @sentence.source_division
      @source = @source_division.source

      @semantic_tags = @token.semantic_tags
      # Add semantic tags from lemma not present in the token's semantic tags.
      @semantic_tags += @token.lemma.semantic_tags.reject { |tag| @semantic_tags.map(&:semantic_attribute).include?(tag.semantic_attribute) } if @token.lemma

      @outgoing_semantic_relations = @token.outgoing_semantic_relations
      @incoming_semantic_relations = @token.incoming_semantic_relations

      @notes = @token.notes
      @audits = @token.audits

      respond_with @token
    end
  end

  def edit
    @token = Token.includes(:sentence => [:source_division => [:source]]).find(params[:id])

    if @token.nil?
      raise ActiveRecord::RecordNotFound
    else
      @sentence = @token.sentence
      @source_division = @sentence.source_division
      @source = @source_division.source

      @possible_binders =
        Token.with_semantic_tag('LOGOCENTRE').where(sentence_id: @sentence.previous_objects.pluck(:id)) +
        @sentence.tokens.order(:token_number)

      respond_with @token
    end
  end

  def update
    normalize_unicode_params! params[:token], :presentation_before, :presentation_after, :form

    @token = Token.find(params[:id])
    @token.update!(token_params)

    respond_with @token.sentence
  end

  def dependency_alignment_group
    @token = Token.find(params[:id])
    alignment_set, edge_count = @token.dependency_alignment_set

    render :json => { :alignment_set => alignment_set.map(&:id), :edge_count => edge_count }
  end

  def index
    @search = Token.search(params[:q])

    # Location sorts are actually multi-sorts. Inspecting @search.sorts may
    # seem like the sensible solution to this, but this is actually an array of
    # non-inspectable objects. We'll instead peek at params[:q][:s] and
    # instruct ransack what to do based on its value.
    sort_order = params[:q] ? params[:q][:s] : nil

    case sort_order
    when NilClass, '', 'location asc' # default
      @search.sorts = ['sentence_source_division_source_id asc',
                       'sentence_source_division_position asc',
                       'sentence_sentence_number asc',
                       'token_number asc']
    when 'location desc'
      @search.sorts = ['sentence_source_division_source_id desc',
                       'sentence_source_division_position desc',
                       'sentence_sentence_number desc',
                       'token_number desc']
    else
      # Do nothing; ransack has already taken care of it.
    end

    respond_to do |format|
      format.html do
        @tokens = @search.result.page(current_page)
      end
      format.csv do
        if @search.result.count > 5000
          head :no_content
        end
      end
      format.txt do
        if @search.result.count > 5000
          head :no_content
        end
      end
    end
  end

  def quick_search
    q = params[:q].strip

    case q
    when '' # reload the same page
      redirect_to :back
    when /^\d+$/ # look up a sentence ID
      redirect_to sentence_url(q.to_i)
    else # match against token forms
      redirect_to tokens_url(:q => { :form_wildcard_matches => "#{q}*" })
    end
  end

  private

  def token_params
    params.require(:token).permit(:sentence_id, :token_number, :form, :lemma_id, :head_id,
      :source_morphology_tag, :source_lemma, :foreign_ids, :information_status_tag,
      :empty_token_sort, :contrast_group, :token_alignment_id,
      :automatic_token_alignment, :dependency_alignment_id, :antecedent_id,
      :morphology_tag, :citation_part, :presentation_before, :presentation_after,
      :relation_tag, :created_at, :updated_at)
  end
end
