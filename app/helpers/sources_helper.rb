module SourcesHelper
  # Returns a link to a source.
  def link_to_source(source)
    link_to source.title, source
  end

  def metadata_fields_and_labels(source)
    {
      'Treebank' => Proiel::Metadata::treebank_fields_and_labels,
      'Electronic text' => Proiel::Metadata::electronic_text_fields_and_labels,
      'Printed text' => Proiel::Metadata::printed_text_fields_and_labels,
    }.map do |header, data|
      d = data.map { |(f, lbl)| [lbl, @source.send(f)] }.reject { |(_, f)| f.blank? }
      [header, d]
    end
  end
end
