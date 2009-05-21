module PartsOfSpeechHelper
  # Creates a table view of a collection of parts of speech.
  def parts_of_speech_table(parts_of_speech)
    render_tabular parts_of_speech, [ 'Tag', 'Summary', 'Frequency', '&nbsp;' ]
  end

  # Returns a link to a part of speech.
  #
  # ==== Options
  # <tt>:abbreviated</tt> - If true, will use the abbreviated form of the
  # summary as the link text.
  def link_to_part_of_speech(part_of_speech, options = {})
    if options[:abbreviated]
      link_to part_of_speech.summary, part_of_speech
    else
      link_to part_of_speech.abbreviated_summary, part_of_speech
    end
  end

  # Returns a link to an array of parts of speech.
  #
  # ==== Options
  # <tt>:abbreviated</tt> - If true, will use the abbreviated form of the
  # summary as the link text.
  def link_to_parts_of_speech(parts_of_speech, options = {})
    parts_of_speech.map { |l| link_to_part_of_speech(l, options) }.to_sentence
  end
end
