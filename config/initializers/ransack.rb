Ransack.add_predicate :wildcard_matches, :arel_predicate => :matches, :formatter => proc { |p| p.gsub('*', '%').gsub('?', '_') }

Ransack.add_predicate :char0_matches, :arel_predicate => :matches, :formatter => proc { |p| "#{p}_________" }
Ransack.add_predicate :char1_matches, :arel_predicate => :matches, :formatter => proc { |p| "_#{p}________" }
Ransack.add_predicate :char2_matches, :arel_predicate => :matches, :formatter => proc { |p| "__#{p}_______" }
Ransack.add_predicate :char3_matches, :arel_predicate => :matches, :formatter => proc { |p| "___#{p}______" }
Ransack.add_predicate :char4_matches, :arel_predicate => :matches, :formatter => proc { |p| "____#{p}_____" }
Ransack.add_predicate :char5_matches, :arel_predicate => :matches, :formatter => proc { |p| "_____#{p}____" }
Ransack.add_predicate :char6_matches, :arel_predicate => :matches, :formatter => proc { |p| "______#{p}___" }
Ransack.add_predicate :char7_matches, :arel_predicate => :matches, :formatter => proc { |p| "_______#{p}__" }
Ransack.add_predicate :char8_matches, :arel_predicate => :matches, :formatter => proc { |p| "________#{p}_" }
Ransack.add_predicate :char9_matches, :arel_predicate => :matches, :formatter => proc { |p| "_________#{p}" }
