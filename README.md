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

The following attribute methods will be added to your model object to use:
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
