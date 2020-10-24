module Redjack
  class Player
    attr_accessor :splitted
    attr_accessor :game
    attr_accessor :cards
    attr_accessor :finished
    attr_accessor :position
    attr_accessor :amount

    def initialize(game, amount, options={})
      self.game = game
      self.cards = []
      self.finished = false
      self.amount = amount
      self.splitted = options.fetch(:splitted, false)
      game.balance -= amount
    end

    # :nocov:
    def inspect
      "<Player##{position} (#{points}): #{cards.collect(&:inspect).join(" ")} possible_actions: #{possible_actions}>"
    end
    # :nocov:

    def his_turn?
      previous_players.all?(&:finished?)
    end

    def previous_players
      game.players.select{|other| other.position < position}
    end

    def finish!
      raise "already finished" if finished?
      self.finished = true
      points # do we need this?
    end

    def his_turn?
      game.current_player == self
    end

    def waiting?
      !finished && !his_turn?
    end

    def playing?
      !finished?
    end

    def finished?
      finished
    end

    def busted?
      points > 21
    end

    def must_hit?
      !can_split? && !can_double? && points < 11
    end

    def blackjack?
      cards.count == 2 && points == 21 && !splitted?
    end

    def can_hit?
      his_turn? && !finished? && points <= 20
    end

    def can_stand?
      !finished?
    end

    def can_split?
      !splitted? && !finished? && cards.count == 2 && cards.first.points == cards.last.points && enough_balance_available?
    end

    def can_double?
      !splitted_aces? && !finished? && cards.count == 2 && [9,10,11].include?(points) && enough_balance_available?
    end

    def splitted?
      splitted
    end

    def splitted_aces?
      splitted? && cards.first.ace?
    end

    def won_with_blackjack?
      blackjack? && !game.dealer.blackjack?
    end

    def enough_balance_available?
      game.balance >= amount
    end

    def ending_balance
      raise "game not finished" unless game.finished?
      case status
      when :blackjack
        amount + amount*1.5
      when :win
        amount + amount
      when :push 
        amount
      else
        0
      end
    end

    def result
    end

    def take_card!
      raise "must hit! instead of taking a card" if cards.count >= 2 && !must_hit?
      # the initial card round
      self.cards << game.deck.draw
      finish!  if blackjack?
    end

    def hit!
      raise "waiting for previous player to finish" unless his_turn?
      if can_hit?
        card = game.deck.draw
        self.cards << card
        if blackjack? || points==21 || busted?
          finish! 
        else
          points
        end        
      else
        raise "can't hit anymore"
      end
    end
    
    def stand!
      finish!
    end

    def points
      total = cards.sum(&:points)
      if total > 21 && cards.any?(&:ace?)
        # check if we can count some aces as a 1 to be still good

        cards.count(&:ace?).times do
          total -= 10
          return total if total <= 21
        end
      end
      total
    end

    def possible_actions
      candidates = []
      if can_hit?
        candidates << :split! if can_split?
        candidates << :double! if can_double?      
        candidates << :hit! 
        candidates << :stand!
      end
      candidates
    end

    def double!
      raise "can't double" unless can_double?
      game.balance -= amount
      self.amount += amount
      hit! 
      if !finished?
        stand!
      end
    end

    def split!
      raise "can't split" unless can_split?
      # take the second card and make it a new hand
      # and reindex_players all the other hands
      new_player = Player.new(game, amount, splitted: true)
      new_player.cards << cards.pop
      # insert in the hand behind him
      game.players.insert(position+1, new_player)
      game.reindex_players!
      hit!
      self.splitted = true
    end

    # :nocov:
    def status
      return :playing if his_turn?
      return :waiting if waiting?      
      return :busted if busted?
      return :blackjack if won_with_blackjack?
      return :waiting_for_dealer unless game.dealer.finished?
      return :push if points == game.dealer.points
      return :win if !busted? && points > game.dealer.points || game.dealer.busted?
      :lose
    end
    # :nocov:
  end
end