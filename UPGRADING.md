## Upgrading to v1.0

1) In an initializer add the following
```ruby
Money.active_support_deprecator.behavior = :raise
Money.default_currency = nil # if you do not have a default currency
```
Make sure everything is running smoothly

2) Handle both format of the `to_json` (see breaking changes below)

3) upgrade to v1.0

#### Breaking changes

- invalid value will raise
```ruby
Money.new('a', 'USD')
```

- money with no currency will raise (setting a default currency is still supported)
```ruby
Money.new(1)
```

- invalid currency will raise
```ruby
Money.new(1, 'ABCD')
```

- mathematical operations between objects with different currencies will raise
```ruby
Money.new(1, 'USD') + Money.new(1, 'CAD')
```

- parsing a string with invalid delimiters will raise
```ruby
Money.parse('123*12')
```

- saving a money object with a new currency to a money_column with `read_only_currency: true` will raise

- to_json will return both value and currency, instead of just the value
```ruby
# before
money.to_json #=> "1"

# after
money.to_json #=> { value: 1, currency: 'USD' }
```

#### Legacy support

If you'd like more time to make the transition to v1.0 but still want the latest fixes add the following to an initializer
```ruby
Money.configure do |config|
  config.legacy_support!
  #...
end
```
