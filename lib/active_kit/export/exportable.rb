require 'active_support/concern'

module ActiveKit
  module Export
    module Exportable
      extend ActiveSupport::Concern

      included do
      end

      class_methods do
        def exporter
          @exporter ||= ActiveKit::Export::Exporter.new(current_class: self)
        end

        def export_describer(name, **options)
          exporter.create_export_describer(name, options)
        end

        def export_attribute(name, **options)
          exporter.create_export_attribute(name, options)
        end
      end
    end
  end
end
