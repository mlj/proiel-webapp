#!/usr/bin/env ruby
#
# gale_church.rb - PROIEL source boundary detection: Gale-Church alignment method
#
# Written by Marius L. Jøhndal, 2008.
#
require 'minimal_range_set'
require 'logos'

module PROIEL
  module SentenceBoundaries
    # Runs the Gale-Church alignment algorithm on the two sources +a+ and +b+
    # and deduces (hopefully) sensible sentence divisions by transferring
    # sentence divisions from +a+ to the corresponding locations in +b+. For
    # success, this assumes that both +a+ and +b+ contain punctuation, 
    # that this punctuation mostly occurs in the same places in +a+ and +b+,
    # and that the two sources contain approximately the same number of words.
    #
    # It is assumed that each source contains a number of chapters from
    # *one* book, i.e. the chapter numbers do not repreat. Chapter numbers 
    # are further assumed to be stable across the sources, but there does 
    # not have to be the same number of chapters in each source.
    #
    # For additional precision, the algorithm may use collocated verse 
    # boundaries and punctuation marks as additional synchronisation points.
    # This assumes that verse numbering is stable across the
    # sources. This behaviour also prevents the comparison from being
    # thrown off if source A has significant lacunae.
    #
    # ==== Options
    # no_verse_synchronisation:: Disable verse-level synchronisation.
    def self.gale_church(a, b, writer, options = {})
      # Build the regions: Each chapter boundary should be a hard delimiter,
      # each punctuation in our list of delimiting punctuation symbols a
      # soft delimiter. Start by dividing the text into chapters, then iterate
      # the chapters to see if they match up.
      current_chapter = nil
      regions_a = extract_chapters(a)
      regions_b = extract_chapters(b)

      regions_a.keys.sort.each do |chapter|
        if regions_b.has_key?(chapter)
          puts " * Chapter #{chapter}: #{regions_a[chapter].length}/#{regions_b[chapter].length} regions"
          chop_chapter(chapter, regions_a[chapter], regions_b[chapter], writer, options)
        else
          STDERR.puts " * Cannot find chapter #{chapter} in source A"
          writer.emit_tokens(regions_a[chapter].flatten, :track_sentence_numbers => true)
        end
        writer.next_sentence # make sure that each chapter starts a new sentence
      end
    end

    private

    # Transfers sentence boundaries within a chapter +chapter+ consisting
    # of the texts +region_a+ and +region_b+.
    def self.chop_chapter(chapter, region_a, region_b, writer, options)
      if options[:no_verse_synchronisation]
        transfer_boundaries(chapter, region_a, region_b, writer)
      else
        # Compute the set of minimal ranges.
        m = MinimalRangeSet.new
        region_a.each { |r| m.add(r.verse_range) }
        region_b.each { |r| m.add(r.verse_range) }

        # Repeatedly run the boundary transfer for the ranges.
        sentence_number = nil

        m.ranges.each do |s|
          verses_a = region_a.select { |r| r.verse_range.overlap?(s) }
          verses_b = region_b.select { |r| r.verse_range.overlap?(s) }

          # If the sentence number changed since the last time we outputted,
          # we need to explicitly add a sentence division.
          if verses_b.empty?
            STDERR.puts " * Cannot find verse #{chapter}:#{s.first}-#{s.last} in source B. Trying to recover."
          else
            sentence_number ||= verses_b.first.first[:sentence_number]
            writer.next_sentence if sentence_number != verses_b.first.first[:sentence_number]
            sentence_number = verses_b.first.first[:sentence_number]
          end

          transfer_boundaries(chapter, verses_a, verses_b, writer)
        end
      end
    end

    def self.transfer_boundaries(chapter, region_a, region_b, writer)
      sentence_number = nil

      Logos::Alignment::align_regions(region_a, region_b, :gale_church).each do |alignment|
        # Now is the time to figure out where to insert new sentence divisions. First, see if the
        # sentence number is stable within the regions in this alignment for source B. If they
        # aren't emit a warning complaining that we don't know what to do. In any case, keep
        # track of how the sentence number for source B increases, and add a sentence division
        # for source A whenever source B's changes.
        left, right = alignment.left.flatten, alignment.right.flatten
        
        b_sentence_numbers = right.collect { |t| t[:sentence_number] }.uniq
        STDERR.puts " * Chapter #{chapter}: Sentence division in the middle of aligned block from source B. Ignoring." if b_sentence_numbers.length > 1

        unless right.empty?
          # The right block may be empty, in which case we certainly do not want to introduce
          # any new sentence boundary.
          sentence_number ||= right.first[:sentence_number]
          writer.next_sentence if sentence_number != right.first[:sentence_number]
          sentence_number = right.first[:sentence_number]
        end

        writer.emit_tokens(left)
      end
    end

    def self.extract_chapters(src)
      chapters = src.classify { |t| t[:chapter].to_i }
      chapters.keys.each do |chapter|
        chapters[chapter] = accumulate_tokens(chapters[chapter])
      end

      chapters
    end

    # A representation of our alignable regions that uses the number of
    # non-punctuation tokens as weight.
    class AlignableRegion < Array
      # Returns the number of tokens in the region as a weight for alignment.
      def weight
        self.reject { |t| PROIEL::is_punctuation?(t[:sort]) }.length
      end

      # Returns the concatenation of all the token forms.
      def to_s
        self.collect { |t| t[:token] }.join(' ')
      end

      # Returns the verse range for this region. This assumes that all
      # tokens in this region belong to the same chapter.
      def verse_range
        raise "Tokens belong to different chapters" unless self.first[:chapter] == self.last[:chapter]
        raise "Verse numbers are in the wrong order" if self.first[:verse].to_i > self.last[:verse].to_i
        Range.new(self.first[:verse].to_i, self.last[:verse].to_i)
      end
    end

    def self.accumulate_tokens(tokens)
      regions = []
      current_region = nil

      tokens.collect do |t|
        form = t[:token]

        if PROIEL::is_punctuation?(t[:sort])
          unless current_region
            # This means that we are at the beginning of a region and have encountered
            # some punctuation. This may happen in two situations: 1) there is a sequence
            # of punctuation marks. This is OK. 2) A chapter starts with punctuation. This 
            # is bad for us, and we bail out.
            unless regions.last
              STDERR.puts "Punctuation encountered at beginning of region. Ignoring."
            else
              regions.last << t
            end
          else
            current_region << t
            regions << current_region
            current_region = nil
          end
        else
          current_region ||= AlignableRegion.new
          current_region << t
        end
      end

      regions << current_region if current_region
      regions
    end
  end
end
