module ActiveKit
  module Search
    class Searcher < Bedrock::Bedrocker
      def create_attribute(name, options)
        describer_names = super

        depends_on = options.delete(:depends_on) || {}
        describer_names.each do |describer_name|
          set_callbacks(describer_name, depends_on)
          self.for(describer_name).add_attribute(name: name, options: options.deep_dup)
        end
      end

      def describer_method(describer, params)
        params[:page] = 1 if params.key?(:page) && params[:page].blank?
        self.for(describer.name).fetch(term: params.delete(:term), **params).records
      end

      private

      # Set callbacks for depending classes and then current class.
      def set_callbacks(describer_name, depends_on)
        depends_on.each do |depends_on_association, depends_on_inverse|
          klass = @current_class.reflect_on_all_associations.map { |assoc| [assoc.name, assoc.klass.name] }.to_h[depends_on_association]

          next if klass.constantize.private_method_defined?(after_commit_depends_callback_method_name(describer_name))
          klass.constantize.class_eval <<-CODE, __FILE__, __LINE__ + 1
            after_commit :#{after_commit_depends_callback_method_name(describer_name)}

            private

            def #{after_commit_depends_callback_method_name(describer_name)}
              inverse_assoc = self.public_send("#{depends_on_inverse}")
              if inverse_assoc.respond_to?(:each)
                inverse_assoc.each do |instance|
                  if instance.class.name == "#{@current_class.name}"
                    instance.class.searcher.for("#{describer_name}").reload(record: instance)
                  end
                end
              else
                if inverse_assoc.class.name == "#{@current_class.name}"
                  inverse_assoc.class.searcher.for("#{describer_name}").reload(record: inverse_assoc)
                end
              end
              logger.info "ActiveKit::Search | Indexing Done. (Class: " + self.class.name + " | Reloading: #{@current_class.name} | Describer: #{describer_name})"
            end
          CODE
        end

        return if @current_class.private_method_defined?(after_commit_callback_method_name(describer_name))
        @current_class.class_eval <<-CODE, __FILE__, __LINE__ + 1
          after_commit :#{after_commit_callback_method_name(describer_name)}

          private

          def #{after_commit_callback_method_name(describer_name)}
            self.class.searcher.for("#{describer_name}").reload(record: self)
            logger.info "ActiveKit::Search | Indexing Done. (Class: " + self.class.name + " | Reloading: #{@current_class.name} | Describer: #{describer_name})"
          end
        CODE
      end

      def after_commit_callback_method_name(describer_name)
        "#{callback_method_name(describer_name)}_callback"
      end

      def after_commit_depends_callback_method_name(describer_name)
        "#{callback_method_name(describer_name)}_depends_callback"
      end

      def callback_method_name(describer_name)
        "activekit_search_#{@current_class.model_name.singular}_#{describer_name}"
      end
    end
  end
end
