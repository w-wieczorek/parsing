# parsing

This is a simple Crystal module for one-pass parsing.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     parsing:
       github: w-wieczorek/parsing
   ```

2. Run `shards install`

## Usage

```crystal
require "parsing"
include Parsing

str = <<-DOT
  graph G {
    0;
    1;
    2;
    4;
    5;
    0 -> 1;
    1 -> 2;
    2 -> 4;
    5 -> 0;
  }
  DOT

text = Slice.new(str.chars.to_unsafe, str.size)

num : Parser(Int32) =
  digit.many1.store { |ns|
  mreturn(ns.join.to_i) }

num_semicolon : Parser(Int32) =
  num.store { |value|
  char(';').skip (
  whitespace.many0.skip (
  mreturn(value) ) ) }

edge : Parser(Tuple(Int32, Int32)) =
  num.store { |v1|
  whitespace.many0.skip (
  seq(Slice['-', '-']).skip (
  whitespace.many0.skip (
  num.store { |v2|
  char(';').skip (
  whitespace.many0.skip (
  mreturn({v1, v2}) ) ) } ) ) ) }

graph_parser : Parser(Tuple(Array(Int32), Array(Tuple(Int32, Int32)))) =
  seq(Slice['g', 'r', 'a', 'p', 'h']).skip (
  whitespace.many1.skip (
  letter.store { |name|
  whitespace.many0.skip (
  char('{').skip (
  whitespace.many0.skip (
  num_semicolon.many1.store { |vs|
  edge.many0.store { |es|
  char('}').skip (
  mreturn({vs, es}) ) } } ) ) ) } ) )

result = graph_parser.parse text
if result.size > 0
  arrays, slice = result[0]
  graph = {vertices: arrays[0].to_set, edges: arrays[1].to_set}
  puts graph
  if slice.size > 0
    puts "The remaining text is #{slice.to_s}"
  end
end
```

## Contributing

1. Fork it (<https://github.com/your-github-user/parsing/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [your-name-here](https://github.com/your-github-user) - creator and maintainer
