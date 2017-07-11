require 'test_helper'

class SourceTest < ActiveSupport::TestCase
  test "Complete but empty Source object" do
    s = sources(:complete_but_without_contents)

    assert_equal 'Plautus',            s.author
    assert_equal 'Amphitruo',          s.title
    assert_equal 'Plautus: Amphitruo', s.author_and_title
    assert_equal 'Amphitruo',          s.to_label

    assert_equal 'lat',  s.language_tag
    assert_equal 'Latin', s.language_name

    assert_equal 'Pl. Am.', s.citation_part
    assert_equal 'Pl. Am.', s.citation

    assert_equal 'pl-am', s.code

    assert_empty s.annotator
    assert_empty s.reviewer
    assert_empty s.aggregated_status_statistics

    assert_nil s.inferred_aligned_source
  end
end
