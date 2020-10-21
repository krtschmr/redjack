RSpec.describe Redjack::Dealer do

  let(:game) { Redjack::Game.new(seed: 1234, balance: 100, bets: [100]) }
  let(:player) { game.players.first }
  let(:dealer) { game.dealer }

  let(:bj_game) { Redjack::Game.new(seed: 931, balance: 100, bets: [100]) } # 10 K 9 A. so dealer has 10, player 19 and dealer draws BJ
  let(:bj_dealer) { bj_game.dealer }

  it "can't stand" do 
    dealer.cards = [card("8"), card("7")]
    player.stand!
    expect(dealer).to_not be_can_stand
  end

  it "can't split" do 
    dealer.cards = [card("8"), card("8")]
    player.stand!
    expect(dealer).to_not be_can_split
  end

  it "can't double" do 
    dealer.cards = [card("2"), card("9")]
    player.stand!
    expect(dealer).to_not be_can_double 
  end

  describe "hitting" do 
    it "must hit on 16" do 
      dealer.cards = [card("8"), card("8")]
      expect(dealer).to be_must_hit
    end

    it "won't hit on 17" do 
      dealer.cards = [card("8"), card("9")]
      expect(dealer).to_not be_must_hit
    end

    it "must hit on soft 17" do 
      dealer.cards = [card("A"), card("6")]
      expect(dealer).to be_must_hit
    end

    it "won't hit on soft 18" do 
      dealer.cards = [card("A"), card("y")]
      expect(dealer).to_not be_must_hit
    end
  end

  describe "play!" do 
    it "can't play if players aren't finished yet" do 
      expect(dealer).to_not be_can_play
      expect { dealer.play! }.to raise_error("players haven't finished")      
    end

    it "will autoplay till he must stand or is bust" do 
      player.finish!
      dealer.cards = [card(2)]
      next_card(5)
      next_card(3)
      next_card(4)
      next_card(5)
      # we expect the dealer to hit 4 times.
      expect(game.deck).to receive(:draw).exactly(4).times.and_call_original
      dealer.play!      
      expect(dealer.points).to eq(19)
    end

    it "will stop on Blackjack" do 
      bj_game.players.first.finish!
      expect(bj_game.deck).to receive(:draw).once.and_call_original
      bj_dealer.play!
      expect(bj_dealer.points).to eq(21)
      expect(bj_dealer).to be_blackjack
    end
  end


end