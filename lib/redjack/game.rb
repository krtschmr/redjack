module Redjack
  class Game
    attr_accessor :seed
    attr_accessor :amount_decks
    attr_accessor :options
    attr_accessor :players
    attr_accessor :dealer    
    attr_accessor :actions
    attr_accessor :deck
    attr_accessor :balance
    attr_accessor :finished
    attr_accessor :bets
    
    def initialize(args={})
      self.bets = args.fetch(:bets)
      self.balance = args.fetch(:balance, 0)
      raise ArgumentError.new("not enough balance to start game") if balance < bets.sum
      
      self.seed = args.fetch(:seed, rand(100_000_000))
      self.amount_decks = args.fetch(:amount_decks, 1)
      self.actions = []
      prepare
      load_actions(args.delete(:actions) || [])
    end
    
    def in_play
      players.sum(&:amount)
    end

    def start_balance
      balance + players.sum(&:amount)
    end

    def ending_balance
      raise "game not finished" unless finished?
      balance + players.sum(&:ending_balance)
    end

    def profit
      ending_balance - start_balance
    end

    def current_player
      players.detect(&:playing?)
    end

    def possible_actions
      current_player&.possible_actions
    end

    def hit!
      execute_action(:hit!) if current_player&.can_hit?
    end

    def stand!
      execute_action(:stand!) if current_player&.can_stand?
    end

    def double!
      execute_action(:double!) if current_player&.can_double? 
    end
    
    def split!
      execute_action(:split!) if current_player&.can_split?
    end

    def finished?
      finished
    end

    def all_players_finished?
      players.all?(&:finished?)
    end
    
    def reindex_players!
      players.each_with_index {|player, index| player.position = index}
    end

    private 

    def load_action(action)
      send(action)
    end

    def give_out_cards
      players.each(&:take_card!)
      dealer.take_card!
      players.each(&:take_card!)      
      autoplay_if_neccessary!
    end

    def execute_action(method)
      current_player.send(method)
      self.actions << method
      autoplay_if_neccessary!
    end

    def finish!
      self.finished = true
    end

    def load_actions(actions)
      actions.compact.each do |action|
        load_action(action)
      end
    end
    
    def autoplay_if_neccessary!
      current_player.take_card! if current_player&.must_hit?
      dealer.play! if all_players_finished?
    end

    def prepare
      self.deck = Deck.new(amount_decks, seed)
      initialize_players
      give_out_cards          
    end

    def initialize_players
      self.players = bets.collect{ |amount| Player.new(self, amount) }
      self.dealer = Dealer.new(self)
      reindex_players!
    end

  end
end