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
  before_action :set_lemma, only: [:show, :update]

  respond_to :html
  before_filter :is_reviewer?, :only => [:update, :merge]

  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found

  # GET /lemmas
  # GET /lemmas.json
  def index
    l = Lemma.order(:lemma)
    l = l.where(language: params[:language]) if params[:language]
    l = l.where(part_of_speech_tag: params[:part_of_speech]) if params[:part_of_speech]

    if params[:form]
      base, variant = params[:form].split('#')
      l = l.where("lemma LIKE ?", base.gsub('.', '_').gsub('*', '%')) unless base.blank?
      l = l.where(variant: variant) unless variant.blank?
    end

    @limit = 50
    @count = l.count
    @page = params[:page].to_i || 0
    @pages = (@count / @limit.to_f).ceil

    @lemmata = l.limit(@limit).offset(@page * @limit)

    respond_to do |format|
      format.html
      format.json
    end
  end

  # GET /lemmas/1
  # GET /lemmas/1.json
  def show
    @lemma = Lemma.find(params[:id])

    respond_to do |format|
      format.html {
        if @lemma.nil?
          raise ActiveRecord::RecordNotFound
        else
          @semantic_tags = @lemma.semantic_tags
          @tokens = @lemma.tokens.page(current_page)
          @mergeable_lemmata = @lemma.mergeable_lemmata
          @notes = @lemma.notes.sort_by(&:created_at).reverse
          @audits = @lemma.audits.sort_by(&:created_at).reverse

          respond_with @lemma
        end
      }
      format.json
    end
  end

  # POST /lemmata.json
  def create
    @lemma = Lemma.new(lemma_params)

    respond_to do |format|
      if @lemma.save
        format.json { render :show, status: :created, location: @lemma }
      else
        format.json { render json: @lemma.eroors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /lemmas/1.json
  def update
    respond_to do |format|
      if @lemma.update(lemma_params)
        format.json { render :show, status: :ok, location: @lemma }
      else
        format.json { render json: @lemma.errors, status: :unprocessable_entity }
      end
    end
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

  def set_lemma
    @lemma = Lemma.find(params[:id])
  end

  def lemma_params
    #params.fetch(:lemma, {})
    params.require(:lemma).permit(:lemma, :variant, :gloss, :foreign_ids, :language_tag, :part_of_speech_tag)
  end
end
