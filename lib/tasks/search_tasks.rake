namespace :active_kit do
  desc "bundle exec rails active_kit:boot DOMAIN='www.yourdomain.com'"
  task boot: [:environment] do
    # Database & Preferences
    domain = ENV['DOMAIN'] || raise("DOMAIN not specified")

    tenant = nil
    shard_name = nil

    # Returns the first db config for a specific environment where it is assumed that all tenants data is stored.
    default_shard_name = ActiveRecord::Base.configurations.find_db_config(Rails.env).name

    ActiveRecord::Base.connected_to(role: :writing, shard: default_shard_name.to_sym) do
      tenant = System::Tenant.where(domain: domain).or(System::Tenant.where(custom_domain: domain)).select(:database, :storage, :domain, :custom_domain).first
      shard_name = tenant.database
      raise RuntimeError, 'Could not set shard name.' unless shard_name.present? # TODO: In future, redirect this to "Nothing Here Yet" page
    end

    ApplicationRecord.connects_to database: { writing: "#{shard_name}".to_sym }

    System::Current.tenant = OpenStruct.new(tenant.serializable_hash)
    System::Current.preferences = System::Preference.revealed
    System::Current.integrations = System::Integration.revealed
  end

  namespace :search do
    desc "bundle exec rails active_kit:search:reload CLASS='Article' DOMAIN='www.yourdomain.com'"
    task reload: [:boot] do
      if ENV['CLASS']
        if ENV['CLASS'].constantize.searcher.attributes_present?
          puts "ActiveKit::Search | Reloading: #{ENV['CLASS']}"
          ENV['CLASS'].constantize.searcher.reload
        end
      else
        Rails.application.eager_load!
        models = ApplicationRecord.descendants.collect(&:name)
        models.each do |model|
          if model.constantize.searcher.attributes_present?
            puts "ActiveKit::Search | Reloading: #{model}"
            model.constantize.searcher.reload
          end
        end
      end
    end

    desc "bundle exec rails active_kit:search:clear CLASS='Article' DOMAIN='www.yourdomain.com'"
    task clear: [:boot] do
      if ENV['CLASS']
        if ENV['CLASS'].constantize.searcher.attributes_present?
          puts "ActiveKit::Search | Clearing: #{ENV['CLASS']}"
          ENV['CLASS'].constantize.searcher.clear
        end
      else
        Rails.application.eager_load!
        models = ApplicationRecord.descendants.collect(&:name)
        models.each do |model|
          if model.constantize.searcher.attributes_present?
            puts "ActiveKit::Search | Clearing: #{model}"
            model.constantize.searcher.clear
          end
        end
      end
    end

    desc "bundle exec rails active_kit:search:drop CLASS='Article' DOMAIN='www.yourdomain.com'"
    task drop: [:boot] do
      if ENV['CLASS']
        if ENV['CLASS'].constantize.searcher.attributes_present?
          puts "ActiveKit::Search | Dropping: #{ENV['CLASS']}"
          ENV['CLASS'].constantize.searcher.drop
        end
      else
        Rails.application.eager_load!
        models = ApplicationRecord.descendants.collect(&:name)
        models.each do |model|
          if model.constantize.searcher.attributes_present?
            puts "ActiveKit::Search | Dropping: #{model}"
            model.constantize.searcher.drop
          end
        end
      end
    end
  end
end
