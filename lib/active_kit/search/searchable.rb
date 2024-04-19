require 'active_support/concern'

module ActiveKit
  module Search
    module Searchable
      extend ActiveSupport::Concern

      included do
      end

      class_methods do
        def searcher
          @searcher ||= ActiveKit::Search::Search.new(current_class: self)
        end

        def searching(term: nil, **options)
          options[:page] = 1 if options.key?(:page) && options[:page].blank?
          searcher.fetch(term: term, **options).records
        end

        def search_attribute(name, **options)
          options.deep_symbolize_keys!

          set_activekit_search_callbacks unless searcher.attributes_present?
          depends_on = options.delete(:depends_on) || {}
          set_activekit_search_depends_on_callbacks(depends_on: depends_on) unless depends_on.empty?

          searcher.add_attribute(name: name, options: options)
        end

        def set_activekit_search_callbacks
          after_commit do
            self.class.searcher.reload(record: self)
            logger.info "ActiveKit::Search | Indexing from #{self.class.name}: Done."
          end
        end

        def set_activekit_search_depends_on_callbacks(depends_on:)
          depends_on.each do |depends_on_association, depends_on_inverse|
            klass = self.reflect_on_all_associations.map { |assoc| [assoc.name, assoc.klass.name] }.to_h[depends_on_association]
            klass.constantize.class_eval do
              after_commit do
                inverse_assoc = self.public_send(depends_on_inverse)
                if inverse_assoc.respond_to?(:each)
                  inverse_assoc.each { |instance| instance.class.searcher.reload(record: instance) }
                else
                  inverse_assoc.class.searcher.reload(record: inverse_assoc)
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




# require 'active_support/concern'

# module ActiveKit
#   module Search
#     module Searchable
#       extend ActiveSupport::Concern

#       included do
#       end

#       class_methods do
#         def searcher
#           @searcher ||= ActiveKit::Search::Searcher.new(current_class: self)
#         end

#         def search_describer(name, **options)
#           name = name.to_sym
#           options.deep_symbolize_keys!

#           unless searcher.find_describer_by(describer_name: name)
#             searcher.new_describer(name: name, options: options)
#             define_search_describer_method(kind: options[:kind], name: name)
#           end
#         end

#         def search_attribute(name, **options)
#           search_describer(:to_csv, kind: :csv, database: -> { ActiveRecord::Base.connection_db_config.database.to_sym }) unless searcher.describers?

#           options.deep_symbolize_keys!
#           searcher.new_attribute(name: name.to_sym, options: options)
#         end

#         def define_search_describer_method(kind:, name:)
#           case kind
#           when :csv
#             define_singleton_method name do
#               describer = exporter.find_describer_by(describer_name: name)
#               raise "could not find describer for the describer name '#{name}'" unless describer.present?

#               # The 'all' relation must be captured outside the Enumerator,
#               # else it will get reset to all the records of the class.
#               all_activerecord_relation = all.includes(describer.includes)

#               Enumerator.new do |yielder|
#                 ActiveRecord::Base.connected_to(role: :writing, shard: describer.database.call) do
#                   exporting = exporter.new_exporting(describer: describer)

#                   # Add the headings.
#                   yielder << CSV.generate_line(exporting.headings) if exporting.headings?

#                   # Add the values.
#                   # find_each will ignore any order if set earlier.
#                   all_activerecord_relation.find_each do |record|
#                     lines = exporting.lines_for(record: record)
#                     lines.each { |line| yielder << CSV.generate_line(line) }
#                   end
#                 end
#               end
#             end
#           end
#         end
#       end
#     end
#   end
# end
