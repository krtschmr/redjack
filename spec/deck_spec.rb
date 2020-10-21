RSpec.describe Redjack::Deck do

  it "has 52 cards" do
    deck = Redjack::Deck.new(1)
    expect(deck.cards.count).to eq(52)
  end
  
  it "has 8x52=416 cards" do
    deck = Redjack::Deck.new(8)
    expect(deck.cards.count).to eq(416)
  end

  it "has the same card order with same seed" do 
    deck_a = Redjack::Deck.new(1, 1234)
    deck_b = Redjack::Deck.new(1, 1234)
    expect(deck_a.cards).to eq(deck_b.cards)
  end

  it "has not the same card order with different seed" do 
    deck_a = Redjack::Deck.new(1, 1234)
    deck_b = Redjack::Deck.new(1, 4321)
    expect(deck_a.cards).to_not eq(deck_b.cards)
  end

  describe "drawing" do 
    it "2 cards from the deck" do 
      deck = Redjack::Deck.new(1, 1234)
      # we take 2 cards out
      expect(deck.draw.to_s).to eq("J of hearts")
      expect(deck.draw.to_s).to eq("7 of diamonds")
      # then expect that they are not in anymore
      expect(deck.cards.count).to eq(50)
      expect(deck.cards).to_not include(Redjack::Card.new("J", "hearts") )
      expect(deck.cards).to_not include(Redjack::Card.new("7", "diamonds") )
    end
  
    it "all cards from the deck" do 
      deck = Redjack::Deck.new(1, 1234)
      52.times { deck.draw }
      expect(deck.cards.count).to eq(0)
      expect(deck.draw).to be_nil
    end
  end
end