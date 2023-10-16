module ActiveKit
  class Engine < ::Rails::Engine
    isolate_namespace ActiveKit
    config.eager_load_namespaces << ActiveKit

    initializer "active_kit.activekitable" do
      require "active_kit/activekitable"

      ActiveSupport.on_load(:active_record) do
        include ActiveKit::Activekitable

        has_one :activekit, as: :record, dependent: :destroy, class_name: "ActiveKit::Attribute"
      end
    end
  end
end
