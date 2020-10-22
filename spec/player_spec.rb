RSpec.describe Redjack::Player do

  let(:game) { Redjack::Game.new(seed: 1234, balance: 500, bets: [100]) }
  let(:player) { game.current_player }

  let(:bj_game) { Redjack::Game.new(seed: 8, balance: 300, bets: [100]) } # 10, Q, A. so player gets a BJ
  let(:bj_player) { bj_game.players.first }

  describe "with a just started game" do 
    it "has 2 cards" do
      expect(player.cards.count).to eq(2)
    end 

    it "can hit" do 
      expect(player.can_hit?).to eq(true)
    end

    it "can stand" do 
      expect(player.can_stand?).to eq(true)
    end

    it "is not splitted" do 
      expect(player).to_not be_splitted
    end
  end

  it "has a Blackjack" do 
    player.cards = [card("A"), card("K")]
    expect(player).to be_blackjack
  end

  describe "point counting" do 
    it "returns 21 for a Blackjack" do 
      player.cards = [card("A"), card("K")]
      expect(player.points).to eq(21)

      player.cards = [card("A"), card("T")]
      expect(player.points).to eq(21)
    end

    it "returns 20 for two Queens" do 
      player.cards = [card("Q"), card("Q")]
      expect(player.points).to eq(20)
    end

    it "returns 17 for A K 6" do 
      player.cards = [card("A"), card("K"), card(6)]      
      expect(player.points).to eq(17)
    end

    it "returns 17 for A 6" do 
      player.cards = [card("A"), card(6)]      
      expect(player.points).to eq(17)
    end

    it "returns 21 for 2 2 2 2 2 2 2 2 2 2 2 A" do 
      player.cards = [card("A"), *10.times.collect{ card("2") } ]
      expect(player.points).to eq(21)
    end

    it "returns 30 for 3 tens" do 
      player.cards = [ card("K"), card("Q"), card("J") ]
      expect(player.points).to eq(30)
    end

    it "returns 15 for A A A A A" do 
      player.cards = 5.times.collect{ card("A") }
      expect(player.points).to eq(15)
    end 
    
    it "returns 15 for K A A A A A" do 
      player.cards = [ card("K"), *5.times.collect{ card("A") } ]
      expect(player.points).to eq(15)
    end 
  end
  
  it "can't finish if he's already finished" do 
    allow(player).to receive(:finished?) { true }
    expect { player.finish! }.to raise_error("already finished")      
  end

  describe "hitting" do 
    it "will receive a card from the deck" do 
      next_card_in_deck = game.deck.cards.first
      assert_difference("player.cards.count" => +1, "game.deck.cards.count" => -1) do 
        player.hit!
        expect(player.cards.last).to eq(next_card_in_deck)        
      end
    end

    it "can't use the :take_card! method" do 
      expect { player.take_card! }.to raise_error("must hit! instead of taking a card")              
    end

    it "autoreceives a card if he's under 9 but can't split" do 
      player.cards = [card(2), card(3)]
      expect(player).to be_must_hit
    end

    it "won't autoreceive a card if he's under 9 but could split" do 
      player.cards = [card(3), card(3)]
      expect(player).to_not be_must_hit
      expect(player.possible_actions).to eq([:split!, :hit!, :stand!])
    end

    it "won't autoreceive a card if he's over 8" do 
      player.cards = [card(5), card(4)]
      expect(player).to_not be_must_hit
      player.cards = [card(5), card(9)]
      expect(player).to_not be_must_hit
    end

    it "will not finish if he's under 21" do 
      player.cards = [card(3), card(3)]
      player.hit!
      expect(player).to be_can_hit
      expect(player).to_not be_finished
    end

    it "will finish if he's 21" do 
      player.cards = [card(8), card(3)]
      player.hit! # a Queen is coming
      expect(player).to_not be_can_hit
      expect(player).to be_finished
    end

    it "will finish if he busted" do 
      player.cards = [card(7), card(5)]
      player.hit! # a Queen is coming. 12+10 = 22
      expect(player).to_not be_can_hit
      expect(player).to be_busted
      expect(player).to be_finished
    end

    it "can hit if he's under 21" do 
      player.cards = [card("3"), card("2")]
      player.hit! # a queen
      expect(player).to be_can_hit
      player.hit! # a 2
      expect(player).to be_can_hit
      player.hit! # a queen. he's busted now (27)
      expect(player).to_not be_can_hit
    end

    it "can't hit if he's busted" do 
      player.cards = [card("K"), card("K")]
      player.hit! # it's a queen
      expect(player).to_not be_can_hit
    end

    it "raises an exception if he tries to hit again" do 
      allow(player).to receive(:can_hit?) { false }
      expect { player.hit! }.to raise_error("can't hit anymore")      
    end

    it "can't hit once he finished" do 
      player.cards = [card("A"), card("2")]
      player.stand!
      expect(player).to_not be_can_hit
    end

    it "can't hit on a Blackjack" do 
      player.cards = [card("A"), card("K")]
      expect(player).to_not be_can_hit
    end

    it "can't hit if all previous players haven't finished" do 
      game = Redjack::Game.new(seed: 1234, bets: [100,100], balance: 200)
      last_player = game.players.last
      expect { last_player.hit! }.to raise_error("waiting for previous player to finish")      
      game.players.first.stand!
      last_player.hit! # no exception anymore
    end    
  end

  describe "standing" do 
    it "will finish his game" do 
      player.stand!
      expect(player).to be_finished
    end

    it "can't stand if he has 21 as he already is finished" do 
      player.cards = [card(9), card("2")]
      player.hit! # a Queen is coming
      expect(player).to be_finished
      expect(player).to_not be_can_hit
    end
    
    it "can't stand if he has a Blackjack as he already is finished" do 

      expect(bj_player).to be_blackjack
      expect(bj_player).to be_finished
      expect(bj_player).to_not be_can_stand
    end

    it "can't stand if he stands already" do 
      player.stand!
      expect(player).to_not be_can_stand
    end

    it "can't stand if he is busted" do 
      player.cards = [card(10), card(10)]
      player.hit!
      expect(player).to_not be_can_stand
    end
  end
  
  describe "splitting" do 

    it "can split if both cards are 8 8" do 
      player.cards = [card(8), card(8)]
      expect(player).to be_can_split
      expect(player.possible_actions).to include(:split!)
    end

    it "can split if both cards are ten values" do 
      player.cards = [card("K"), card("J")]
      expect(player).to be_can_split
      expect(player.possible_actions).to include(:split!)
    end

    it "can't split if he doesn't have enough balance" do 
      player.cards = [card(8), card(8)]
      player.amount = 100
      game.balance = 0
      expect(player).to_not be_can_split
      expect(player.possible_actions).to_not include(:split!)
    end    

    it "can't split 3 same cards" do 
      player.cards = [card(8), card(8), card(8)]
      expect(player).to_not be_can_split
    end

    it "can't split non equaling cards" do 
      player.cards = [card(8), card(7)]
      expect(player).to_not be_can_split
    end

    it "creates a new hand with the second card" do 
      player.cards = [card(8, "hearts"), card(8, "diamonds")]
      next_card(2, "spades")

      assert_difference("game.players.count" => +1) do 
        player.split!
      end
      new_player = game.players.last
      
      expect(player.cards.count).to eq(2) # the player auto hits
      expect(player.cards).to eq([card(8, "hearts"), card(2, "spades")])
      
      expect(new_player.cards.count).to eq(1)
      expect(new_player.cards).to eq([card(8, "diamonds")])
    end

    it "flags both players as splitted" do 
      expect(player).to_not be_splitted
      player.cards = [card(8, "hearts"), card(8, "diamonds")]
      player.split!
      expect(game.players.all?(&:splitted?)).to be true
    end

    it "raises an exception if he tries to split and can't" do 
      allow(player).to receive(:can_split?) { false }
      expect { player.split! }.to raise_error("can't split")      
    end

    it "creates a new hand with the same amount" do 
      player.cards = [card(5), card(5)]
      assert_difference("game.balance" => -100, "player.amount" => 0, "game.players.count"=>+1)  do 
        player.split!
      end      
      expect(game.players.all?{|player| player.amount == 100}).to be true
    end
  end

  describe "doubling" do 
    it "can double a 9" do
      player.cards = [card(5), card(4)]
      expect(player).to be_can_double
      expect(player.possible_actions).to include(:double!)
    end
    
    it "can double a 10" do
      player.cards = [card(5), card(5)]
      expect(player).to be_can_double
      expect(player.possible_actions).to include(:double!)
    end
    
    it "can double a 11" do
      player.cards = [card(7), card(4)]
      expect(player).to be_can_double
      expect(player.possible_actions).to include(:double!)
    end

    it "can't double if he doesn't have enough balance" do 
      player.cards = [card(5), card(5)]
      game.balance = 0
      expect(player).to_not be_can_double
    end

    it "deducted the double from the balance" do 
      # game was 500 balance. -100 to start and another -100 for double should be 300 left
      player.cards = [card(5), card(5)]
      player.double!
      expect(game.balance).to eq(300)
    end

    it "doubles the amount of the hand and deducts it from the game" do 
      player.cards = [card(5), card(5)]
      assert_difference("game.balance" => -100, "player.amount" => +100)  do 
        player.double!
      end      
    end

    it "is finished after a double" do 
      player.cards = [card(5), card(5)]
      player.double!
      expect(player).to be_finished
      expect(player.possible_actions).to be_empty
    end

    it "can't double again" do 
      player.cards = [card(5), card(5)]
      player.double!
      expect(player).to_not be_can_double
      expect(player.possible_actions).to_not include(:double!)
      expect { player.double! }.to raise_error("can't double")      
    end

    it "can double after a split" do 
      game.balance = 200
      player.amount = 50
      next_card(6)
      next_card(10)
      next_card(6)
      player.cards = [card(5), card(5)]
      player.split!
      expect(player).to be_can_double
      expect(player.amount).to eq(50)
      player.double!
      expect(player.amount).to eq(100)
      # we had 200. we took 50 out to split. balance is 150
      # then we doubled that box (50+50), so new balance is 100
      expect(game.balance).to eq(100)
      expect(player).to be_finished      
    end
    
    it "can't double with any 3 cards" do 
      player.cards = [card(3), card(3), card(3)]
      expect(player).to_not be_can_double
    end

    it "doesn't have Blackjack with splitting aces" do 
      player.cards = [card("A"), card("A")]
      next_card("K")
      next_card(10)
      player.split!
      # player receives automatically a new card which makes him finished
      next_player = game.players.last
      # next player still needs to hit!
      next_player.hit!
      
      expect(game.players.all?(&:finished?)).to be true
      expect(game.players.all?{|player| player.points == 21 }).to be true
      expect(game.players.none?(&:blackjack?)).to be true
    end

    it "can't double a Ace with a King (21, not 11) after split" do 
      game.balance = 100
      player.cards = [card("A"), card("A")]
      next_card("K")
      next_card(10)
      player.split!
      next_player = game.players.last
      next_player.hit!
      expect(next_player).to_not be_can_double
    end
  end

  describe "scoring" do 
    it "won with BJ if bank doesn't have one" do 
      player.cards = [card("A"), card("K")]
      game.dealer.cards = [card("K"), card("K")]
      player.finish!
      expect(player).to be_won_with_blackjack
      expect(player.status).to eq(:blackjack)
    end
  end
end


# # 349 is player and dealer Blackjack
# a = 1000.times.collect do |i|
#   deck = Redjack::Deck.new(1, i)

#   if [deck.cards[0], deck.cards[2]].sum(&:points) == 21 && [deck.cards[1], deck.cards[3]].sum(&:points) == 21
#     i
#   end
# end