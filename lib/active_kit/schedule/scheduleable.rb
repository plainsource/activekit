require 'active_support/concern'

module ActiveKit
  module Schedule
    module Scheduleable
      extend ActiveSupport::Concern

      included do
      end

      class_methods do
        # Usage Options
        # schedule_attribute :name, :run_method, :begin_at, :end_at
        # schedule_attribute :name, :run_method, :timestamp_method, updater: {}
        # schedule_attribute :name, :run_method, :timestamp_method, updater: { on: {} }
        # schedule_attribute :name, :run_method, :timestamp_method, updater: { via: :assoc, on: {} }
        # schedule_attribute :name, :run_method, :timestamp_method, updater: { via: {}, on: {} }
        # Note: :on and :via in :updater can accept nested associations.
        def schedule_attribute(name, run_method, timestamp_method, interval, **options)
          ActiveKit::Base::Ensure.setup_for!(current_class: self)

          name = name.to_sym
          options.store(:run_method, run_method&.to_sym)
          options.store(:timestamp_method, datetime_method&.to_sym)
          options.deep_symbolize_keys!

          set_activekit_schedule_callbacks(name: name, options: options)
          activekiter.schedule.add_attribute(name: name, options: options)
        end
      end
    end
  end
end
