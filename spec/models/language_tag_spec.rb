require 'rails_helper'

RSpec.describe LanguageTag, type: :model do
  it "can be accessed with language accessor" do
    tag1 = 'lat'
    tag2 = 'grc'
    expect(LanguageTag.new(tag1).language).to eq tag1
    expect(LanguageTag.new(tag2).language).to eq tag2
  end

  it "can be serialized with to_s" do
    tag1 = 'lat'
    tag2 = 'grc'
    expect(LanguageTag.new(tag1).to_s).to eq tag1
    expect(LanguageTag.new(tag2).to_s).to eq tag2
  end
end
