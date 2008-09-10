class Announcement < ActiveRecord::Base
  belongs_to :role

  def self.current_announcements(hide_time)
    with_scope :find => { :conditions => "starts_at <= now() AND ends_at >= now()" } do
      if hide_time.nil?
        find(:all)
      else
        find(:all, :conditions => ["updated_at > ? OR starts_at > ?", hide_time, hide_time])
      end
    end
  end

  protected

  def self.search(query, options = {})
    options[:conditions] ||= ["message LIKE ?", "%#{query}%"] unless query.blank?

    paginate options
  end

end
