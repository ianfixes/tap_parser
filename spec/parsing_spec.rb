require "spec_helper"
require "pathname"
require "json"

# ruby tries to symbolicate all the keys... stop it.
def str_key(hash)
  JSON.parse(hash.to_json)
end

RSpec.describe "TAPParser" do
  context "parsing" do
    (Pathname.new(__dir__) + "examples").each_child.select(&:file?).select { |f| f.extname == ".tap" }.sort.each do |child|

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
            unless ENV['HELP_WITH_JSON'].nil?
              puts JSON.pretty_generate(@actual, indent: "  ")
            end
            raise
          end

        end
      end
    end
  end
end
