module UsersHelper
  # Returns a select tag for users.
  #
  # ==== Options
  # +:include_blank+:: If +true+, includes an empty value first.
  def user_select_tag(name, value, options = {})
    _select_tag_db(name, User, :full_name, value, options)
  end

  # Returns a link to a user.
  #
  # ==== Options
  # role:: Includes the user's role.
  def link_to_user(user, options = {})
    link_to(user.full_name, user) + (options[:role] ? " (#{user.role.description})" : '')
  end

  # Returns true if the current user is an administrator.
  def is_administrator?
    current_user.has_role?(:administrator)
  end

  # Returns true if the current user is a reviewer.
  def is_reviewer?
    current_user.has_role?(:reviewer)
  end

  # Returns true if the current user is an annotator.
  def is_annotator?
    current_user.has_role?(:annotator)
  end
end
