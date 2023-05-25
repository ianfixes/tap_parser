
# TapParser Ruby gem (`tap_parser`)
[![Gem Version](https://badge.fury.io/rb/tap_parser.svg)](https://rubygems.org/gems/tap_parser)
[![Documentation](http://img.shields.io/badge/docs-rdoc.info-blue.svg)](http://www.rubydoc.info/gems/tap_parser/0.0.0)

`tap_parser` is a Ruby gem that parses the [Test Anything Protocol](https://testanything.org/).

## Quick start

First `gem install tap_parser`. Then:

```ruby
require "TAPParser"
require "pathname"
require "json"

result_file = Pathname.new("/path/to/myfile.tap")
result = TAPParser.parse(result_file.basename, File.read(result_file).each_line)
puts JSON.pretty_generate(result, indent: "  ")
```


## Author

This gem was written by Ian Katz (ianfixes@gmail.com) in 2023.  It's released under the Apache 2.0 license.


## See Also

* [Contributing](CONTRIBUTING.md)
