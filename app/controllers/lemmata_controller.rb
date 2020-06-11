#--
#
# Copyright 2009-2016 University of Oslo
# Copyright 2009-2016 Marius L. Jøhndal
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

class LemmataController < ApplicationController
  respond_to :html
  before_action :is_reviewer?, :only => [:edit, :update, :merge]

  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found

  def show
    @lemma = Lemma.find(params[:id])

    if @lemma.nil?
      raise ActiveRecord::RecordNotFound
    else
      @semantic_tags = @lemma.semantic_tags
      @tokens = @lemma.tokens.page(current_page)
      @mergeable_lemmata = @lemma.mergeable_lemmata

      respond_with @lemma
    end
  end

  def edit
    @lemma = Lemma.find(params[:id])

    respond_with @lemma
  end

  def update
    normalize_unicode_params! params[:lemma], :lemma

    @lemma = Lemma.find(params[:id])
    @lemma.update(lemma_params)

    respond_with @lemma
  rescue ActiveRecord::RecordInvalid => invalid
    flash[:error] = invalid.record.errors.full_messages

    respond_with @lemma
  end

  def merge
    @lemma = Lemma.find(params[:id])
    @other_lemma = Lemma.find(params[:other_id])

    if @lemma.mergeable?(@other_lemma)
      @lemma.merge!(@other_lemma)

      flash[:notice] = "Lemmata sucessfully merged"
    else
      flash[:error] = "Lemmata cannot be merged because base form, language or part of speech do not match"
    end

    respond_with @lemma
  end

  def index
    @search = Lemma.order(:lemma).search(params[:q])
    @lemmata = @search.result.page(current_page)

    respond_with @dictionary
  end

  # Returns potential renderings of transliterated lemmata.
  def autocomplete
    form, language = params[:form] || '', params[:language]

    if form.empty?
      # Prevent look-up of all possible completions
      @transliterations = []
      @completions = []
    else
      @transliterations, @completions = LanguageTag.find_lemma_completions(language, form)
    end

    a = []
    @transliterations.each { |t| a << { form: t, gloss: nil, exists: false } }
    @completions.sort_by { |l| l.form }.uniq.each { |t| a << { form: t.form, gloss: t.gloss, exists: true } }

    respond_to do |format|
      format.json { render json: a }
    end
  end

  private

  def lemma_params
    params.require(:lemma).permit(:lemma, :variant, :gloss, :foreign_ids, :language_tag, :part_of_speech_tag)
  end
end
