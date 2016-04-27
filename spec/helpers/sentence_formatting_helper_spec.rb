require 'rails_helper'

RSpec.describe SentenceFormattingHelper, type: :helper do
  describe 'TokenText' do
    it "returns HTML for PUA italic/sub/sup characters" do
      expect(TokenText.token_form_as_html("\u{F002}GIŠ\u{F102}GU.ZA")).to eq "<sup>GIŠ</sup>GU.ZA"
      expect(TokenText.token_form_as_html("\u{F000}A-BI-IA\u{F100}")).to eq "<i>A-BI-IA</i>"
      expect(TokenText.token_form_as_html("\u{F002}m\u{F102}\u{F000}Ar-nu-an-da-an\u{F100}")).to eq "<sup>m</sup><i>Ar-nu-an-da-an</i>"
      expect(TokenText.token_form_as_html("\u{F002}URU\u{F102}Ka\u{F001}4\u{F101}-aš-ka\u{F001}4\u{F101}-ma")).to eq "<sup>URU</sup>Ka<sub>4</sub>-aš-ka<sub>4</sub>-ma"
    end

    it "returns HTML with line and paragraph breaks" do
      expect(TokenText.token_form_as_html("line\u{2028}line")).to eq "line<br>line"
      expect(TokenText.token_form_as_html("line\u{2029}line")).to eq "line<p>line"
      expect(TokenText.token_form_as_html("line\u{2028}line\u{2029}line\u{2029}line\u{2028}line")).to eq "line<br>line<p>line<p>line<br>line"
      expect(TokenText.token_form_as_html("line\u{2028}\u{2029}line")).to eq "line<br><p>line"
    end

    it "ignores line and paragraph breaks if asked to" do
      expect(TokenText.token_form_as_html("line\u{2028}line", single_line: true)).to eq "line line"
      expect(TokenText.token_form_as_html("line\u{2029}line", single_line: true)).to eq "line line"
      expect(TokenText.token_form_as_html("line\u{2028}line\u{2029}line\u{2029}line\u{2028}line", single_line: true)).to eq "line line line line line"
      expect(TokenText.token_form_as_html("line\u{2028}\u{2029}line", single_line: true)).to eq "line line"
    end
  end
end
