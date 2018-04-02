# money

[![Build Status](https://circleci.com/gh/Shopify/money.png?circle-token=88060f61185838446bb65723d96658bdd74ebb3c)](https://circleci.com/gh/Shopify/money) [![codecov](https://codecov.io/gh/Shopify/money/branch/master/graph/badge.svg)](https://codecov.io/gh/Shopify/money)


money_column expects a decimal 8,3 database field.

### Features

- Keeps value in decimal
- Provides a `Money` class which encapsulates all information about an certain
  amount of money, such as its value and its currency.
- Provides a `Money::Currency` class which encapsulates all information about
  a monetary unit.
- Does NOT provides APIs for exchanging money from one currency to another.
- wont lose pennies during division!
- Money::NullCurrency for no currency support

## Installation

    gem 'shopify-money', require: 'money'

## Usage

``` ruby
require 'money'

# 10.00 USD
money = Money.new(10.00, "USD")
money.subunits     #=> 1000
money.currency  #=> Currency.new("USD")

# Comparisons
Money.new(1000, "USD") == Money.new(1000, "USD")   #=> true
Money.new(1000, "USD") == Money.new(100, "USD")    #=> false
Money.new(1000, "USD") == Money.new(1000, "EUR")   #=> false
Money.new(1000, "USD") != Money.new(1000, "EUR")   #=> true

# Arithmetic
Money.new(1000, "USD") + Money.new(500, "USD") == Money.new(1500, "USD")
Money.new(1000, "USD") - Money.new(200, "USD") == Money.new(800, "USD")
Money.new(1000, "USD") / 5                     == Money.new(200, "USD")
Money.new(1000, "USD") * 5                     == Money.new(5000, "USD")

# Unit to subunit conversions
Money.from_subunits(500, "USD") == Money.new(5, "USD")  # 5 USD
Money.from_subunits(5, "JPY") == Money.new(5, "JPY")    # 5 JPY
Money.from_subunits(5000, "TND") == Money.new(5, "TND") # 5 TND
```

## Currency

Currencies are consistently represented as instances of `Money::Currency`.
The most part of `Money` APIs allows you to supply either a `String` or a
`Money::Currency`.

``` ruby
Money.new(1000, "USD") == Money.new(1000, Money::Currency.new("USD"))
Money.new(1000, "EUR").currency == Money::Currency.new("EUR")
```

A `Money::Currency` instance holds all the information about the currency,
including the currency symbol, name and much more.

``` ruby
currency = Money.new(1000, "USD").currency
currency.iso_code #=> "USD"
currency.name     #=> "United States Dollar"
currency.to_s     #=> 'USD'
currency.symbol   #=> '$'
currency.disambiguate_symbol #=> 'US$'
```

### Default Currency

By default `Money` defaults to Money::NullCurrency as its currency. This is a
global variable that can be changed using:

``` ruby
Money.default_currency = Money::Currency.new("USD")
```

In web apps you might want to set the default currency on a per request basis.
In Rails you can do this with an around action, for example:

```ruby
class ApplicationController < ActionController::Base
  around_action :set_currency

  private

  def set_currency
    Money.with_currency(current_shop.currency) { yield }
  end
end
```

### Currency Minor Units

The exponent of a money value is the number of digits after the decimal
separator (which separates the major unit from the minor unit).

``` ruby
Money::Currency.new("USD").minor_units  # => 2
Money::Currency.new("JPY").minor_units  # => 0
Money::Currency.new("MGA").minor_units  # => 1
```

## Money column

Since money internally uses BigDecimal it's logical to use a `decimal` column
(or `money` for PostgreSQL) for your database. The `money_column` method can
generate methods for use with ActiveRecord:

```ruby
create_table :orders do |t|
  t.decimal :sub_total, precision: 20, scale: 3
  t.decimal :tax, precision: 20, scale: 3
  t.string :currency, limit: 3
end

class Order < ApplicationRecord
  money_column :sub_total, :tax
end
```

### Options

| option | type |  description |
| --- | --- |  --- |
| currency_column | method | column from which to read/write the currency  |
| currency | string | hardcoded currency value  |
| currency_read_only | boolean |  when true, `currency_column` won't write the currency back into the db. Must be set to true if `currency_column` is an attr_reader or delegate. Default: false |
| coerce_null | boolean | when true, a nil value will be returned as Money.zero. Default: false |

You can use multiple `money_column` calls to achieve the desired effects with
currency on the model or attribute level.

There are no validations generated. You can add these for the specified money
and currency attributes as you normally would for any other.

## Contributing to money

- Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
- Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
- Fork the project
- Start a feature/bugfix branch
- Commit and push until you are happy with your contribution
- Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
- Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 Shopify. See LICENSE.txt for
further details.

