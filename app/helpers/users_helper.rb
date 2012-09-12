module UsersHelper
  # Returns a link to a user.
  def link_to_user(user)
    link_to(user.full_name, user)
  end
end
