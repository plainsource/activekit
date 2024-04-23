module ActiveKit
  module Export
    class Exporter < Bedrock::Bedrocker
      def new_exporting(describer:)
        Exporting.new(describer: describer)
      end
    end
  end
end
