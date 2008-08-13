module AnnouncementsHelper
  def announcement_block
    unless current_announcements.empty?
      t = content_tag(:ul, current_announcements.map(&:message).map { |m| content_tag(:li, m) } * "\n")
      t += link_to_remote "Hide this message", :url => "/javascripts/hide_announcement.js"
      content_tag(:div, t, :class => "message-block flash warning", :id => "announcement")
    end
  end

  # Returns an array containing the currently visible announcement messages.
  def current_announcements
    @current_announcements ||= Announcement.current_announcements(session[:announcement_hide_time])
  end
end
