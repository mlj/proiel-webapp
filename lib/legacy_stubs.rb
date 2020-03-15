#--
#
# Copyright 2007-2016 University of Oslo
# Copyright 2007-2020 Marius L. Jøhndal
# Copyright 2010-2012 Dag Haug
#
# This file is part of the PROIEL web application.
#
# The PROIEL web application is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.
#
# The PROIEL web application is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the PROIEL web application.  If not, see
# <http://www.gnu.org/licenses/>.
#
#++

# TODO: move to proiel library
#
SUPPORTED_LANGUAGES = {
  "por" => "Portuguese",
  "spa" => "Spanish",

  # Derived using
  # https://github.com/cltk/cltkv1/blob/master/scripts/make_glottolog_languages.py,
  # which downloads language codes from Glottolog and the official ISO-639-3
  # tables and picks the ones that are marked 'historical' or 'ancient'.

  'akk' => 'Akkadian',
  'ang' => 'Old English (ca. 450-1100)',
  'arb' => 'Standard Arabic',
  'arc' => 'Official Aramaic (700-300 BCE)',
  'ave' => 'Avestan',
  'axm' => 'Middle Armenian',
  'chu' => 'Church Slavic',
  'cmg' => 'Classical Mongolian',
  'cms' => 'Messapic',
  'cnx' => 'Middle Cornish',
  'dum' => 'Middle Dutch',
  'ecr' => 'Eteocretan',
  'ecy' => 'Eteocypriot',
  'egy' => 'Egyptian (Ancient)',
  'elx' => 'Elamite',
  'emy' => 'Epigraphic Mayan',
  'enm' => 'Middle English',
  'ett' => 'Etruscan',
  'frk' => 'Old Frankish',
  'frm' => 'Middle French',
  'fro' => 'Old French (842-ca. 1400)',
  'gez' => 'Geez',
  'ghc' => 'Hiberno-Scottish Gaelic',
  'gmh' => 'Middle High German',
  'gml' => 'Middle Low German',
  'gmy' => 'Mycenaean Greek',
  'goh' => 'Old High German (ca. 750-1050)',
  'got' => 'Gothic',
  'grc' => 'Ancient Greek',
  'hbo' => 'Ancient Hebrew',
  'hit' => 'Hittite',
  'hlu' => 'Hieroglyphic Luwian',
  'hmk' => 'Maek',
  'htx' => 'Middle Hittite',
  'ims' => 'Marsian',
  'imy' => 'Milyan',
  'inm' => 'Minaean',
  'jpa' => 'Palestinian Jewish Aramaic',
  'jut' => 'Jutish',
  'kaw' => 'Kawi',
  'kho' => 'Khotanese',
  'kjv' => 'Kajkavian',
  'lab' => 'Linear A',
  'lat' => 'Latin',
  'lng' => 'Langobardic',
  'ltc' => 'Middle Chinese',
  'lzh' => 'Literary Chinese',
  'mga' => 'Middle Irish (10-12th century)',
  'mxi' => 'Mozarabic',
  'myz' => 'Classical Mandaic',
  'nci' => 'Classical Nahuatl',
  'ndf' => 'Nadruvian',
  'nei' => 'Neo-Hittite',
  'non' => 'Old Norse',
  'nrc' => 'Noric',
  'nrp' => 'North Picene',
  'nwc' => 'Classical Newari',
  'nwx' => 'Middle Newar',
  'nxm' => 'Numidian',
  'oar' => 'Old Aramaic (up to 700 BCE)',
  'oav' => 'Old Avar',
  'obm' => 'Moabite',
  'obr' => 'Old Burmese',
  'obt' => 'Old Breton',
  'och' => 'Old Chinese',
  'oco' => 'Old Cornish',
  'odt' => 'Old Dutch-Old Frankish',
  'ofs' => 'Old Frisian',
  'oge' => 'Old Georgian',
  'oht' => 'Old Hittite',
  'ohu' => 'Old Hungarian',
  'ojp' => 'Old Japanese',
  'okm' => 'Middle Korean (10th-16th cent.)',
  'oko' => 'Old Korean (3rd-9th cent.)',
  'olt' => 'Old Lithuanian',
  'omn' => 'Minoan',
  'omp' => 'Old Manipuri',
  'omr' => 'Old Marathi',
  'omx' => 'Old Mon',
  'onw' => 'Old Nubian',
  'oos' => 'Old Ossetic',
  'orv' => 'Old Russian',
  'osc' => 'Oscan',
  'osp' => 'Old Spanish',
  'osx' => 'Old Saxon',
  'ota' => 'Ottoman Turkish (1500-1928)',
  'otb' => 'Old Tibetan',
  'otk' => 'Old Turkish',
  'oty' => 'Old Tamil',
  'oui' => 'Old Turkic',
  'owl' => 'Old-Middle Welsh',
  'pal' => 'Pahlavi',
  'peo' => 'Old Persian (ca. 600-400 B.C.)',
  'pgd' => 'Gāndhārī',
  'pgl' => 'Primitive Irish',
  'pgn' => 'Paelignian',
  'phn' => 'Phoenician',
  'pka' => 'Ardhamāgadhī Prākrit',
  'pkc' => 'Paekche',
  'pli' => 'Pali',
  'plq' => 'Palaic',
  'pmh' => 'Maharastri Prakrit',
  'pro' => 'Old Provençal',
  'psu' => 'Sauraseni Prakrit',
  'pyx' => 'Burma Pyu',
  'qwc' => 'Classical Quechua',
  'san' => 'Sanskrit',
  'sbv' => 'Sabine',
  'scx' => 'Sicula',
  'sga' => 'Early Irish',
  'sog' => 'Sogdian',
  'spx' => 'South Picene',
  'sqr' => 'Siculo Arabic',
  'sux' => 'Sumerian',
  'svx' => 'Skalvian',
  'sxc' => 'Sicana',
  'sxo' => 'Sorothaptic',
  'syc' => 'Classical Syriac',
  'txb' => 'Tokharian B',
  'txg' => 'Tangut',
  'txh' => 'Thracian',
  'txr' => 'Tartessian',
  'uga' => 'Ugaritic',
  'umc' => 'Marrucinian',
  'wlm' => 'Middle Welsh',
  'xaa' => 'Andalusian Arabic',
  'xae' => 'Aequian',
  'xag' => 'Aghwan',
  'xaq' => 'Aquitanian',
  'xbc' => 'Bactrian',
  'xbm' => 'Middle Breton',
  'xbo' => 'Bolgarian',
  'xcb' => 'Cumbric',
  'xcc' => 'Camunic',
  'xce' => 'Celtiberian',
  'xcg' => 'Cisalpine Gaulish',
  'xcl' => 'Classical Armenian',
  'xco' => 'Khwarezmian',
  'xcr' => 'Carian',
  'xct' => 'Classical Tibetan',
  'xcu' => 'Curonian',
  'xdc' => 'Dacian',
  'xdm' => 'Edomite',
  'xeb' => 'Eblaite',
  'xep' => 'Epi-Olmec',
  'xfa' => 'Faliscan',
  'xga' => 'Galatian',
  'xgl' => 'Galindan',
  'xha' => 'Harami',
  'xhc' => 'Hunnic',
  'xhd' => 'Hadrami',
  'xhr' => 'Hernican',
  'xht' => 'Hattic',
  'xhu' => 'Hurrian',
  'xib' => 'Iberian',
  'xil' => 'Illyrian',
  'xiv' => 'Harappan',
  'xlc' => 'Lycian A',
  'xld' => 'Lydian',
  'xle' => 'Lemnian',
  'xlg' => 'Ancient Ligurian',
  'xli' => 'Liburnian',
  'xln' => 'Alanic',
  'xlp' => 'Lepontic',
  'xls' => 'Lusitanian',
  'xlu' => 'Cuneiform Luwian',
  'xly' => 'Elymian',
  'xme' => 'Median',
  'xmk' => 'Ancient Macedonian',
  'xmn' => 'Manichaean Middle Persian',
  'xmr' => 'Meroitic',
  'xna' => 'Ancient North Arabian',
  'xng' => 'Middle Mongol',
  'xno' => 'Anglo-Norman',
  'xpc' => 'Pecheneg',
  'xpg' => 'Phrygian',
  'xpi' => 'Pictish',
  'xpp' => 'Puyo-Paekche',
  'xpr' => 'Parthian',
  'xps' => 'Pisidian',
  'xpu' => 'Punic',
  'xpy' => 'Puyo',
  'xqa' => 'Karakhanid',
  'xqt' => 'Qatabanian',
  'xrm' => 'Armazic',
  'xrr' => 'Raetic',
  'xsa' => 'Sabaic',
  'xsc' => 'Scythian',
  'xsd' => 'Sidetic',
  'xtg' => 'Transalpine Gaulish',
  'xto' => 'Tokharian A',
  'xtq' => 'Tumshuqese',
  'xtr' => 'Early Tripuri',
  'xum' => 'Umbrian',
  'xur' => 'Urartian',
  'xve' => 'Venetic',
  'xvn' => 'Vandalic',
  'xvo' => 'Volscian',
  'xvs' => 'Vestinian',
  'xzh' => 'Zhangzhung',
  'xzp' => 'Ancient Zapotec',
  'yms' => 'Mysian',
  'zkg' => 'Koguryo',
  'zkh' => 'Khorezmian',
  'zkt' => 'Kitan',
  'zkz' => 'Khazar',
  'zra' => 'Kara (Korea)',
  'zsk' => 'Kaskean',
}

ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular "lemma", "lemmata"
  inflect.irregular "part_of_speech", "parts_of_speech"
