require File.dirname(__FILE__) + '/../test_helper'

class SourceTest < ActiveSupport::TestCase
  fixtures :sources

  def test_metadata
    s = Source.new
    s.tei_header = '<TEI.2><teiHeader></teiHeader></TEI.2>'
    assert s.metadata.valid?
    assert s.metadata.to_html
    assert_equal '<teiHeader xmlns="http://www.tei-c.org/ns/1.0"/>', s.metadata.export_form
  end
end
