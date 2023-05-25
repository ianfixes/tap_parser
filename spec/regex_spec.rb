require "spec_helper"

RSpec.describe "TAPParser" do

  context "regexes" do

    it "can parse version" do
      match = TAPParser::IS_TAP_VERSION.match("TAP version 999")
      expect($1).to eq("999")
    end

    it "can recognize comments" do
      expect(TAPParser::IS_COMMENT.match("#   ")).to be_truthy
      expect(TAPParser::IS_COMMENT.match("   #")).to be_truthy
    end

    it "can recognize plans" do
      match = TAPParser::IS_TEST.match("ok")
      expect(match).to be_truthy
      expect($1).to eq("")
      expect($2).to eq("ok")
      expect($3).to eq(nil)
      expect($4).to eq(nil)
      expect($5).to eq(nil)
      expect($6).to eq(nil)
      expect($7).to eq(nil)
      expect($8).to eq(nil)
      expect($9).to eq(nil)

      match = TAPParser::IS_TEST.match("    ok")
      expect(match).to be_truthy
      expect($1).to eq("    ")
      expect($2).to eq("ok")
      expect($3).to eq(nil)
      expect($4).to eq(nil)
      expect($5).to eq(nil)
      expect($6).to eq(nil)
      expect($7).to eq(nil)
      expect($8).to eq(nil)
      expect($9).to eq(nil)

      match = TAPParser::IS_TEST.match("not ok")
      expect(match).to be_truthy
      expect($1).to eq("")
      expect($2).to eq("not ok")
      expect($3).to eq("not ")
      expect($4).to eq(nil)
      expect($5).to eq(nil)
      expect($6).to eq(nil)
      expect($7).to eq(nil)
      expect($8).to eq(nil)
      expect($9).to eq(nil)

      match = TAPParser::IS_TEST.match("not ok 4 - Summarized correctly # TODO Not written yet")
      expect(match).to be_truthy
      expect($1).to eq("")
      expect($2).to eq("not ok")
      expect($3).to eq("not ")
      expect($4).to eq(" 4")
      expect($5).to eq("4")
      expect($6).to eq(" - Summarized correctly")
      expect($7).to eq(" Summarized correctly")
      expect($8).to eq(" # TODO Not written yet")
      expect($9).to eq(nil)

      match = TAPParser::IS_TEST.match("ok 5 - # SKIP no /sys directory")
      expect(match).to be_truthy
      expect($1).to eq("")
      expect($2).to eq("ok")
      expect($3).to eq(nil)
      expect($4).to eq(" 5")
      expect($5).to eq("5")
      expect($6).to eq(" -")
      expect($7).to eq("")
      expect($8).to eq(" # SKIP no /sys directory")
      expect($9).to eq(nil)

    end

    it "can recognize tests" do
      match = TAPParser::IS_BAIL_OUT.match("Bail out!")
      expect(match).to be_truthy
      expect($2).to be_nil
    end

    it "can recognize bailouts" do
      match = TAPParser::IS_BAIL_OUT.match("Bail out!")
      expect(match).to be_truthy
      expect($2).to be_nil

      match = TAPParser::IS_BAIL_OUT.match("Bail out! I'm tired")
      expect($2).to eq("I'm tired")

      match = TAPParser::IS_BAIL_OUT.match("Bail out! no newline\n")
      expect($2).to eq("no newline")
    end

    it "can recognize directives" do
      match = TAPParser::IS_DIRECTIVE.match(" # TODO")
      expect($1).to eq("TODO")
      expect($2).to be_nil

      match = TAPParser::IS_DIRECTIVE.match(" # TODO things later")
      expect($1).to eq("TODO")
      expect($2).to eq("things later")

      match = TAPParser::IS_DIRECTIVE.match(" # SKIP no /sys directory")
      expect($1).to eq("SKIP")
      expect($2).to eq("no /sys directory")
    end

    it "can recognize pragmas" do
      match = TAPParser::IS_PRAGMA.match("pragma +foo  \n")
      expect($1).to eq("+")
      expect($2).to eq("foo")

      match = TAPParser::IS_PRAGMA.match("pragma -bar")
      expect($1).to eq("-")
      expect($2).to eq("bar")
    end

  end
end
