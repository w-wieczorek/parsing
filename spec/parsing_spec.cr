require "spec"
require "../src/parsing.cr"

describe Parsing do
  simple_slice = Slice['a', 'b', 'c', 'd']

  it "parses a char" do
    result = Parsing.item.parse simple_slice
    result.should eq( [{'a', Slice['b', 'c', 'd']}] )
  end

  it "can return something without consuming" do
    result = Parsing.mreturn(99).parse simple_slice
    result.should eq( [{99, Slice['a', 'b', 'c', 'd']}] )
  end

  it "chains parsers with storing values" do
    pair =
      Parsing.item.store { |i1|
      Parsing.item.store { |i2|
      Parsing.mreturn({i1, i2}) } }
    
    result = pair.parse simple_slice
    result.should eq( [{ {'a', 'b'}, Slice['c', 'd']}] )
  end

  it "can skip chars" do 
    items1and4 =
      Parsing.item.store { |i1|
      Parsing.item.skip (
      Parsing.item.skip (
      Parsing.item.store { |i4|
      Parsing.mreturn({i1, i4}) } ) ) }
    
    result = items1and4.parse simple_slice
    result.should eq( [{ {'a', 'd'}, Slice(Char).empty}] )
  end

  it "parses a char that fulfills a certain predicate" do
    result = Parsing.sat(&.!=('z')).parse simple_slice
    result.should eq( [{ 'a', Slice['b', 'c', 'd']}] )
    result = Parsing.sat(&.!=('a')).parse simple_slice
    result.size.should eq(0)
  end

  it "parses a given char" do
    result = Parsing.char('a').parse simple_slice
    result.should eq( [{ 'a', Slice['b', 'c', 'd']}] )
  end

  it "parses a given sequence" do
    word = Slice.new("abc".chars.to_unsafe, 3)
    result = Parsing.seq(word).parse simple_slice
    result.should eq( [{ nil, Slice['d']}] )
  end

  it "parses a digit" do
    result = Parsing.digit.parse Slice['1', 'b', 'c', 'd']
    result.should eq( [{ '1', Slice['b', 'c', 'd']}] )
    result = Parsing.digit.parse simple_slice
    result.size.should eq(0)
  end

  it "parses a letter" do
    result = Parsing.letter.parse simple_slice
    result.should eq( [{ 'a', Slice['b', 'c', 'd']}] )
    result = Parsing.letter.parse Slice['1', 'b', 'c', 'd']
    result.size.should eq(0)
  end

  it "can handle an alternative" do
    result = (Parsing.char('a') // Parsing.char('b')).parse simple_slice
    result.should eq( [{ 'a', Slice['b', 'c', 'd']}] )
    result = (Parsing.char('b') // Parsing.char('a')).parse simple_slice
    result.should eq( [{ 'a', Slice['b', 'c', 'd']}] )
  end

  it "can handle the Kleene closure" do
    result = Parsing.item.many0.parse simple_slice
    result.should eq( [{['a', 'b', 'c', 'd'], Slice(Char).empty}] )
  end

  it "allows building a parser for integers" do
    num : Parsing::Parser(Int32) =
      Parsing.digit.many1.store { |ns|
      Parsing.mreturn(ns.join.to_i) }

    result = num.parse Slice.new("124".chars.to_unsafe, 3)
    result.should eq( [{124, Slice(Char).empty}] )
    result = num.parse Slice.new("12a4".chars.to_unsafe, 4)
    result.should eq( [{12, Slice['a', '4']}] )
  end

  it "parses more complex texts" do
    table = [1, 2, 34, 100]
    s = table.to_s
    text = Slice.new(s.chars.to_unsafe, s.size)

    num : Parsing::Parser(Int32) =
      Parsing.digit.many1.store { |ns|
      Parsing.char(',').skip (
      Parsing.whitespace.many0.skip (
      Parsing.mreturn(ns.join.to_i) ) ) }

    last_num : Parsing::Parser(Int32) =
      Parsing.digit.many1.store { |ns|
      Parsing.mreturn(ns.join.to_i) }

    tableP : Parsing::Parser(Array(Int32)) =
      Parsing.char('[').skip (
      num.many0.store { |ns|
      last_num.store { |ln|
      Parsing.char(']').skip (
      Parsing.mreturn(ns << ln) ) } } )
    
    result = tableP.parse text
    result.should eq( [{table, Slice(Char).empty}] )
  end
end
