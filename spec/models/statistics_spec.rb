require "spec_helper"

describe Proiel::Statistics do
  it "calculates least squares" do
    x = [1, 1, 2, 3, 4, 4, 5, 6, 6, 7]
    y = [2.1, 2.5, 3.1, 3.0, 3.8, 3.2, 4.3, 3.9, 4.4, 4.8]

    a, b = Proiel::Statistics::least_squares(x, y)

    a.should be_within(0.01).of(2.0)
    b.should be_within(0.01).of(0.387)
  end
end
