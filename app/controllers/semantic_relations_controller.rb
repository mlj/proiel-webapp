class SemanticRelationsController < ApplicationController
  respond_to :html

  def edit
    @semantic_relation = SemanticRelation.find(params[:id])
  end

  def show
    @semantic_relation = SemanticRelation.find(params[:id])

    respond_with @semantic_relation
  end

  def update
    @semantic_relation = SemanticRelation.find(params[:id])

    if @semantic_relation.update_attributes(params[:semantic_relation])
      flash[:notice] = "Successfully updated semantic relation"
    end

    respond_with @semantic_relation
  end
end
