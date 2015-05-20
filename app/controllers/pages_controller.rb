class PagesController < ApplicationController
  layout :layout_for_page

  def export
    file_name = export_file_name_with_path(params[:id], params[:format])

    if File.exists?(file_name)
      send_file(file_name)
    else
      flash[:error] = 'File not found'
      redirect_to :back
    end
  end

  protected

  def layout_for_page
    case params[:id]
    when 'home'
      'home'
    else
      'application'
    end
  end
end
