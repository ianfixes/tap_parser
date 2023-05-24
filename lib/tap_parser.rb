require 'yaml'
require "tap_parser/version"

# TapParser contains a module for parsing and serializing text that follows the Test Anything Protocol
# @author Ian Katz <ianfixes@gmail.com>
module TAPParser

  def self.parse(source_description, lines)
    pragmas = {}

    # some nonsense because the internal pointer of my iterator keeps resetting to zero!
    @line_enumerator = lines.each

    def self.enum_next
      @line_enumerator.next
    rescue StopIteration
      nil
    end

    def self.enum_peek
      @line_enumerator.peek
    rescue StopIteration
      nil
    end

    def self.enum_take_while(&block)
      Enumerator.new do |yielder|
        loop do
          x = enum_peek
          break if x.nil?
          break unless block.call(x)
          enum_next
          yielder << x
        end
      end
    end

    def self.parse_tests(parent_description, current_indentation, limit)
      return {} if limit < 0
      expected_indentation = " " * current_indentation * 4
      protocol_version = nil
      directives = nil
      expected_tests = nil
      encountered_tests = 0
      tests = []

      loop do
        line = enum_next
        break if line.nil?
        next_line = enum_peek

        case line
        when /^TAP version (\d+)/
          protocol_version = $1.to_i
        # when /^\s*#/
        #   # comment, ignore
        when /^1\.\.(\d+)/
          # TAP plan line
          expected_tests = $1.to_i
        when /^(\s*)((not )?ok)\s*(\d+)?\s*(-\s*)?(.*?)\s*(#.*?)?\n$/
          encountered_tests += 1
          actual_indentation = $1 || ''
          result_str = $2
          test_number = $4.nil? ? encountered_tests : $4.to_i
          description = $6.strip
          directive_str = $7

          test = {
            number: test_number,
            description: description,
            result: (result_str == 'ok' ? :pass : :fail),
            # subtests: parse_tests(description, lines, indentation, limit - 1),
          }

          # find directives
          unless directive_str.nil?
            match = /#\s+(SKIP|TODO)(\S*\s+([^\n]*))?/.match(directive_str)
            test[:directives] = { $1.to_sym => $3 } if match
          end

          # find diagnostics
          yaml_indent = expected_indentation + (" " * 2)
          if /^#{yaml_indent}---(\s*)$/.match(next_line)
            raw_yaml = enum_take_while { |l| !/^#{yaml_indent}\.\.\.\s*$/.match(l) }
            yaml = raw_yaml.map { |l| l[yaml_indent.length..-1] }.to_a.join
            # puts yaml.to_s
            test[:diagnostics] = YAML.safe_load(yaml)
            enum_next # strip off "..."
          end

          tests << test

        # when /^(\s*)---\n/
        #   test = parse_tests(lines, current_indentation, limit - 1)
        #   test[:diagnostics] ||= {}

        #   yaml_block_lines = []
        #   begin
        #     line = lines.peek
        #     break if line == "#{test[:indentation]}...\n"
        #     yaml_block_lines << lines.next
        #   rescue StopIteration
        #     break
        #   end

        #   yaml_block = YAML.safe_load(yaml_block_lines.join(''))
        #   test[:diagnostics].merge!(yaml_block)

        #   tests << test
        when /^Bail out!(.*)\n$/
          # Bail out directive
          reason = ($1.nil? || $1.strip.empty?) ? nil : $1.strip
          directives ||= {}
          directives["bail out"] = reason
          break
        when /^pragma ([+-])([a-zA-Z0-9_-]+)\n$/
          # Pragma directive
          action = $1 == '+' ? 'enable' : 'disable'
          pragma_key = $2
          pragmas[pragma_key] = action
        end
      end

      ret = {
        tap_version: protocol_version,
        description: parent_description,
        tests: tests,
        expected_tests: expected_tests
      }
      ret[:directives] = directives unless directives.nil?
      ret
    end
    parse_tests(source_description, 0, 2)
  end
end
