module UsersHelper
  # Returns a user's full name.
  #
  # ==== Options
  # role:: Includes the user's role.
  def readable_name(user, options = {})
    user.full_name + (options[:role] ? " (#{user.role.description})" : '')
  end

  # Returns a link to a user.
  #
  # ==== Options
  # role:: Includes the user's role.
  def link_to_user(user, options = {})
    link_to(readable_name(user), user) + (options[:role] ? " (#{user.role.description})" : '')
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
