#!/usr/bin/env ruby
#
# tagger.rb - PROIEL tagger
#
# Written by Marius L. Jøhndal, 2007, 2008.
#
# $Id: $
#
require 'proiel/morphtag'
require 'fastercsv'
require 'gdbm'

module PROIEL
  class Tagger
    # The weight given to a hand-written rule
    MANUAL_RULE_WEIGHT = 1.0

    # The weight given to a generated rule
    GENERATED_RULE_WEIGHT = 0.2

    # The weight given to a complete, existing tag
    EXISTING_TAG_WEIGHT = 1.0

    # The weight ratio for existing instances
    INSTANCE_WEIGHT_RATIO = 0.5

    # The weight ratio for contradictory, incomplete, existing tags
    CONTRADICTION_RATIO = 0.5

    attr_reader :logger
    attr_writer :logger
    attr_reader :statistics_retriever

    @@open_dbs = {}

    # Creates a new tagger.
    #
    # ==== Options
    # logger:: Specifies a logger object.
    #
    # statistics_retriever:: Specifies a function that returns the frequency of aleady tagged
    # forms, e.g. lambda { |language, form| [[ "C-", "cum", 30 ], [ "G-", "cum", 40 ]] }. All tags in the
    # returned data must be valid and complete.
    #
    # data_directory:: Specifies the directory in which to look for data files. The default
    # is the current directory. 
    def initialize(options = {})
      @logger = options[:logger]
      @statistics_retriever = options[:statistics_retriever]
      @data_directory = options[:data_directory] || '.'

      Tagger.update_databases(@data_directory, LANGUAGES.keys, @logger)
    end

    # Generates a list of tags for a token.
    #
    # Options:
    # ignore_instances:: Ignore any instance matches.
    def tag_token(language, form, sort, existing = nil, options = {})
      # Gather all the candidates first
      raw_candidates = []
      raw_candidates += get_manual_rule_matches(language, form).collect { |t| [t, MANUAL_RULE_WEIGHT, :manual_rule] }
      raw_candidates += get_generated_rule_matches(language, form).collect { |t| [t, GENERATED_RULE_WEIGHT, :generated] }
      raw_candidates += get_instance_matches(language, form).collect { |t, w| [t, w * INSTANCE_WEIGHT_RATIO, :recorded_instance] } unless options[:ignore_instances]

      if existing
        # We have some information already. Use this to partition the set
        # of candidates and give the subset that are compatible with the existing
        # information greater weight.

        # First try to do some ad hoc repairwork for our source tags.
        if existing.morphtag.pos_to_s == 'N-'
          existing.morphtag[:minor] = :b # probably a common noun 
        end

        if existing.morphtag[:major] == :A and existing.morphtag[:degree].to_s == '-'
          existing.morphtag[:degree] = :p # reasonably a positive
        end

        if existing.morphtag.complete?(language)
          # Add it as any other candidate unless it belongs to one of the
          # groups we manually craft rules for, in which case doing this
          # would poison the results. The same goes for stuff that does
          # not have any lemma set.
          if [:N, :V, :A].include?(existing.morphtag[:major]) and not existing.lemma.nil?
            raw_candidates << [existing, EXISTING_TAG_WEIGHT, :source]
            @logger.warn { "Tagger: Adding existing tag #{existing} as an alternative" }
          end
        else
          # At least use it to lower the score of others
          raw_candidates.collect! { |c, w, s| c.morphtag.contradiction?(existing.morphtag) || (existing.lemma and c.lemma != existing.lemma) ? [c, w * CONTRADICTION_RATIO, s] : [c, w, s] }

          @logger.warn { "Tagger: Failed to use existing tag as candidate due to its incompleteness: #{existing}" } if @logger
        end
      end

      if false
        # Filter out duplicates, leaving the highest scoring one only
        candidates = raw_candidates.inject({}) do |candidates, raw_candidate| 
          tag, weight, source = raw_candidate
          candidates[tag] = weight if not candidates[tag] or candidates[tag] < weight
          candidates
        end
      else
        # Filter out duplicates, accumulating scores 
        candidates = raw_candidates.inject({}) do |candidates, raw_candidate| 
          tag, weight, source = raw_candidate
          candidates[tag] ||= 0.0
          candidates[tag] += weight
          candidates
        end
      end

      # Try to pick the best match.
      ordered_candidates = candidates.sort_by { |c, w| w }.reverse

      # If the first candidate in the ordered list has the same as the next,
      # we're unable to decide, so pick none but return all as suggestions. Otherwise,
      # pick the first and return the remainder as suggestions. 
      if ordered_candidates.length > 1 and ordered_candidates[0][1] == ordered_candidates[1][1]
        [:ambiguous, nil] + ordered_candidates
      elsif ordered_candidates.length == 0
        [:failed, nil]
      else
        [ordered_candidates.tail.length == 0 ? :unambiguous : :ambiguous, 
          ordered_candidates.head.first] + ordered_candidates
      end
    end

    def access_rule_db(mode, language, form)
      db_name = "#{mode}-#{language}.db"
      unless @@open_dbs[db_name]
        file_name = File.join(@data_directory, db_name) 
        raise "Unable to open database #{file_name}" unless File.exists?(file_name)
        @@open_dbs[db_name] = GDBM::open(file_name, GDBM::READER)
      end
      db = @@open_dbs[db_name]
      value = db[form]
      values = value ? value.split(',') : []
      y = values.collect { |x| MorphLemmaTag.new(x) }

      # FIXME: the  READER/WRITER stuff doesn't work at all!
      db.close
      @@open_dbs.delete(db_name)

      y
    end

    def get_manual_rule_matches(language, form)
      access_rule_db(:manual, language, form)
    end

    def get_generated_rule_matches(language, form)
      access_rule_db(:generated, language, form)
    end

    def get_instance_matches(language, form)
      if @statistics_retriever
        instances = @statistics_retriever.call(language, form)

        # Filter out those that fail completeness testing (or validation) or
        # lack a lemma.
        instances.reject! { |tag, lemma, frequency| not MorphTag.new(tag).complete? or lemma.nil? }

        # Compute frequency
        sum = instances.inject(0) { |sum, instance| sum + instance[2] }
        instances.collect { |tag, lemma, frequency| [MorphLemmaTag.new("#{tag}:#{lemma}"), frequency / sum.to_f] }
      else
        []
      end
    end

    # Generate the complete tag space using any known tag and language as a constraint.
    # +limit+ ensures that the generated space will not exceed a certain number of
    # members and instead return nil.
    def generate_tag_space(language, known_tag, limit = 10)
      morphtags = MorphTag.new(known_tag).completions(language)
      morphtags.length > limit ? nil : morphtags 
    end

    public

    # Creates or updates any databases that need to be updated based on the modification 
    # time of the rule files.
    def self.update_databases(data_directory, languages, logger = nil)
      for mode in [:manual, :generated]
        data_file = File.join(data_directory, "#{mode}.csv")
        recreate = false

        logger.info { "Checking if #{data_file} has changed..." } if logger 

        # Find the earliest mtime for the databases
        db_mtime = Time.now
        languages.each do |language|
          db_file_name = File.join(data_directory, "#{mode}-#{language}.db")

          if File.exists?(db_file_name)
            mtime = File.mtime(db_file_name)
            db_mtime = mtime if mtime < db_mtime
          else
            recreate = true
            break
          end
        end

        rule_mtime = File.mtime(data_file)
        recreate = true if rule_mtime > db_mtime

        logger.info { "#{data_file} has changed..." } if logger and recreate

        Tagger.update_database(data_file, mode, data_directory, logger) if recreate
      end
    end

    # Creates or updates a rules database for the tagger.
    def self.update_database(data_file, mode, data_directory, logger = nil)
      dbs = {}

      FasterCSV.foreach(data_file, :skip_blanks => true) do |e|
        language, lemma, variant, form, *morphtags = e
        db_name = "#{mode}-#{language}.db"

        raise "Update aborted: Incomplete or invalid rules for #{form}." unless morphtags.select { |m| !MorphTag.new(m).complete? }.empty?

        unless dbs[db_name]
          logger.info { "Updating tagger database #{db_name} based on #{data_file} and mode #{mode}" } if logger

          # GDBM::NEWDB doesn't seem to really clear the old database properly.
          file_name = File.join(data_directory, db_name)
          File.unlink(file_name) if File.exists?(file_name)
          dbs[db_name] = GDBM::open(file_name, 0666)
        end
        d = dbs[db_name]

        base_form = variant ? "#{lemma}##{variant}" : lemma
        morphtags.collect! { |m| [MorphTag.new(m).to_s, base_form].join(':') }
        morphtags += d[form].split(',') if d[form]
        d[form] = morphtags.join(',')
      end

      dbs.values.each { |db| db.close }
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  include PROIEL

  class TaggerTestCase < Test::Unit::TestCase
    def test_unambiguous
      tagger = Tagger.new
      assert_equal [:unambiguous, MorphLemmaTag.new("C:et"), [MorphLemmaTag.new("C:et"), 1.0]], tagger.tag_token(:la, 'et', :word)
    end

    def test_previous_instance_influence
      # With this setup the G occurs more often than R in the data and
      # should be preferred
      tagger = Tagger.new(:statistics_retriever => lambda { |language, form| [[ "R----------", "cum", 20 ], [ "G----------", "cum", 80 ]] })
      assert_equal [:ambiguous, MorphLemmaTag.new("G:cum"), 
        [MorphLemmaTag.new("G:cum"), 1.4], 
        [MorphLemmaTag.new("R:cum"), 1.1],
        [MorphLemmaTag.new("Dq:cum"), 1.0]], tagger.tag_token(:la, 'cum', :word)

      # Then do it the other way around
      tagger = Tagger.new(:statistics_retriever => lambda { |language, form| [[ "R----------", "cum", 300 ], [ "G----------", "cum", 100 ]] })
      assert_equal [:ambiguous, MorphLemmaTag.new("R:cum"), 
        [MorphLemmaTag.new("R:cum"), 1.375], 
        [MorphLemmaTag.new("G:cum"), 1.125],
        [MorphLemmaTag.new("Dq:cum"), 1.0]], tagger.tag_token(:la, 'cum', :word)
    end

    def test_existing_tag_influence_complete_tag
      tagger = Tagger.new

      # Existing tag is complete
      assert_equal [:ambiguous, MorphLemmaTag.new("R:cum"), 
        [MorphLemmaTag.new("R:cum"), 2.0], 
        [MorphLemmaTag.new("Dq:cum"), 1.0],
        [MorphLemmaTag.new("G:cum"), 1.0],
      ], tagger.tag_token(:la, 'cum', :word, MorphLemmaTag.new('R:cum'))
      assert_equal [:ambiguous, MorphLemmaTag.new("G:cum"), 
        [MorphLemmaTag.new("G:cum"), 2.0], 
        [MorphLemmaTag.new("R:cum"), 1.0],
        [MorphLemmaTag.new("Dq:cum"), 1.0],
      ], tagger.tag_token(:la, 'cum', :word, MorphLemmaTag.new('G:cum'))
    end

    def test_existing_tag_influence_incomplete_tag
      tagger = Tagger.new

      # Existing tag is incomplete
      assert_equal [:ambiguous, MorphLemmaTag.new("Dn:ne"),
        [MorphLemmaTag.new("Dn:ne"), 1.0], 
        [MorphLemmaTag.new("I:ne"), 0.5], 
        [MorphLemmaTag.new("G:ne"), 0.5],
      ], tagger.tag_token(:la, 'ne', :word, MorphLemmaTag.new('D'))
    end

    def test_existing_tag_influence_complete_tag_but_contradictory_lemma
      tagger = Tagger.new

      # Existing tag is complete, but contradictory lemma 
      assert_equal [:ambiguous, nil,
        [MorphLemmaTag.new("I:ne"), 0.5], 
        [MorphLemmaTag.new("Dn:ne"), 0.5],
        [MorphLemmaTag.new("G:ne"), 0.5], 
      ], tagger.tag_token(:la, 'ne', :word, MorphLemmaTag.new('Df:neo'))
    end

    def test_draw
      tagger = Tagger.new
      assert_equal [:ambiguous, nil, 
        [MorphLemmaTag.new("R:cum"), 1.0],
        [MorphLemmaTag.new("Dq:cum"), 1.0],
        [MorphLemmaTag.new("G:cum"), 1.0],
      ], tagger.tag_token(:la, 'cum', :word)
    end

    def test_generated_lookup
      tagger = Tagger.new
      assert_equal [:ambiguous, nil, 
        [MorphLemmaTag.new("Ne-p---mn:Herodes"), 0.2],
        [MorphLemmaTag.new("Ne-s---mn:Herodes"), 0.2],
        [MorphLemmaTag.new("Ne-p---mv:Herodes"), 0.2],
        [MorphLemmaTag.new("Ne-p---ma:Herodes"), 0.2],
      ], tagger.tag_token(:la, 'Herodes', :word)
    end

    def test_failed_tagging
      tagger = Tagger.new
      assert_equal [:failed, nil], tagger.tag_token(:la, 'fjotleik', :word)
    end
  end
end
