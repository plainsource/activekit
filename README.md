# ActiveKit
Add the essential kit for rails ActiveRecord models and be happy.

## Usage

### Search Attribute

Add searching to your ActiveRecord models.
Search Attribute provides full searching functionality for your model database records using redis search including search suggestions.

You can define any number of model attributes in one model to search together.

Define the search attributes in accordance with the column name in your model like below.
```ruby
class Product < ApplicationRecord
  search_attribute :name, type: :text
  search_attribute :permalink, type: :tag
  search_attribute :short_description, type: :text
  search_attribute :published, type: :tag, sortable: true
end
```

You can also define a search_describer to describe the details of the search instead of using the defaults.
```ruby
class Product < ApplicationRecord
  # search_describer method_name, database: -> { ActiveRecord::Base.connection_db_config.database }
  search_describer :limit_by_search, database: -> { System::Current.tenant.database }
  search_attribute :name, type: :text
  search_attribute :permalink, type: :tag
  search_attribute :short_description, type: :text
  search_attribute :published, type: :tag, sortable: true
end
```

The following class methods will be added to your model class to use in accordance with details provided for search_describer:
```ruby
Product.limit_by_search(term: "term", tags: { published: true }, order: "name asc", page: 1)
Product.searcher.for(:limit_by_search).current_page
Product.searcher.for(:limit_by_search).previous_page?
Product.searcher.for(:limit_by_search).previous_page
Product.searcher.for(:limit_by_search).next_page?
Product.searcher.for(:limit_by_search).next_page
Product.searcher.for(:limit_by_search).suggestions(prefix: "prefix_term").keys
```

### Export Attribute

Add exporting to your ActiveRecord models.
Export Attribute provides full exporting functionality for your model database records.

You can define any number of model attributes and association attributes in one model to export together.

Define the export attributes in accordance with the column name in your model like below.
```ruby
class Product < ApplicationRecord
  export_attribute :name
  export_attribute :sku, heading: "SKU No."
  export_attribute :image_name, value: lambda { |record| record.image&.name }, includes: :image
  export_attribute :variations, value: lambda { |record| record.variations }, includes: :variations, attributes: [:name, :price, discount_value: { heading: "Discount" }]
end
```

You can also define an export_describer to describe the details of the export instead of using the defaults.
```ruby
class Product < ApplicationRecord
  # export_describer method_name, kind: :csv, database: -> { ActiveRecord::Base.connection_db_config.database }
  export_describer :to_csv, kind: :csv, database: -> { System::Current.tenant.database }
  export_attribute :name
  export_attribute :sku, heading: "SKU No."
  export_attribute :image_name, value: lambda { |record| record.image&.name }, includes: :image
  export_attribute :variations, value: lambda { |record| record.variations }, includes: :variations, attributes: [:name, :price, discount_value: { heading: "Discount" }]
end
```

The following class methods will be added to your model class to use in accordance with details provided for export_describer:
```ruby
Product.to_csv
```

### Position Attribute

Add positioning to your ActiveRecord models.
Position Attribute provides full positioning functionality using lexicographic ordering for your model database records.

You can also add multiple position attributes in one model to store different arrangements.

Just create a database column in your model with type :string having an index.
```ruby
add_column :products, :arrangement, :string
add_index  :products, :arrangement
```

Then define the column name in your model like below.
```ruby
class Product < ApplicationRecord
  position_attribute :arrangement
end
```

Creating the record will automatically set it to the last position:
```ruby
product = Product.create(name: "Nice Product")
```

The following attribute methods will become available in your model object to use:
```ruby
product.arrangement_position = 1 # Set the position
product.arrangement_position # Access the manually set position
product.arrangement_position_in_database # Check the position as per database
product.arrangement_position_options # Can be used in dropdown
product.arrangement_position_maximum # Check current maximum position
```

The following class methods will be added to your model class to use:
```ruby
# If a database table already has existing rows, run this to set initial values.
# You can also run this to manually harmonize a position attribute column.
Product.harmonize_arrangement!
```

### Schedule Attribute

Add scheduling to your ActiveRecord models.
Schedule Attribute provides full scheduling functionality to schedule one-time, recurring or run-later methods for your model database records.

You can also add multiple schedule attributes in one model to run multiple schedules.

Just create a database column in your model with type :datetime as below.
```ruby
add_column :products, :rearrangement_at, :datetime, precision: 6
```

Then define the column name and the respective method in your model like below.
```ruby
class Product < ApplicationRecord
  schedule_attribute :rearrangement_at

  def rearrangement
    # perform the task

    # Set the next datetime at which this method should run for this record.
    self.rearrangement_at = DateTime.current + 1.hour
    self.save
  end
end

# Or to use a custom schedule method name.

class Product < ApplicationRecord
  schedule_attribute :rearrangement_at, method: :rearranging

  def rearranging
    # perform the task

    # Set the next datetime at which this method should run for this record.
    self.rearrangement_at = DateTime.current + 1.hour
    self.save
  end
end
```

Creating the record will set the schedule attribute value to nil which signifies that the related method is not scheduled:
```ruby
product = Product.create(name: "Nice Product")
```

The following attributes will become available in your model object to use:
```ruby
product.rearrangement_at = DateTime.current + 2.hours # Set the schedule datetime after which the method will be sent to run.
product.rearrangement_at = nil # This will stop running the scheduled method for this record.
```

In case you want to schedule a different method for each record, just add another database column in your model like below.
```ruby
add_column :products, :rearrangement_method, :string
```

#### Using a Scheduler to Handle Multiple Records Together

If you want to schedule a method that handles multiple records together, you can create a scheduler.

Create a model named Scheduler. If you like, you can use another model name as per your context.
```sh
rails g model Scheduler
```

Then create database columns in your model as below.
```ruby
add_column :scheduler, :schedule_at, :datetime, precision: 6
add_column :scheduler, :schedule_method, :string

# TIP: You can also add other columns here to store useful values specific to each scheduler.
```

Then define the column name and all the schedule methods in your model like below.
```ruby
class Scheduler < ApplicationRecord
  schedule_attribute :schedule_at

  def method_name1
    # perform task1 for multiple records.

    # Set the next datetime at which this method should run for these records.
    self.schedule_at = DateTime.current + 1.hour
    self.save
  end

  def method_name2
    # perform task2 for multiple records.

    # Set the next datetime at which this method should run for these records.
    self.schedule_at = DateTime.current + 1.hour
    self.save
  end
end
```

Create a scheduler and it will be picked up to run automagically after the specified datetime.
```ruby
scheduler = Scheduler.create(schedule_at: DateTime.current + 2.hours, schedule_method: :method_name1)
```

Any number of schedulers can be added with each having a value for schedule_at and schedule_method. Hope you have fun using it.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'active_kit'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install active_kit
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
