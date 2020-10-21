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
      self.seed = args.fetch(:seed)
      self.bets = args.fetch(:bets)
      self.amount_decks = args.fetch(:amount_decks, 1)
      self.balance = args.fetch(:balance, 0)
      self.actions = []
      prepare
      load_actions(args.delete(:actions) || [])
    end

    def prepare
      self.deck = Deck.new(amount_decks, seed)
      initialize_players
      give_out_cards    
      # one special case: all players have a BJ, then it's dealers turn
      dealer.play! if all_players_finished?  
    end

    def initialize_players
      self.players = bets.collect{ |amount| Player.new(self, amount) }
      self.dealer = Dealer.new(self)
      reindex_players!
    end

    def reindex_players!
      players.each_with_index {|player, index| player.position = index}
    end
    
    def load_actions(actions)
      actions.compact.each do |action|
        load_action(action)
      end
    end

    def current_player
      players.detect(&:playing?)
    end

    def possible_actions
      current_player&.possible_actions
    end

    def load_action(action)
      send(action)
    end

    def give_out_cards
      players.each(&:take_card!)
      dealer.take_card!
      players.each(&:take_card!)      
    end

    def american_rules?
      false
    end

    def hit!
      if current_player&.hit!
        self.actions << :hit!
        hit! if current_player&.must_hit?
        true
      end
    end

    def stand!
      if current_player&.stand!
        self.actions << :stand!
        hit! if current_player&.must_hit?
        dealer.play! if all_players_finished?
        true
      end
    end

    def double!
      if current_player&.double!
        self.actions << :double!
        hit! if current_player&.must_hit?
        dealer.play! if all_players_finished?
        true
      end
    end
    
    def split!
      if current_player.split!
        self.actions << :split!
        hit! if current_player&.must_hit?
        true
      end
    end

    def finish!
      self.finished = true
    end

    def finished?
      finished
    end

    def all_players_finished?
      players.all?(&:finished?)
    end

  end
end