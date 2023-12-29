# ActiveKit
Add the essential kit for rails ActiveRecord models and be happy.

## Usage

### Position Attribute

Add positioning to your ActiveRecord models.
Position Attribute provides full positioning functionality using lexicographic ordering for your model database records.

You can add multiple position attributes in one model to store different arrangements.

Just create a database column in your model with type :string with index.
```ruby
add_column :products, :arrangement, :string, index: true, before: :created_at
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
product.arrangement_position
product.arrangement_position = 1
product.arrangement_position_in_database
product.arrangement_position_options
product.arrangement_position_maximum
```

The following class methods will be added to your model class to use:
```ruby
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
