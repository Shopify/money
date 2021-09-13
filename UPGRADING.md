## Upgrading to v1.0

In an initializer add the following
```ruby
Money.configure do |config|
  config.legacy_default_currency!
  config.legacy_deprecations!
  config.legacy_json_format!
  config.parser = MoneyParser
  #...
end
```

Remove each legacy setting making sure your app functions as expected.

### Legacy support

#### legacy_default_currency!

By enabling this setting your app will accept money object that are missing a currency

```ruby
Money.new(1) #=> value: 1, currency: XXX
```

#### legacy_deprecations!
By enabling `legacy_deprecations!` your app will show deprecation warnings instead of raising and will:

convert invalid money values to zero
```ruby
Money.new('a', 'USD') #=> Money.new(0, 'USD')
```

ignore invalid currencies
```ruby
Money.new(1, 'ABCD') #=> Money.new(1)
```

allow mathematical operations between different currencies
```ruby
Money.new(1, 'USD') + Money.new(1, 'CAD') #=> Money.new(2, 'USD')
```

parse a string with invalid delimiters
```ruby
Money.parse('123*12') #=> Money.new(123)
```

#### legacy_json_format!


By enabling `legacy_json_format!` your app will return only the value (no currency) when calling to_json
```ruby
# with legacy_json_format!
money.to_json #=> "1"

# without
money.to_json #=> { value: 1, currency: 'USD' }
```

#### MoneyParser

By setting the parser to `MoneyParser` your app will try to guess if `.` or `,` is a decimal or thousand mark

```ruby
Money.parse("1,000", "USD") #=> Money.new("1000", "USD")
Money.parse("1.000", "USD") #=> Money.new("1000", "USD")
```
