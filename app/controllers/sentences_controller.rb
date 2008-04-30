class SentencesController < ApplicationController
  # GET /sentences
  # GET /sentences.xml
  def index
    @sentences = Sentence.search(params.slice(:source, :book, :chapter, :sentence_number), params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @sentences }
    end
  end

  # GET /sentence/1
  # GET /sentence/1.xml
  def show
    @sentence = Sentence.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @sentence }
    end
  end
end
