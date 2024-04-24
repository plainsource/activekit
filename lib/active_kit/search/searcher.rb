module ActiveKit
  module Search
    class Searcher < Bedrock::Bedrocker
      def create_attribute(name, options)
        describer_names = super

        depends_on = options.delete(:depends_on) || {}
        describer_names.each do |describer_name|
          set_reload_callbacks(depends_on, describer_name)
          self.for(describer_name).add_attribute(name: name, options: options.deep_dup)
        end
      end

      def describer_method(describer, params)
        params[:page] = 1 if params.key?(:page) && params[:page].blank?
        self.for(describer.name).fetch(term: params.delete(:term), **params).records
      end

      private

      # Set callbacks for current class and depending classes.
      def set_reload_callbacks(depends_on, describer_name)
        @current_class.class_eval do
          unless searcher.for(describer_name).attributes_present?
            after_commit do
              self.class.searcher.for(describer_name).reload(record: self)
              logger.info "ActiveKit::Search | Indexing from #{self.class.name}: Done."
            end
          end

          unless depends_on.empty?
            depends_on.each do |depends_on_association, depends_on_inverse|
              klass = self.reflect_on_all_associations.map { |assoc| [assoc.name, assoc.klass.name] }.to_h[depends_on_association]
              klass.constantize.class_eval do
                after_commit do
                  inverse_assoc = self.public_send(depends_on_inverse)
                  if inverse_assoc.respond_to?(:each)
                    inverse_assoc.each { |instance| instance.class.searcher.for(describer_name).reload(record: instance) }
                  else
                    inverse_assoc.class.searcher.for(describer_name).reload(record: inverse_assoc)
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
