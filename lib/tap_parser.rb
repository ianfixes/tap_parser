require 'yaml'
require "tap_parser/version"

# TapParser contains a module for parsing and serializing text that follows the Test Anything Protocol
# @author Ian Katz <ianfixes@gmail.com>
module TAPParser
  TAP_TAB_WIDTH         = 4
  TAP_YAML_INDENT_WIDTH = 2

  # regexes we will use, with capture groups we will also use
  IS_TAP_VERSION = /^TAP version (\d+)/.freeze
  IS_COMMENT     = /^\s*#/.freeze
  IS_BLANK       = /^\s*$/.freeze
  IS_CONTENT     = /^(\s*)\S/.freeze
  IS_TAP_PLAN    = /^\s*1\.\.(\d+)/.freeze
  IS_TEST        = /
    ^                # start of line
    (\s*)            # any indentation
    ((not\ )?ok)     # result. note the escaping of the space!
    (\s+(\d+))?      # optional test number
    (\s+-(.*?))?     # optional test description
    \s*?             # optional spacing
    ([^\\]\#.*?)?    # optional directive, must start with space and hash
    \s*$             # optional trailing whitespace
  /x.freeze
  IS_BAIL_OUT    = /^Bail out!(\s*)(.+?)?\s*$/.freeze
  IS_DIRECTIVE   = /^[^\\]#\s+(SKIP|TODO)\s*(\S.*?)?\s*$/.freeze
  IS_PRAGMA      = /^\s*pragma ([+-])([a-zA-Z0-9_-]+)\s*$/.freeze

  # detect whether this is the start of a YAML block at the beginning of YAML indentation
  #
  # @param expected_indentation [String] the expected indentation in spaces
  # @return [bool]
  def self.yaml_begin(expected_indentation)
    yaml_indent = expected_indentation + (" " * TAP_YAML_INDENT_WIDTH)
    /^#{yaml_indent}---(\s*)$/
  end

  def self.yaml_end(expected_indentation)
    yaml_indent = expected_indentation + (" " * TAP_YAML_INDENT_WIDTH)
    /^#{yaml_indent}\.\.\.\s*$/
  end

  # Parse a TAP file into a hash of its contents
  #
  # @param source_description [String] the name of the input
  # @param lines [Enumerator] A source of lines as strings
  # @return [Hash] the structured content representing the input
  def self.parse(source_description, lines)
    @pragmas = nil

    # Workaround: the internal pointer of my enumerator keeps resetting to zero!
    # If you want something done right, do it yourself I guess :(
    @line_enumerator = lines.each

    # Take the next line of the input, and unescape slashes
    def self.enum_next
      @line_enumerator.next.gsub("\\\\", "\\") # unescape as we go
    rescue StopIteration
      nil
    end

    # peek at the next line of input
    def self.enum_peek
      @line_enumerator.peek
    rescue StopIteration
      nil
    end

    # take all matching contiguous lines of input
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

    # figure out the indentation level of lines in terms of number of tabs
    def self.indentation_of(line)
      return nil if line.nil?

      match = IS_CONTENT.match(line)
      match.nil? ? 0 : ($1.length / TAP_TAB_WIDTH).to_i
    end

    def self.empty_as_nil(str)
      str.nil? || str.empty? ? nil : str.strip
    end

    # recursive entry point: parse a TAP file into a hash of its contents
    #
    # @param parent_description [String] the name of the input
    # @param current_indentation [Int] the number of tabs the input is expected to have
    # @return [Hash] the structured content of the file
    def self.parse_tests(parent_description, current_indentation)
      expected_indentation = " " * current_indentation * TAP_TAB_WIDTH
      protocol_version = nil
      directives = nil
      expected_tests = nil
      encountered_tests = 0
      tests = []
      children = nil

      loop do
        # decide whether to recurse
        this_line = enum_peek
        children = parse_tests(nil, current_indentation + 1) if !this_line.nil? && indentation_of(this_line) > current_indentation

        # consume input from wherever we left off
        line = enum_next
        next_line = enum_peek

        # special case exit when subtests aren't "owned"
        if line.nil?
          tests << { children: children } unless children.nil?
          break
        end

        # process the input
        case line
        when IS_TAP_VERSION
          protocol_version = $1.to_i
        when IS_COMMENT
          # comment, ignore
        when IS_TAP_PLAN
          expected_tests = $1.to_i
        when IS_BAIL_OUT
          reason = empty_as_nil($2)
          directives ||= {}
          directives["bail out"] = reason
          break
        when IS_PRAGMA
          action = $1 == '+' ? 'enable' : 'disable'
          pragma_key = $2
          @pragmas ||= {}
          @pragmas[pragma_key] = action
        when IS_TEST
          encountered_tests += 1
          result_str = $2
          test_number = $4.nil? ? encountered_tests : $4.to_i
          description = empty_as_nil($7)
          directive_str = $8

          # avoid doing gsub above because it screws up the $ variables
          description = description.gsub("\\#", "#") unless description.nil?

          test = {
            number: test_number,
            description: description,
            ok: (result_str == 'ok'),
          }

          # add children if parsed, and reset
          test[:children] = children unless children.nil?
          children = nil

          # find directives and add
          unless directive_str.nil?
            match = IS_DIRECTIVE.match(directive_str)
            k = $1  # could be nil if not SKIP or TODO, so don't .to_sym here
            v = empty_as_nil($2)&.gsub("\\#", "#")
            test[:directives] = { k.to_sym => v } if match && !k.nil?
          end

          # find diagnostics and add
          yaml_indent = expected_indentation + (" " * 2)
          if yaml_begin(expected_indentation).match(next_line)
            raw_yaml = enum_take_while { |l| !yaml_end(expected_indentation).match(l) }
            yaml = raw_yaml.map { |l| l[yaml_indent.length..] }.to_a.join
            test[:diagnostics] = YAML.safe_load(yaml)
            enum_next # strip off "..."
          end

          # record the test
          tests << test
        end

        # handle the end of recursion if the next line is de-indented.
        # according to the spec, we can only go up one level at a time
        next_line_indentation = indentation_of(next_line)
        break if next_line.nil? || next_line_indentation < current_indentation
      end

      # summarize the entire operation
      ret = {
        tests: tests,
        expected_tests: expected_tests
      }
      ret[:description] = parent_description unless parent_description.nil?
      ret[:tap_version] = protocol_version if current_indentation.zero?
      ret[:directives]  = directives unless directives.nil?
      ret[:pragmas]     = @pragmas if current_indentation.zero? && !@pragmas.nil?
      ret
    end

    parse_tests(source_description, 0)
  end
end
