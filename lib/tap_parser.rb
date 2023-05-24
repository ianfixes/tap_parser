require 'yaml'
require "tap_parser/version"

# TapParser contains a module for parsing and serializing text that follows the Test Anything Protocol
# @author Ian Katz <ianfixes@gmail.com>
module TAPParser

  IS_TAP_VERSION = /^TAP version (\d+)/
  IS_COMMENT =     /^\s*#/
  IS_TAP_PLAN =    /^1\.\.(\d+)/
  IS_TEST =        /^(\s*)((not )?ok)\s*(\d+)?\s*(-\s*)?(.*?)\s*(#.*?)?\n$/
  IS_BAIL_OUT =    /^Bail out!(.*)\n$/
  IS_DIRECTIVE =   /#\s+(SKIP|TODO)(\S*\s+([^\n]*))?/
  IS_PRAGMA =      /^pragma ([+-])([a-zA-Z0-9_-]+)\n$/

  def self.is_yaml_begin(expected_indentation)
    yaml_indent = expected_indentation + (" " * 2)
    /^#{yaml_indent}---(\s*)$/
  end

  def self.is_yaml_end(expected_indentation)
    yaml_indent = expected_indentation + (" " * 2)
    /^#{yaml_indent}\.\.\.\s*$/
  end

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
        when IS_TAP_VERSION
          protocol_version = $1.to_i
        when IS_COMMENT
          # comment, ignore
        when IS_TAP_PLAN
          # TAP plan line
          expected_tests = $1.to_i
        when IS_TEST
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
            match = IS_DIRECTIVE.match(directive_str)
            test[:directives] = { $1.to_sym => $3 } if match
          end

          # find diagnostics
          yaml_indent = expected_indentation + (" " * 2)
          if is_yaml_begin(expected_indentation).match(next_line)
            raw_yaml = enum_take_while { |l| !is_yaml_end(expected_indentation).match(l) }
            yaml = raw_yaml.map { |l| l[yaml_indent.length..-1] }.to_a.join
            test[:diagnostics] = YAML.safe_load(yaml)
            enum_next # strip off "..."
          end

          tests << test

        when IS_BAIL_OUT
          # Bail out directive
          reason = ($1.nil? || $1.strip.empty?) ? nil : $1.strip
          directives ||= {}
          directives["bail out"] = reason
          break

        when IS_PRAGMA
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
