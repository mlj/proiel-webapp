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
  end
end
