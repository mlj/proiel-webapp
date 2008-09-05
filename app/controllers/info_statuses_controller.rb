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


  # PUT /annotations/1/info_status
  def update
    # If we could trust that Hash#keys and Hash#values always return values in the
    # same order, we could simply use params[:tokens].keys and params[:tokens].values as
    # arguments to the ActiveRecord::Base.update method (like in the example in the
    # standard Rails documentation for the method). But can we...?
    ids, attributes = get_ids_and_attributes_from_params
    Token.update(ids, attributes) unless ids.blank?
  rescue
    render :text => '', :status => :not_found
  else
    render :text => '', :status => :ok
  end


  #########
  protected
  #########

  def get_ids_and_attributes_from_params
    ids_ary = []
    attributes_ary = []

    if params[:tokens]
      params[:tokens].each_pair do |id, category|
        ids_ary << id
        attributes_ary << {:info_status => category.tr('-', '_')}
      end
    end

    [ids_ary, attributes_ary]
  end

end
