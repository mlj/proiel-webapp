class AuditsController < ReadOnlyController
  before_filter :is_annotator?

  private

  def object
    @change = Audit.find(params[:id])
  end

  def collection
    @changes = Audit.search(params[:query], :page => current_page)
  end
end
