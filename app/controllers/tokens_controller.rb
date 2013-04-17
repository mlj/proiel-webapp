# encoding: UTF-8
#--
#
# Copyright 2009, 2010, 2011, 2012, 2013 University of Oslo
# Copyright 2009, 2010, 2011, 2012, 2013 Marius L. Jøhndal
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
  before_filter :is_administrator?, :only => [:edit, :update]

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

      respond_with @token
    end
  end

  def update
    normalize_unicode_params! params[:token], :presentation_before, :presentation_after, :form

    @token = Token.find(params[:id])
    @token.update_attributes(params[:token])

    respond_with @token
  end

  def dependency_alignment_group
    @token = Token.find(params[:id])
    alignment_set, edge_count = @token.dependency_alignment_set

    render :json => { :alignment_set => alignment_set.map(&:id), :edge_count => edge_count }
  end

  def index
    @search = Token.search(params[:q])

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
end
