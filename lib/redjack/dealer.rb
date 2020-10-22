module Redjack
  class Dealer < Player
    def initialize(game, options={})
      self.game = game
      self.cards = []
      self.finished = false
      self.splitted = options.fetch(:splitted, false)
    end

    # :nocov:
    def inspect
      "<Dealer# (#{finished? ? points: "?"}): #{cards.collect(&:inspect).join(" ")} >"
    end
    # :nocov:

    def can_split?
      false
    end

    def can_double?
      false
    end

    def can_stand?
      false
    end

    def must_hit?
      points < 17 || (points == 17 && cards.one?(&:ace?))
    end

    def can_play?
      game.players.all?(&:finished?)
    end

    def finish!
      super
      game.send(:finish!) #only the dealer can finish the game, it's private method
    end

    def play!
      raise "players haven't finished" unless can_play?
      while(must_hit?) do 
        self.cards << game.deck.draw
        if blackjack? || points==21 || busted?
          return finish! 
        end        
      end
      finish!
      true      
    end
  end
end