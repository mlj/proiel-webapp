class DiscoursesController < ApplicationController
  def show
    source_division = SourceDivision.find(params[:source_division_id])
    @img = source_division.visualize_semantic_relation(SemanticRelationType.find_by_tag("discourse"))

    send_data @img, :filename => "#{params[:source_division_id]}.svg", :disposition => 'inline', :type => :svg
  end
end
