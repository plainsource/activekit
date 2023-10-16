module ActiveKit
  class Engine < ::Rails::Engine
    isolate_namespace ActiveKit
    config.eager_load_namespaces << ActiveKit

    initializer "active_kit.sequence" do
      require "active_kit/sequence/sequenceable"

      ActiveSupport.on_load(:active_record) do
        include ActiveKit::Sequence::Sequenceable
      end
    end
  end
end
