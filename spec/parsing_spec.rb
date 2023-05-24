require "spec_helper"
require "pathname"
require "json"

RSpec.describe "TapParser" do
  context "parsing" do

    (Pathname.new(__dir__) + "examples").each_child.select(&:file?).select { |f| f.extname == ".tap" }.sort.each do |child|
      next unless ["null.tap", "e10.tap", "e8.tap", "e7.tap", "e11.tap"].include?(child.basename.to_s)

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
          expected = JSON.parse(File.read(corresponding_path))
          actual_sym = TAPParser.parse(child.basename.to_s, File.read(child).each_line)
          actual = JSON.parse(actual_sym.to_json)

          it "Has the expected number of tests" do
            expect(expected["tests"].length).to eq(actual["tests"].length)
          end

          [expected["tests"].length, actual["tests"].length].max.times do |i|
            it "Has the expected tests[#{i}]" do
              expect(actual["tests"][i]).to eq(expected["tests"][i])
            end
          end

          it "parses as expected" do
            expect(actual).to eq(expected)
          end
        end
      end
    end
  end
end
