module ActiveKit
  class Engine < ::Rails::Engine
    isolate_namespace ActiveKit
    config.eager_load_namespaces << ActiveKit

    initializer "active_kit.add_middleware" do |app|
      app.middleware.use ActiveKit::Middleware
    end

    initializer "active_kit.activekitable" do
      require "active_kit/activekitable"

      ActiveSupport.on_load(:active_record) do
        include ActiveKit::Activekitable
      end
    end
  end
end
