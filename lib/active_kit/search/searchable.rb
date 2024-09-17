require 'active_support/concern'

module ActiveKit
  module Search
    module Searchable
      extend Bedrock::Bedrockable
      extend ActiveSupport::Concern

      included do
      end

      class_methods do
      end
    end
  end
end
