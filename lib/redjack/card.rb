module Redjack
  class Card < Struct.new(:rank, :suit)
    # :nocov:
    def inspect
      "#{rank}#{suit[0]}"
    end
    # :nocov:

    # :nocov:
    def to_s
      "#{rank} of #{suit}"
    end
    # :nocov:

    def ace?
      rank == "A"
    end

    def points
      if ace?
        11
      else
        # if it's not a number, it's a 10
        (rank.is_a?(Integer) || rank.to_i != 0) ? rank.to_i : 10
      end
    end
  end
end