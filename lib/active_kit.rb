require "active_kit/version"
require "active_kit/engine"

module ActiveKit
  extend ActiveSupport::Autoload

  autoload :Activekiter
  autoload :Loader
  autoload :Relation
  autoload :Sequence
end