end

class InformationStatusTag < TagObject
  model_file_name 'information_status.yml'
end

class PartOfSpeechTag < TagObject
  model_file_name 'part_of_speech.yml'
end

class StatusTag < TagObject
  model_file_name 'status.yml'
end

class RelationTag < TagObject
  model_file_name 'relation.yml'
end

class LanguageTag < TagObject
  class LanguageTagProxyObject
    def has_key?(tag)
      SUPPORTED_LANGUAGES.key?(tag)
    end

  #  def keys
  #    SUPPORTED_LANGUAGES.keys
  #  end

    def [](tag)
      SUPPORTED_LANGUAGES[tag]
    end

#    def to_hash
#      SUPPORTED_LANGUAGES
#    end
  end

  model_generator LanguageTagProxyObject.new

  alias :language :tag

  def errors
    ActiveModel::Errors.new(self)
  end

  #def lemmata
  #  Lemma.where(:language_tag => tag).order('lemma ASC')
  #end
end

class SemanticRelationTag < ActiveRecord::Base
  belongs_to :semantic_relation_type
  has_many :semantic_relations
end

class SemanticRelationType < ActiveRecord::Base
  has_many :semantic_relation_tags
end

class DependencyAlignmentTerm < ActiveRecord::Base
  belongs_to :token
  belongs_to :source
