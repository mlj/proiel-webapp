module SourceDivisionsHelper
  # Creates a link to a source division.
  def link_to_source_division(source_division)
    link_to(source_division.title, source_division)
  end
end
