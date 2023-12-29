module ActiveKit
  module Position
    class Positioning
      BASE = 36

      def initialize
        @initial_tier = "t0"
        @initial_spot = "00"
        @initial_slot = "hz"
      end

      def chair_first
        chair(@initial_tier, @initial_spot, @initial_slot)
      end

      def chair_at(no:, increase_length_by: 0)
        nicespot = no.to_s(BASE)
        nicespot = nicespot.rjust(nicespot.length + increase_length_by, "0")
        chair(@initial_tier, nicespot, @initial_slot)
      end

      def chair_above(currvalue:)
        currtier, currspot = currvalue.split("|").take(2)
        nicespot = (currspot.to_i(BASE) - 1).to_s(BASE).rjust(currspot.length, "0")
        nicespot = firstspot(currspot) if nicespot.to_i(BASE) == 0
        chair(currtier, nicespot, @initial_slot)
      end

      def chair_below(currvalue:)
        currtier, currspot = currvalue.split("|").take(2)
        nicespot = (currspot.to_i(BASE) + 1).to_s(BASE).rjust(currspot.length, "0")
        nicespot = finalspot(currspot) if nicespot.to_i(BASE) > finalspot(currspot).to_i(BASE)
        chair(currtier, nicespot, @initial_slot)
      end

      def stool_above(currvalue:, prevvalue:)
        currtier, currspot, currslot = currvalue.split("|")
        prevtier, prevspot, prevslot = prevvalue.split("|") if prevvalue
        stool(currtier, currspot, firstslot(currtier, prevtier, currspot, prevspot, prevslot), currslot)
      end

      def stool_below(currvalue:, nextvalue:)
        currtier, currspot, currslot = currvalue.split("|")
        nexttier, nextspot, nextslot = nextvalue.split("|") if nextvalue
        stool(currtier, currspot, currslot, finalslot(currtier, nexttier, currspot, nextspot, nextslot))
      end

      private

      def firstspot(currspot)
        "0".rjust(currspot.length, "0")
      end

      def finalspot(currspot)
        "z".rjust(currspot.length, "z")
      end

      def firstslot(currtier, prevtier, currspot, prevspot, prevslot)
        currtier == prevtier && currspot == prevspot ? prevslot : "00"
      end

      def finalslot(currtier, nexttier, currspot, nextspot, nextslot)
        currtier == nexttier && currspot == nextspot ? nextslot : "zz"
      end

      def chair(tier, spot, slot)
        ["#{tier}|#{spot}|#{slot}", chairs_almost_over?(spot)]
      end

      def stool(tier, spot, slot_small, slot_big)
        avg_slot = ((slot_big.to_i(BASE) + slot_small.to_i(BASE)) / 2).to_s(BASE).rjust(slot_big.length, "0")
        ["#{tier}|#{spot}|#{avg_slot}", stools_almost_over?(slot_small, slot_big)]
      end

      def chairs_almost_over?(spot)
        finalspot(spot).to_i(BASE) - spot.to_i(BASE) <= 10
      end

      # Careful, when 'true' stools are much less than 10 because of division by 2 to get the next stool.
      def stools_almost_over?(slot_small, slot_big)
        (slot_big.to_i(BASE) - slot_small.to_i(BASE)) <= 10
      end
    end
  end
end