end

class ImportSource < ActiveRecord::Base
  has_many :notes, as: :notable
end

class Note < ActiveRecord::Base
  belongs_to :originator, polymorphic: true
  belongs_to :notable, polymorphic: true
end

class SemanticAttributeValue < ActiveRecord::Base
  belongs_to :semantic_attribute
  has_many :semantic_tags
end

class SemanticAttribute < ActiveRecord::Base
  has_many :semantic_attribute_values
end

class SemanticRelation < ActiveRecord::Base
  belongs_to :controller, :class_name => 'Token', :foreign_key => 'controller_id'
  belongs_to :target, :class_name => 'Token', :foreign_key => 'target_id'
  belongs_to :semantic_relation_tag

  validate do
    errors[:base] << "Controller and target must be in the same source division" unless controller.sentence.source_division == target.sentence.source_division
  end

  delegate :semantic_relation_type, :to => :semantic_relation_tag
end

class Inflection < ActiveRecord::Base
  #attr_accessible :lemma, :form, :language_tag, :morphology_tag, :part_of_speech_tag
  tag_attribute :language, :language_tag, LanguageTag, :allow_nil => false

  composed_of :morphology, :mapping => %w(morphology_tag to_s), :allow_nil => true, :converter => Proc.new { |x| Morphology.new(x) }

  # Returns the morphological features. These will never be nil.
# def morph_features
#   MorphFeatures.new([lemma, part_of_speech_tag, language.tag].join(','), morphology.tag)
# end
end

class Lemma < ActiveRecord::Base
  blankable_attributes :foreign_ids, :gloss

  has_many :tokens
  has_many :notes, :as => :notable, :dependent => :destroy
  has_many :semantic_tags, :as => :taggable, :dependent => :destroy

  tag_attribute :language, :language_tag, LanguageTag, :allow_nil => false
  tag_attribute :part_of_speech, :part_of_speech_tag, PartOfSpeechTag, :allow_nil => false

  validates_numericality_of :variant, allow_nil: true

  # Returns the export-form of the lemma.
  def export_form
    self.variant ? "#{self.lemma}##{self.variant}" : self.lemma
  end

