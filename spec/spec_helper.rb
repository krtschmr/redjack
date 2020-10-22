require "bundler/setup"
require 'simplecov'
require 'codecov'
require "pry"
require "assert_difference"

SimpleCov.start do
  enable_coverage :branch
end

require 'codecov'

if ENV["COVERAGE"]
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require "redjack"



def next_card(value, color="hearts")
  game.deck.cards.insert(0, Redjack::Card.new(value, color))
end

def card(face, color="hearts")
  Redjack::Card.new(face, color)
end

def find_deck_seed(p1, dealer)
  100000.times do |i|
    deck = Redjack::Deck.new(1, i)
    if dealer > 21
      if [deck.cards[0], deck.cards[2]].sum(&:points) == p1 && 
        [deck.cards[1], deck.cards[3], deck.cards[4]].sum(&:points) == dealer &&
        [deck.cards[1], deck.cards[3]].sum(&:points) < 17 # so he can go bust
        return i 
      end
    else
      return i if [deck.cards[0], deck.cards[2]].sum(&:points) == p1 && [deck.cards[1], deck.cards[3]].sum(&:points) == dealer
    end
  end
end


RSpec.configure do |config|
  config.include AssertDifference
  
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
  
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
