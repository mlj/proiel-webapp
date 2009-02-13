module SourceDivisionsHelper
  # Creates a table view of a collection of source divisions.
  def source_divisions_table(source_divisions)
    render_tabular source_divisions, [ 'Source', 'Part', '&nbsp;' ]
  end

  # Creates a link to a source division.
  def link_to_source_division(source_division)
    link_to(source_division.title, source_division)
  end
end
