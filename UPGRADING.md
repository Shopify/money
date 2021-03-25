## Upgrading to v1.0

In an initializer add the following
```ruby
Money.configure do |config|
  config.legacy_default_currency!
  config.legacy_deprecations!
  config.legacy_json_format!
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

invalid money values return zero
```ruby
Money.new('a', 'USD') #=> Money.new(0, 'USD')
```

invalid currency is ignored
```ruby
Money.new(1, 'ABCD') #=> Money.new(1)
```

mathematical operations between objects are allowed
```ruby
Money.new(1, 'USD') + Money.new(1, 'CAD') #=> Money.new(2, 'USD')
```

parsing a string with invalid delimiters
```ruby
Money.parse('123*12') #=> Money.new(123)
```

#### legacy_json_format!

to_json will return only the value (no currency)
```ruby
# with legacy_json_format!
money.to_json #=> "1"

# without
money.to_json #=> { value: 1, currency: 'USD' }
```

