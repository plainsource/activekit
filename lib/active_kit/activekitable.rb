require 'active_support/concern'
require "active_kit/sequence/sequenceable"

module ActiveKit
    module Activekitable
      extend ActiveSupport::Concern
      include ActiveKit::Sequence::Sequenceable

      included do
      end

      class_methods do
      end
    end
end