# def morph_features
#   MorphFeatures.new(self, nil)
# end
#
# def to_s
#   [export_form, part_of_speech.to_s].join(',')
# end
#
# def language_name
#   LanguageTag.new(language_tag).try(:name)
# end
end

class SemanticTag < ActiveRecord::Base
  belongs_to :semantic_attribute_value
  belongs_to :taggable, polymorphic: true

  def semantic_attribute
    semantic_attribute_value.semantic_attribute
  end
end

class Sentence < ActiveRecord::Base
  blankable_attributes :annotated_at, :annotated_by, :assigned_to,
    :automatic_alignment, :presentation_after, :presentation_before,
    :reviewed_at, :reviewed_by, :sentence_alignment_id

  belongs_to :annotator, :class_name => 'User', :foreign_key => 'annotated_by'
  belongs_to :assignee, :class_name => 'User', :foreign_key => 'assigned_to'
  belongs_to :reviewer, :class_name => 'User', :foreign_key => 'reviewed_by'
  belongs_to :sentence_alignment, :class_name => 'Sentence', :foreign_key => 'sentence_alignment_id'
  belongs_to :source_division
  has_many :notes, :as => :notable, :dependent => :destroy
  has_many :semantic_tags, :as => :taggable, :dependent => :destroy
  has_many :tokens, :dependent => :destroy
  tag_attribute :status, :status_tag, StatusTag, :allow_nil => false
  delegate :language, :to => :source_division
  delegate :language_tag, to: :source_division
  delegate :source_citation_part, to: :source_division
  validates_with Proiel::SentenceAnnotationValidator

  # All tokens with dependents and information structure included
  def tokens_with_deps_and_is
    ts = tokens.includes(:dependents, :antecedent, :lemma, :slash_out_edges)
    prodrops, others = ts.partition { |token| token.empty_token_sort == 'P' }

    prodrops.each do |prodrop|
      head, head_index = others.each_with_index do |token, index|
        break [token, index] if token.id == prodrop.head_id
      end
      raise "No head found for prodrop element with ID #{prodrop.id}!" unless head

      relation = prodrop.relation.tag.to_s
      insertion_point = case relation
                        when 'sub'
                          # Position subjects before the verb
                          head_index

                        when 'obl'
                          if others[head_index + 1] && others[head_index + 1].relation &&
                                                    others[head_index + 1].relation.tag == 'obj'
                            # Position obliques after the object, if any,...
                            head_index + 2
                          else
                            # ...or otherwise after the verb
                            head_index + 1
                          end

                        when 'obj'
                          # Position objects after the verb
                          head_index + 1

                        else
                          raise "Unknown relation: #{relation}!"
                        end

      others.insert(insertion_point, prodrop)
    end

    others
  end

# # A sentence that has not been annotated.
# def self.unannotated
#   where(:status_tag => 'unannotated')
# end
#
# # A sentence that has been annotated.
# def self.annotated
#   where(:status_tag => ['annotated', 'reviewed'])
# end
#
# # A sentence that has not been reviewed.
# def self.unreviewed
#   where(:status_tag => ['annotated', 'unannotated'])
# end
#
# # A sentence that has been reviewed.
# def self.reviewed
#   where(:status_tag => 'reviewed')
# end

# # Returns the parent object for the sentence, which will be its
# # source division.
# def parent
#   source_division
# end
#
# # Returns the maximum token number in the sentence.
# def max_token_number
#   self.tokens.maximum(:token_number)
# end
#
# # Returns the minimum token number in the sentence.
# def min_token_number
#   self.tokens.minimum(:token_number)
# end
#
# # Creates a new token and appends it to the end of the sentence. The
# # function is equivalent to +create!+ except for the automatic
# # positioning of the new token in the sentence's linearization
# # sequence.
# def append_new_token!(attrs = {})
#   tokens.create!(attrs.merge({ :token_number => max_token_number + 1 }))
# end
#
  # Returns true if sentence has been annotated.
  def is_annotated?
    status_tag == 'annotated' or status_tag == 'reviewed'
  end

  # Returns true if sentence has been reviewed.
  def is_reviewed?
    status_tag == 'reviewed'
  end
