class AddGeneralisedIndeclinableField < ActiveRecord::Migration
  MAP = [
    ['Ma----------n', 'Mg----------'],
    ['Nb----------n', 'Nh----------'],
    ['Ne----------n', 'Nj----------'],
    ['Df----------n', 'Dn----------'],
    ['Dq----------n', 'Dq----------'],
    ['Du----------n', 'Du----------'],
    ['R-----------n', 'R-----------'],
    ['C-----------n', 'C-----------'],
    ['G-----------n', 'G-----------'],
    ['F-----------n', 'F-----------'],
    ['I-----------n', 'I-----------'],
  ]

  POS_MAP = [
    ['Ma', 'Mg'],
    ['Nb', 'Nh'],
    ['Ne', 'Nj'],
    ['Df', 'Dn'],
  ]

  def self.up
    # morphtag field is wide enough already to accommodate this, so no
    # need to change schema
    MAP.each do |to, from|
      execute("UPDATE tokens SET morphtag = '#{to}' WHERE morphtag = '#{from}'")
      execute("UPDATE tokens SET source_morphtag = '#{to}' WHERE source_morphtag = '#{from}'")
      execute("UPDATE inflections SET morphtag = '#{to}' WHERE morphtag = '#{from}'")
    end
    execute("UPDATE tokens SET morphtag = concat(morphtag, 'i') WHERE length(morphtag) = 12")
    execute("UPDATE tokens SET source_morphtag = concat(source_morphtag, 'i') WHERE length(source_morphtag) = 12")
    execute("UPDATE inflections SET morphtag = concat(morphtag, 'i') WHERE length(morphtag) = 12")
    POS_MAP.each do |to, from|
      execute("UPDATE lemmata SET pos = '#{to}' WHERE pos = '#{from}'")
    end
  end

  def self.down
    MAP.each do |from, to|
      execute("UPDATE tokens SET morphtag = '#{to}' WHERE morphtag = '#{from}'")
      execute("UPDATE tokens SET source_morphtag = '#{to}' WHERE source_morphtag = '#{from}'")
      execute("UPDATE inflections SET morphtag = '#{to}' WHERE morphtag = '#{from}'")
    end
    execute("UPDATE tokens SET morphtag = substr(morphtag, 1, 12)")
    execute("UPDATE tokens SET source_morphtag = substr(source_morphtag, 1, 12)")
    execute("UPDATE inflections SET morphtag = substr(morphtag, 1, 12)")
    POS_MAP.each do |from, to|
      execute("UPDATE lemmata SET pos = '#{to}' WHERE pos = '#{from}'")
    end
  end
end
