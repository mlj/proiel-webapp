require 'rails_helper'

RSpec.describe "application/opensearch", type: :view do
  before do
    render
    @xml_element = Nokogiri.XML rendered
  end

  context 'short name' do
    subject { @xml_element.search('ShortName').text }
    it { is_expected.to eq(I18n.translate('short_title')) }
  end

  context 'search description' do
    subject { @xml_element.search('Description').text }
    it { is_expected.to eq(I18n.translate('opensearch_description')) }
  end

  context 'input encoding ' do
    subject { @xml_element.search('InputEncoding').text }
    it { is_expected.to eq('UTF-8') }
  end
  
  context 'image' do
    subject { @xml_element.search('Image').text }
    it { is_expected.to eq('http://test.host/assets/icon.png') }
  end

  context 'search terms' do
    subject { @xml_element.search('Url').attr('template').value }
    it { is_expected.to eq(CGI.unescape(quick_search_url(q: '{searchTerms}'))) }
  end
end