#
# # Returns the dependency graph for the sentence.
# def dependency_graph
#   Proiel::DependencyGraph.new do |g|
#     tokens.takes_syntax.each { |t| g.badd_node(t.id, t.relation_tag, t.head ? t.head.id : nil,
#                                                          Hash[*t.slash_out_edges.map { |se| [se.slashee.id, se.relation_tag ] }.flatten],
#                                                          { :empty => t.empty_token_sort || false,
#                                                            :token_number => t.token_number,
#                                                            :morph_features => t.morph_features,
#                                                            :form => t.form }) }
#   end
# end
#
# # Returns +true+ if sentence has dependency annotation.
 def has_dependency_annotation?
   tokens.takes_syntax.first && !tokens.takes_syntax.first.relation.nil?
 end
#
# def to_s(options = {})
#   tokens_text = tokens.visible.map { |t| t.to_s(options) }.join
#   [presentation_before, tokens_text, presentation_after].compact.join
# end
#
# # Returns the alignment source if any descendant object is aligned to an object in another source.
# #
# # This does not verify that all descendants with alignments actually refer to the
# # same source.
  def inferred_aligned_source
    if sentence_alignment_id.nil?
      tokens.each do |t|
        i = t.inferred_aligned_source
        return i unless i.nil?
      end
 
      nil
    else
      sentence_alignment.source
    end
  end
end
# Slash edges are directed, labelled edges in the dependency
# graph. They are intended to be used as indicators of various forms
# of coindexing. The `slasher' is generally the element that has a `gap',
# and the `slashee' is the element that would fill the `gap'.
class SlashEdge < ActiveRecord::Base
  belongs_to :slasher, :class_name => 'Token', :foreign_key => 'slasher_id'
  belongs_to :slashee, :class_name => 'Token', :foreign_key => 'slashee_id'
  tag_attribute :relation, :relation_tag, RelationTag, :allow_nil => false
end

class SourceDivision < ActiveRecord::Base
  blankable_attributes :aligned_source_division_id, :presentation_after, :presentation_before, :title
  belongs_to :aligned_source_division, :class_name => "SourceDivision"
  belongs_to :source
  delegate :citation_part, to: :source, prefix: :source
  delegate :language, :to => :source
  delegate :language_tag, :to => :source
  has_many :sentences
  has_many :tokens, :through => :sentences

# # Returns the parent object for the source division, which will be its
# # source.
# def parent
#   source
# end
#
#
 # Returns the alignment source if any descendant object is aligned to an object in another source.
 #
 # This does not verify that all descendants with alignments actually refer to the
 # same source.
 def inferred_aligned_source
   if aligned_source_division_id.nil?
     sentences.each do |s|
       i = s.inferred_aligned_source
       return i unless i.nil?
     end

     nil
   else
     aligned_source_division.source
   end
 end
end

class Source < ActiveRecord::Base
  blankable_attributes :author
  has_many :dependency_alignment_terminations
  has_many :sentences, through: :source_divisions
  has_many :source_divisions
  store :additional_metadata, accessors: Proiel::Metadata.fields
  tag_attribute :language, :language_tag, LanguageTag, :allow_nil => false

  # Returns a citation for the source.
# def citation
#   citation_part
# end
#
# def to_label
#   title
# end
#
# # Returns the name of the language of the source.
# def language_name
#   language.name
# end

# Returns a generated metadata field containing the names of all annotators
# and the number of sentences each has annotated.
def annotator
  Sentence.
    includes(:source_division, :annotator).
    where("source_divisions.source_id" => self).
    where("annotated_by IS NOT NULL").
    group(:annotator).
    count.
    sort_by { |u, n| -n }.
    map { |u, n| [u.full_name, "#{n} sentence".pluralize(n)] }.
    map { |u, n| "#{u} (#{n})" }.
    to_sentence
end

# Returns a generated metadata field containing the names of all reviewers
# and the number of sentences each has reviewed.
def reviewer
  Sentence.
    includes(:source_division, :reviewer).
    where("source_divisions.source_id" => self).
    where("reviewed_by IS NOT NULL").
    group(:reviewer).
    count.
    sort_by { |u, n| -n }.
    map { |u, n| [u.full_name, "#{n} sentence".pluralize(n)] }.
    map { |u, n| "#{u} (#{n})" }.
    to_sentence
