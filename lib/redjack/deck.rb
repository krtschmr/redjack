module Redjack
  class Deck
    SUITS = %w(hearts clubs spades diamonds)
    RANKS = ["A",2, 3, 4, 5, 6, 7, 8, 9, 10, "J", "Q", "K"]

    attr_accessor :cards

    def initialize(decks, seed=Random.new.seed)
      self.cards = build_deck * decks
      self.cards.shuffle!(random: Random.new(seed))
    end

    # :nocov:
    def inspect
      "<Deck next: #{cards.first.inspect} left: #{cards.count} >"
    end
    # :nocov:

    def draw
      # remove first item of deck
      cards.shift
    end

    private

    def build_deck
      RANKS.flat_map {|rank| SUITS.flat_map {|suit| Card.new(rank,suit) } }
    end
  end
end