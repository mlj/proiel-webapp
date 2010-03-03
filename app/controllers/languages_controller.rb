class LanguagesController < InheritedResources::Base
  actions :index, :show

  private

  def collection
    @languages = Language.search(params[:q], :page => params[:page])
  end
end
