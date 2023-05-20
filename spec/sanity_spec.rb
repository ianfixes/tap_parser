require "spec_helper"
require "pathname"

RSpec.describe "TapParser" do
  context "existence" do
    it "has a version" do
      expect(TapParser::VERSION).to_not be(nil)
    end
  end

end