end
#
# # Generates a human-readable ID for the source.
# def human_readable_id
#   code
# end
#
# # Move all source divisions from +other_source_ to this source. If +position+
# # is +:append+, the source divisions from +other_source+ will be placed after
# # existing ones in this source. If +position+ is +:preprend:, they will be
# # placed before them.
# def merge_with_source!(other_source, position = :append)
#   Source.transaction do
#     case position
#     when :append
#       reassign_source_divisions!(other_source, source_divisions.maximum(:position) + 1)
#     when :prepend
#       #self.tokens.sort { |x, y| y.token_number <=> x.token_number }.each do |t|
#       position_base = other_source.source_divisions.count
#
#       self.source_divisions.order('position DESC').each do |sd|
#         sd.update_attributes! :position => sd.position + position_base
#       end
#
#       reassign_source_divisions!(other_source)
#     else
#       raise ArgumentError, 'invalid position' unless position == :append or position == :prepend
#     end
#   end
#
#   other_source.reload
#   self.reload
# end
#
  # Returns the alignment source if any descendant object is aligned to an object in another source.
  #
  # This does not verify that all descendants with alignments actually refer to the
  # same source.
  def inferred_aligned_source
    source_divisions.each do |sd|
      i = sd.inferred_aligned_source
      return i unless i.nil?
    end
 
    nil
  end
#
# private
#
# def reassign_source_divisions!(other_source, position_base = 0)
#   Source.transaction do
#     other_source.source_divisions.order(:position).each_with_index do |sd, i|
#       sd.update_attributes! :position => i + position_base, :source_id => self.id
#     end
#   end
# end
end

class Token < ActiveRecord::Base
  blankable_attributes :antecedent_id, :automatic_token_alignment,
    :contrast_group, :dependency_alignment_id, :empty_token_sort, :foreign_ids,
    :form, :head_id, :information_status_tag, :lemma_id, :morphology_tag,
    :presentation_after, :presentation_before, :relation_tag, :source_lemma,
    :source_morphology_tag, :token_alignment_id

  belongs_to :antecedent, :class_name => 'Token', :foreign_key => 'antecedent_id'
  belongs_to :dependency_alignment, :class_name => 'Token', :foreign_key => 'dependency_alignment_id'
  belongs_to :head, :class_name => 'Token'
  belongs_to :lemma
  belongs_to :sentence
  belongs_to :token_alignment, :class_name => 'Token', :foreign_key => 'token_alignment_id'
  composed_of :morphology, :mapping => %w(morphology_tag to_s), :allow_nil => true, :converter => Proc.new { |x| Morphology.new(x) }
  delegate :language, :to => :sentence
  delegate :language_tag, :to => :sentence
  delegate :part_of_speech, :to => :lemma, :allow_nil => true
  delegate :part_of_speech_tag, :to => :lemma, :allow_nil => true
  delegate :source_citation_part, to: :sentence
  has_many :anaphors, :class_name => 'Token', :foreign_key => 'antecedent_id', :dependent => :nullify
  has_many :dependency_alignment_terminations, class_name: 'DependencyAlignmentTerm'
  has_many :dependents, :class_name => 'Token', :foreign_key => 'head_id'
  has_many :incoming_semantic_relations, :class_name => 'SemanticRelation', :foreign_key => 'target_id', :dependent => :destroy
  has_many :notes, :as => :notable, :dependent => :destroy
  has_many :outgoing_semantic_relations, :class_name => 'SemanticRelation', :foreign_key => 'controller_id', :dependent => :destroy
  has_many :semantic_tags, :as => :taggable, :dependent => :destroy
  has_many :slash_in_edges, :class_name => 'SlashEdge', :foreign_key => 'slashee_id', :dependent => :destroy
  has_many :slash_out_edges, :class_name => 'SlashEdge', :foreign_key => 'slasher_id', :dependent => :destroy
  has_many :slashees, :through => :slash_out_edges
  has_many :slashers, :through => :slash_in_edges
  tag_attribute :information_status, :information_status_tag, InformationStatusTag, :allow_nil => true
  tag_attribute :relation, :relation_tag, RelationTag, :allow_nil => true
