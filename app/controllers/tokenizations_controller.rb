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

class TokenizationsController < ApplicationController
  before_action :is_annotator?, :only => [:edit, :update]

  def edit
    @sentence = Sentence.includes(:source_division => [:source]).find(params[:sentence_id])
    @source_division = @sentence.try(:source_division)
    @source = @source_division.try(:source)
    @sentence_window = @sentence.sentence_window.includes(:tokens).all
  end

  def update
    @sentence = Sentence.find(params[:sentence_id])

    if params[:op_id]
      @target_token = Token.find(params[:op_id])

      unless @sentence.tokens.include?(@target_token)
        flash[:error] = 'Token does not belong to sentence'
        redirect_to :action => 'edit'
        return
      end
    end

    case params[:op]
    when 'split'
      unless @target_token.is_splitable?
        flash[:error] = 'Token cannot be split'
        redirect_to :action => 'edit'
        return
      end

      flash[:notice] = 'Tokenization updated.'
      @target_token.split_token!

    when 'join'
      unless @target_token.is_joinable?
        flash[:error] = 'Token cannot be joined'
        redirect_to :action => 'edit'
        return
      end

      flash[:notice] = 'Tokenization updated.'
      @target_token.join_with_next_token!

    when 'merge_with_next_sentence'
      if @sentence.is_next_sentence_appendable?
        if @sentence.valid? and @sentence.next_object.valid?
          @sentence.append_next_sentence!
          flash[:notice] = 'Sentences merged.'
        else
          flash[:error] = 'One of the sentences is invalid.'
          redirect_to :action => 'edit'
          return
        end
      else
        flash[:error] = 'Next sentence not found.'
        redirect_to :action => 'edit'
        return
      end

    when 'split_sentence'
      if @sentence.valid? and @sentence.is_splitable?(@target_token)
        @sentence.split_sentence!(@target_token)
        flash[:notice] = 'Sentence split.'
      else
        flash[:error] = 'Sentence cannot be split.'
        redirect_to :action => 'edit'
        return
      end
    else
      flash[:error] = 'Invalid tokenization operation'
      redirect_to :action => 'edit'
      return
    end

    respond_to do |format|
      format.html { redirect_to :action => 'edit' }
    end
  rescue ActiveRecord::RecordInvalid => invalid
    if invalid.record.id.nil?
      flash[:error] = invalid.record.errors.full_messages.map { |m| "New #{invalid.record.class}: #{m}" }.join('<br>')
    else
      flash[:error] = invalid.record.errors.full_messages.map { |m| "#{invalid.record.class} #{invalid.record.id}: #{m}" }.join('<br>')
    end

    redirect_to :action => 'edit'
  end
end
