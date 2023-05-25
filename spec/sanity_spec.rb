require "spec_helper"
require "pathname"

RSpec.describe "TAPParser" do
  context "existence" do
    it "has a version" do
      expect(TAPParser::VERSION).to_not be(nil)
    end
  end

end