#  validates_tag_set_inclusion_of :morphology_tag, MorphologyTag, :allow_nil => true
#  validates_tag_set_inclusion_of :source_morphology_tag, MorphologyTag, :allow_nil => true, :message => "%{value} is not a valid source morphology tag"

  # A token with +citation_part+ set.
  def self.with_citation
    where("citation_part IS NOT NULL AND citation_part != ''")
  end

  # A visible token, i.e. is a non-empty token.
  def self.visible
    where(:empty_token_sort => nil)
  end

  # An invisible token, i.e. an empty token.
  def self.invisible
    where("empty_token_sort IS NOT NULL")
  end

  # A token that can be annotated with syntax (i.e. dependency relations).
  def self.takes_syntax
    where("empty_token_sort IS NULL OR empty_token_sort != 'P'")
  end

  # A token belonging to a sentence that has not been annotated.
  def self.unannotated
    joins(:sentence).where(:sentences => { :status_tag => 'unannotated' })
  end

  # A token belonging to a sentence that has been annotated.
  def self.annotated
    joins(:sentence).where(:sentences => { :status_tag => ['annotated', 'reviewed'] })
  end

  # A token belonging to a sentence that has not been reviewed.
  def self.unreviewed
    joins(:sentence).where(:sentences => { :status_tag => ['annotated', 'unannotated'] })
  end

  # A token belonging to a sentence that has been reviewed.
  def self.reviewed
    joins(:sentence).where(:sentences => { :status_tag => 'reviewed' })
  end

  # Returns the morphological features for the token or +nil+ if none
  # are set.
  def morph_features
    # We can rely on the invariant !lemma.blank? <=>
    # !morphology.blank?
    if lemma
      MorphFeatures.new(lemma, morphology)
    else
      nil
    end
  end

  # Sets the morphological features for the token. Executes a +save!+
  # on the token object, which will result in validation of all token
  # attributes. Will also create a new Lemma object if necessary.
  # Returns the morphological features. It is guaranteed that no
  # updating will take place if the morph-features are unchanged.
  def morph_features=(f)
    Token.transaction do
      if f.nil?
        self.morphology = nil
        self.lemma = nil
        self.save!
      elsif f.is_a?(String)
        s1, s2, s3, s4 = f.split(',')
        self.morph_features = MorphFeatures.new([s1, s2, s3].join(','), s4)
      elsif self.morphology != f.morphology or f.lemma.new_record? or f.lemma != self.lemma
        self.morphology = f.morphology
        f.lemma.save! if f.lemma.new_record?
        self.lemma = f.lemma
        self.save!
      end
    end

    f
  end

  # Returns the source morphological features for the token or nil if
  # none are set.
  def source_morph_features
    # Source morph-features may be incomplete, so if any of the
    # relevant fields are set we should return an object. We will have
    # to pass along the language, as the +source_lemma+ attribute is a
    # serialized lemma specification without language code.
    if source_lemma or source_morphology_tag
      MorphFeatures.new([source_lemma, language.tag].join(','), source_morphology_tag)
    else
      nil
    end
  end

  # Sets the source morphological features for the token. Executes a
  # +save!+ on the token object, which will result in validation of
  # all token attributes.  Returns the morphological features. It is
  # guaranteed that no updating will take place if the morph-features
  # are unchanged.
  def source_morph_features=(f)
    Token.transaction do
      if f.nil?
        self.source_morphology_tag = nil
        self.source_lemma = nil
        self.save!
      elsif f.is_a?(String)
        s1, s2, s3, s4 = f.split(',')
        self.source_morph_features = MorphFeatures.new([s1, s2, s3].join(','), s4)
      elsif self.source_morphology_tag != f.morphology or f.lemma_s != self.source_lemma
        self.source_morphology_tag = f.morphology
        self.source_lemma = f.lemma_s
        self.save!
      end
    end
  end

  MorphFeatures::POS_PREDICATES.keys.each do |k|
    next if k == :verb? or k == :conjunction?
    delegate k, :to => :morph_features, :allow_nil => true
  end

  MorphFeatures::MORPHOLOGY_POSITIONAL_TAG_SEQUENCE.each do |k|
    delegate k, :to => :morph_features, :allow_nil => true
  end

  # Returns true if the token is a verb. If +include_empty_tokens+ is
  # true, also returns true for an empty node with its empty token
  # sort set to verb.
  def verb?(include_empty_tokens = true)
    (include_empty_tokens && empty_token_sort == 'V') || (morph_features and morph_features.verb?)
  end

  # Returns +true+ if the token is a conjunction. If +include_empty_tokens+
  # is true, also returns +true+ for an empty node with its empty token
  # sort set to conjunction, i.e. for asyndetic conjunctions.
  def conjunction?(include_empty_tokens = true)
    (include_empty_tokens && empty_token_sort == 'C') || (morph_features and morph_features.conjunction?)
  end

  def parent
    sentence
  end

  # Returns true if this is an empty token, i.e. a token used for empty nodes
  # in dependency structures.
  def is_empty?
    !empty_token_sort.nil?
  end

  # Returns true if this token is visible.
  def is_visible?
    empty_token_sort.nil?
  end

  alias :is_morphtaggable? :is_visible? # deprecated

  # Returns the dependency subgraph for the token as an unordered list.
  def subgraph_set
    [self] + dependents.map(&:subgraph_set).flatten
  end

  # Returns the dependency alignment subgraph for the token as an unordered
  # list.
  def dependency_alignment_subgraph_set(aligned_source)
    unless is_dependency_alignment_terminator?(aligned_source)
      [self] + dependents.map { |d| d.dependency_alignment_subgraph_set(aligned_source) }.flatten
    else
      []
    end
  end

  # Returns true if token is a terminator in dependency alignment.
  def is_dependency_alignment_terminator?(aligned_source)
    not dependency_alignment_terminations.count(:conditions => { :source_id => aligned_source.id }).zero?
  end

  def to_s(options = {})
    token_text = if [*options[:highlight_tokens]].include?(self.id)
                   "*#{form}*"
                 else
                   form
                 end

    [presentation_before, token_text, presentation_after].compact.join
  end

  # Returns the depth of the node, i.e. the distance from the root in number of edges.
  def depth
    if head
      head.depth + 1
    else
      0
    end
  end

  # Find ancestor among the primary relations of the dependency graph.
  def find_dependency_ancestor(&block)
    if head
      if block.call(head)
        head
      else
        head.find_dependency_ancestor(&block)
      end
    else
      nil
    end
  end

  # Iterate ancestors among the primary relations of the dependency graph.
  def each_dependency_ancestor(&block)
    if head
      block.call
      head.each_dependency_ancestor(&block)
    end
  end

  def find_semantic_relation_head(srt)
    if has_outgoing_relation_type?(srt)
      self
    elsif head
      head.find_semantic_relation_head(srt)
    else
      nil
    end
  end

  protected

  def sr_span(srt)
    ([self] + dependents.reject do |d|
       d.is_empty? or d.has_relation_type?(srt)
     end.map do |dd|
       dd.sr_span(srt)
     end).flatten
  end

  public

  def has_relation_type?(srt)
    has_incoming_relation_type?(srt) or has_outgoing_relation_type?(srt)
  end

  def has_incoming_relation_type?(srt)
    incoming_semantic_relations.any? { |sr| sr.semantic_relation_type == srt }
  end

  def has_outgoing_relation_type?(srt)
    outgoing_semantic_relations.any? { |sr| sr.semantic_relation_type == srt }
  end

  delegate :is_reviewed?, to: :sentence
  delegate :is_annotated?, :to => :sentence
  delegate :status, :to => :sentence
  delegate :status_tag, :to => :sentence

  # Returns the alignment source if any descendant object is aligned to an object in another source.
  #
  # This does not verify that all descendants with alignments actually refer to the
  # same source.
  def inferred_aligned_source
    if token_alignment_id.nil?
      nil
    else
      token_alignment.sentence.source_division.source
    end
  end

  def slashes
    slash_out_edges.map { |s| { relation_tag: s.relation_tag, target_id: s.slashee_id } }
  end
end

class User < ActiveRecord::Base
  has_many :assigned_sentences, :class_name => 'Sentence', :foreign_key => 'assigned_to'
  has_many :audits, :class_name => 'Audited::Audit'
  has_many :notes, :as => :originator
  store :preferences, accessors: [:graph_method]

  # Returns the user's full name.
  def full_name
    "#{first_name} #{last_name}"
  end
end
