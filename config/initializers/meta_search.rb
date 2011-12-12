MetaSearch::Where.add :wildcard_matches, :wm,
  :types => [:string, :text], :predicate => :matches,
  :formatter => Proc.new { |p| p.gsub('*', '%').gsub('?', '_') }
