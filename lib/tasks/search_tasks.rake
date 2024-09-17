namespace :active_kit do
  namespace :search do
    desc "bundle exec rails active_kit:search:reload CLASS='Article' DESCRIBER='limit_by_search'"
    task :reload do
      manager = ActiveKit::Search::Manager.new(given_class: ENV['CLASS'], given_describer: ENV['DESCRIBER'])
      manager.reload
    end

    desc "bundle exec rails active_kit:search:clear CLASS='Article' DESCRIBER='limit_by_search'"
    task :clear do
      manager = ActiveKit::Search::Manager.new(given_class: ENV['CLASS'], given_describer: ENV['DESCRIBER'])
      manager.clear
    end

    desc "bundle exec rails active_kit:search:drop CLASS='Article' DESCRIBER='limit_by_search'"
    task :drop do
      manager = ActiveKit::Search::Manager.new(given_class: ENV['CLASS'], given_describer: ENV['DESCRIBER'])
      manager.drop
    end
  end
end
