module Parsing
  class Parser(T)
    property fun : Proc( Slice(Char), Array(Tuple(T, Slice(Char))) )
  
    def initialize(@fun)
    end
  
    def store(&f : T -> Parser(U)) forall U
      Parser(U).new(
        ->(cs : Slice(Char)) {
          parse(cs).map{ |r, _cs| (f.call r).parse(_cs) }.flatten
        }
      )
    end

    def skip(q : Parser(U)) forall U
      Parser(U).new(
        ->(cs : Slice(Char)) {
          parse(cs).map{ |r, _cs| q.parse(_cs) }.flatten
        }
      )
    end

    def //(q : Parser(U)) forall U
      Parser(T | U).new(
        ->(cs : Slice(Char)) {
          result = parse(cs)
          if result.empty?
            q.parse(cs)
          else
            result
          end
        }
      )
    end
  
    def self.mreturn(r : T)
      Parser(T).new( ->(cs : Slice(Char)) { [{r, cs}] } )
    end
  
    def many0 : Parser(Array(T))
      many1 // Parser(Array(T)).mreturn([] of T)
    end
    
    def many1 : Parser(Array(T)) 
      store { |r|
      many0.store { |rs|
      Parser(Array(T)).mreturn([r] + rs) } }
    end
  
    def parse(cs : Slice(Char))
      @fun.call cs
    end
  end
  
  class Fail(T) < Parser(T)
    def initialize
      super( ->(cs : Slice(Char)) { [] of Tuple(T, Slice(Char)) } )
    end
  end
  
  def self.mreturn(r : T) forall T
    Parser(T).new( ->(cs : Slice(Char)) { [{r, cs}] } )
  end
  
  def self.item
    Parser(Char).new(
      ->(cs : Slice(Char)) {
        if cs.empty? 
          [] of Tuple(Char, Slice(Char))
        else
          c, _cs = cs[0], cs[1..]
          [{c, _cs}]
        end
      }
    )
  end
  
  def self.sat(&cond : Char -> Bool)
    item.store { |c| cond.call(c) ? mreturn(c) : Fail(Char).new }
  end
  
  def self.char(c : Char)
    sat &.==(c)
  end
  
  def self.seq(cs : Slice(Char)) : Parser(Nil)
    if cs.size > 0
      c, _cs = cs[0], cs[1..]
      (char c).skip(seq(_cs).skip(Parser(Nil).mreturn(nil)))
    else
      Parser(Nil).mreturn(nil)
    end
  end
  
  def self.digit
    sat &.number?
  end
  
  def self.letter
    sat &.letter?
  end
  
  def self.whitespace
    sat &.whitespace?
  end
end
