## Road to v1.0
To make sure you're ready for v1.0 which includes numerous breaking changes, **please enable `opt_in_v1`**
```ruby
Money.configure do |config|
  config.opt_in_v1!
end
```

#### Breaking changes:

invalid value will raise
```ruby
Money.new('a', 'USD')
```

money with no currency will raise (setting a default currency is still supported)
```ruby
Money.new(1)
```

invalid currency will raise
```ruby
Money.new(1, 'ABCD')
```

mathematical operations between objects with different currencies will raise
```ruby
Money.new(1, 'USD') + Money.new(1, 'CAD')
```

parsing a string with invalid delimiters will raise
```ruby
Money.parse('123*12')
```

saving a money object with a new currency to a money_column will raise
```ruby
model.update(price: Money.new(1, 'USD'))
model.update(price: Money.new(1, 'CAD'))
```
(if you'd like to modify the currency you'll need to do so explicitly beforehand)

to_json will return both value and currency, instead of just the value
```ruby
money.to_json #=> { value: 1, currency: 'USD' }
```
