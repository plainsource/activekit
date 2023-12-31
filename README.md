# ActiveKit
Add the essential kit for rails ActiveRecord models and be happy.

## Usage

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
