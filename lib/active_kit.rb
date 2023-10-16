require "active_kit/version"
require "active_kit/engine"

module ActiveKit
  extend ActiveSupport::Autoload

  autoload :Sequencer, "active_kit/sequence/sequencer"
  autoload :Wordbook, "active_kit/sequence/wordbook"
end
