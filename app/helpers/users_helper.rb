module UsersHelper
  # Returns a select tag for users.
  #
  # ==== Options
  # +:include_blank+:: If +true+, includes an empty value first.
  def user_select_tag(name, value, options = {})
    _select_tag_db(name, User, :full_name, value, options)
  end

  # Returns a link to a user.
  def link_to_user(user)
    link_to(user.full_name, user)
  end
end
