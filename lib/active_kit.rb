require "active_kit/version"
require "active_kit/engine"

module ActiveKit
  extend ActiveSupport::Autoload

  autoload :Loader
  autoload :Sequence
end
