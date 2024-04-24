module ActiveKit
  module Search
    class Searcher < Bedrock::Bedrocker
      def create_attribute(name, options)
        super

        set_callbacks_for_attribute(name, options)
        self.for(nil).add_attribute(name: name, options: options)
      end

      def describer_method(describer, params)
        params[:page] = 1 if params.key?(:page) && params[:page].blank?
        self.for(nil).fetch(term: params.delete(:term), **params).records
      end

      private

      # Set callbacks for current class and depending classes.
      def set_callbacks_for_attribute(name, options)
        @current_class.class_eval do
          unless searcher.for(nil).attributes_present?
            after_commit do
              self.class.searcher.for(nil).reload(record: self)
              logger.info "ActiveKit::Search | Indexing from #{self.class.name}: Done."
            end
          end

          depends_on = options.delete(:depends_on) || {}
          unless depends_on.empty?
            depends_on.each do |depends_on_association, depends_on_inverse|
              klass = self.reflect_on_all_associations.map { |assoc| [assoc.name, assoc.klass.name] }.to_h[depends_on_association]
              klass.constantize.class_eval do
                after_commit do
                  inverse_assoc = self.public_send(depends_on_inverse)
                  if inverse_assoc.respond_to?(:each)
                    inverse_assoc.each { |instance| instance.class.searcher.for(nil).reload(record: instance) }
                  else
                    inverse_assoc.class.searcher.for(nil).reload(record: inverse_assoc)
                  end
                  logger.info "ActiveKit::Search | Indexing from #{self.class.name}: Done."
                end
              end
            end
          end
        end
      end
    end
  end
end
