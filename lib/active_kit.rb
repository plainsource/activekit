require "active_kit/version"
require "active_kit/engine"

module ActiveKit
  extend ActiveSupport::Autoload

  autoload :Base
  autoload :Sequence
end
