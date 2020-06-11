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

class SentencesController < ApplicationController
  respond_to :html
  before_action :is_reviewer?, :only => [:flag_as_reviewed, :flag_as_not_reviewed]
  before_action :is_annotator?, :only => [:edit, :update]

  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found

  def show
    @sentence = Sentence.includes(:source_division => [:source],
                                  :tokens => [:lemma, :audits, :notes],
                                  :notes => [],
                                  :audits => [:auditable]).find(params[:id])
    @source_division = @sentence.source_division
    @source = @source_division.try(:source)

    @sentence_window = @sentence.sentence_window.includes(:tokens)
    @semantic_tags = @sentence.semantic_tags

    @tokens_with_foreign_ids = @sentence.tokens.where('foreign_ids IS NOT NULL')
    @notes = (@sentence.notes + @sentence.tokens.map(&:notes).flatten).sort_by(&:created_at).reverse
    @audits = (@sentence.audits + @sentence.tokens.map(&:audits).flatten).sort_by(&:created_at).reverse

    mode = params[:method] || user_preferences[:graph_method] || :unsorted

    @user = current_user
    @user.preferences_will_change!
    @user.update_attributes! graph_method: mode

    respond_to do |format|
      format.html
      format.svg  { send_data @sentence.visualize(:svg, mode), filename: "#{params[:id]}.svg", disposition: :inline, type: :svg }
      format.dot  { send_data @sentence.visualize(:dot, mode), filename: "#{params[:id]}.dot", disposition: :inline, type: :dot } 
      format.json {
        render json: @sentence.to_json(
          include: {
            source_division: {
              include: {
                source: {}
              }
            },

            tokens: {
              methods: %i(msd guesses slashes),

              include: {
                lemma: {
                  methods: :form
                }
              }
            },
          },
        )
      }
    end
  end

  def edit
    @sentence = Sentence.includes(:source_division => [:source]).find(params[:id])
    @source_division = @sentence.try(:source_division)
    @source = @source_division.try(:source)

    respond_with @sentence
  end

  def update
    normalize_unicode_params! params[:sentence], :presentation_before, :presentation_after

    @sentence = Sentence.find(params[:id])

    if @sentence.is_reviewed? and not user_is_reviewer?
      flash[:error] = 'You do not have permission to update reviewed sentences'
      redirect_to action: 'edit', wizard: params[:wizard], sentence_id: params[:sentence_id]
      return
    end

    respond_to do |format|
      format.html do
        @sentence.update!(sentence_params)
        flash[:notice] = 'Sentence was successfully updated.'
        respond_with @sentence
      end

      format.json do
        tokens = ActiveSupport::JSON.decode(params[:tokens])
        @sentence.update_annotation!(tokens)

        render json: @sentence
      end
    end
  rescue ActiveRecord::RecordInvalid => invalid
    flash[:error] = invalid.record.errors.full_messages.join('<br>')
    redirect_to action: 'edit', wizard: params[:wizard], output: params[:output]
  end

  def x
    # FIXME: calling ActiveSupport::JSON.decode can trigger a max nesting
    # level error because our hashes can be very deeply nested and there is
    # no way to pass an option to disable the nesting-level check to the
    # JSON library through multi_json. The work around is to call the json
    # gem directly and hope for the best.
    #unless params[:output].blank? || ActiveSupport::JSON.decode(params[:output], :max_nesting => false).blank?
    unless params[:output].blank? || JSON.parse(params[:output], :max_nesting => false).blank?
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
        # FIXME: see FIXME above
        #@sentence.syntactic_annotation = Proiel::DependencyGraph.new_from_editor(ActiveSupport::JSON.decode(params[:output]))
        @sentence.syntactic_annotation = Proiel::DependencyGraph.new_from_editor(JSON.parse(params[:output], :max_nesting => false))
        @sentence.save!
      end

      @sentence.set_annotated!(current_user)
    end
  end

  def flag_as_reviewed
    @sentence = Sentence.find(params[:id])

    @sentence.set_reviewed!(current_user)
    flash[:notice] = 'Sentence was successfully updated.'
    redirect_to @sentence
  rescue ActiveRecord::RecordInvalid => invalid
    flash[:error] = invalid.record.errors.full_messages.map { |m| "#{invalid.record.class} #{invalid.record.id}: #{m}" }.join('<br>')
    redirect_to @sentence
  end

  def flag_as_not_reviewed
    @sentence = Sentence.find(params[:id])

    @sentence.unset_reviewed!(current_user)
    flash[:notice] = 'Sentence was successfully updated.'
    redirect_to @sentence
  rescue ActiveRecord::RecordInvalid => invalid
    flash[:error] = invalid.record.errors.full_messages.join('<br>')
    redirect_to @sentence
  end

  def export
    @sentence = Sentence.find(params[:id])

    result = LatexGlossingExporter.instance.generate(@sentence)

    respond_to do |format|
      format.html { send_data result, disposition: 'inline', type: :html }
    end
  end

  private

  def sentence_params
    params.require(:sentence).permit(:sentence_number, :annotated_by, :annotated_at, :reviewed_by,
      :reviewed_at, :unalignable, :automatic_alignment, :sentence_alignment_id,
      :source_division_id, :assigned_to, :presentation_before, :presentation_after,
      :status_tag, :created_at, :updated_at)
  end
end
