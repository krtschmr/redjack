RSpec.describe Redjack::Game do

	let(:game) { Redjack::Game.new(seed: 1234, balance: 500, bets: [100]) }
  let(:player) { game.current_player }

	it "should succeed" do
		
	end

	describe "should not throw a bug anymore" do 
		it "case1" do 
			# player one has a 5 2 and then auto hits a 3. he should also hit another card automatically as he can't bust
			# the next card would be a 7 for a total of 17
			game = Redjack::Game.new(seed: 70110878557887557551041208286687180, balance: 1000, bets: [20,20], ) #actions: [:split!, :stand!, :stand!])
			expect(game.players[0].cards.count).to eq(4)
			expect(game.players[0].points).to eq(17)
			
		end
	end

	describe "balance" do 

		it "can't start with enough balance" do 
			expect{ Redjack::Game.new(balance: 100, bets: [101])}.to raise_error("not enough balance to start game")      
		end

		it "deducts the initial bets from the balance" do 
			game = Redjack::Game.new(balance: 100, bets: [100])
			expect(game.balance).to eq(0)
		end

		it "has the correct balance after a split" do 
			player.cards = [card(8), card(8)]			
			player.split!
			expect(game.balance).to eq(300)
		end
		
		it "has the correct balance after a double" do 
			player.cards = [card(8), card(2)]			
			player.double!
			expect(game.balance).to eq(300)
		end
		
		it "has the correct balance after a split and double" do 
			player.cards = [card(8), card(8)]			
			next_card(10)
			next_card(3)
			next_card(8)
			next_card(3)
			game.split! # now 2 boxes each 100, he should get the 3 on his 8, makes it 11.
			game.double! # receiving an 8 for 19 and auto stand. should auto put another card on top of the other box
			game.current_player.double! # if we call game.double then dealer would autoplay
			# 2 boxes each 100 doubled is 400 total in play.
			expect(game.balance).to eq(100)
			expect(game.in_play).to eq(400)
		end
	end

	describe "preload actions" do 
		it "stand! was executed and the game is finished" do 
			game = Redjack::Game.new(seed: 203, balance: 500, bets: [100], actions: [:stand!])
			expect(game.players.first).to be_finished
			expect(game.actions).to eq([:stand!])
			expect(game).to be_finished
		end
	end

	describe "ending_balance" do 

		it "lost 100" do 
			game.hit! # he busts with 30 points
			expect(game.start_balance).to eq(500)
			expect(game.ending_balance).to eq(400)
		end

		it "won 150 with a blackjack" do 
			game = Redjack::Game.new(seed: 8, balance: 500, bets: [100]) # 10, Q, A. so player gets a BJ
			expect(game.players.first).to be_blackjack
			expect(game.dealer).to_not be_blackjack
			expect(game.start_balance).to eq(500)
			expect(game.ending_balance).to eq(650)
		end

		it "won 0 (push) with BJ vs BJ" do 
			game = Redjack::Game.new(seed: 349, balance: 500, bets: [100])
			expect(game.players.first).to be_blackjack
			expect(game.dealer).to be_blackjack
			expect(game.start_balance).to eq(500)
			expect(game.ending_balance).to eq(500)
		end

		it "won 0 (push) with 20 vs 20" do 
			game = Redjack::Game.new(seed: 54, balance: 500, bets: [100])
			game.stand!
			expect(game.players.first.points).to eq(20)
			expect(game.dealer.points).to eq(20)			
			expect(game.start_balance).to eq(500)
			expect(game.ending_balance).to eq(500)
		end
		
		it "lost 100 with 20 vs BJ" do 
			game = Redjack::Game.new(seed: 50, balance: 500, bets: [100])
			game.stand!
			expect(game.players.first.points).to eq(20)
			expect(game.dealer.points).to eq(21)
			expect(game.start_balance).to eq(500)
			expect(game.ending_balance).to eq(400)
		end
		
		it "lost 100 with 18 vs 19" do 
			game = Redjack::Game.new(seed: 47, balance: 500, bets: [100])
			game.stand!
			expect(game.players.first.points).to eq(18)
			expect(game.dealer.points).to eq(19)			
			expect(game.start_balance).to eq(500)
			expect(game.ending_balance).to eq(400)
		end

		it "lost 0 (push) with 18 vs 18" do 
			game = Redjack::Game.new(seed: 384, balance: 500, bets: [100])
			game.stand!
			expect(game.players.first.points).to eq(18)
			expect(game.dealer.points).to eq(18)
			expect(game.start_balance).to eq(500)
			expect(game.ending_balance).to eq(500)
		end
		
		it "won 100 with 13 vs 22" do 
			game = Redjack::Game.new(seed: 203, balance: 500, bets: [100])
			game.stand!
			expect(game.players.first.points).to eq(13)
			expect(game.dealer.points).to eq(22)
			expect(game.start_balance).to eq(500)
			expect(game.ending_balance).to eq(600)
		end
		
		it "has the correct balance after winning a splitted box where both doubled" do 
			player.cards = [card(8), card(8)]			
			next_card(10)
			next_card(3)
			next_card(8)
			next_card(3)
			game.split! # now 2 boxes each 100, he should get the 3 on his 8, makes it 11.
			game.double! # receiving an 8 for 19 and auto stand. should auto put another card on top of the other box
			game.double!

			# dealer makes a 17
			# 500 in and 400 in play which one, should be 900
			expect(game.ending_balance).to eq(900)
		end

		it "has the correct balance after splitting twice and losing both" do 
			game.dealer.cards = [card(5)]
			player.cards = [card(8), card(8)]			
			next_card(6)
			next_card(10)
			next_card("A")
			next_card("A")
			game.split! # 2 boxes with each an 8
			game.stand! # get an Ace for 19 and stand
			game.stand! # received another Ace for 19 and stands
			# dealer receives (5) + 10 and 6 for 21
			expect(game.start_balance).to eq(500)
			expect(game.ending_balance).to eq(300)
		end
	end
end