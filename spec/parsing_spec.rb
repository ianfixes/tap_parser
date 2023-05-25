require "spec_helper"
require "pathname"
require "json"

# ruby tries to symbolicate all the keys... stop it.
def str_key(hash)
  JSON.parse(hash.to_json)
end

RSpec.describe "TapParser" do

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

  context "parsing" do
    (Pathname.new(__dir__) + "examples").each_child.select(&:file?).select { |f| f.extname == ".tap" }.sort.each do |child|
      next if [
        "arduino_ci.tap",
        "e5.tap",
        "e6a.tap",
        "e6b.tap",
        "e6c.tap",
        "e6d.tap",
        "e6e.tap",
        "simple.tap",
      ].include?(child.basename.to_s)

      context("#{child.basename}") do
        corresponding_path = child.parent + "#{child.basename('.*')}.json"
        it "has a corresponding file at #{corresponding_path}" do
          expect(corresponding_path.file?).to be_truthy
        end

        it "has JSON in the corresponding file" do
          expect { JSON.parse(File.read(corresponding_path)) }.not_to raise_error
        end

        it "can parse" do
          TAPParser.parse(child.basename, File.read(child).each_line)
        end

        context "parsing" do
          expected = JSON.parse(File.read(corresponding_path)) rescue str_key({tests: []})

          before do
            @actual = str_key(TAPParser.parse(child.basename.to_s, File.read(child).each_line))
          end

          if expected["tests"].nil?
            it "Expects tests" do
              expect(expected["tests"].not_to be_nil)
            end
          else
            it "Has the expected number of tests" do
              expect(expected["tests"].length).to eq(@actual["tests"].length)
            end

            expected["tests"].length.times do |i|
              it "Has the expected tests[#{i}]" do
                expect(@actual["tests"][i]).to eq(expected["tests"][i])
              end
            end
          end

          it "parses as expected" do
            expect(@actual).to eq(expected)
          rescue RSpec::Expectations::ExpectationNotMetError => e
            puts JSON.pretty_generate(@actual, indent: "  ")
            raise
          end

        end
      end
    end
  end
end
