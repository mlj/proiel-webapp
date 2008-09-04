class LanguagesController < ReadOnlyController
  private

  def collection
    @languages = Language.search(params[:q], :page => params[:page])
  end
end
