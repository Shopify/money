module MoneyColumn
  module ActiveRecordHooks
    def money_column(*columns)
      Array(columns).flatten.each do |name|
        composed_of name,
          class_name: 'Money',
          allow_nil: true,
          mapping: [name, :value],
          converter: Proc.new { |v| v.present? && v.respond_to?(:to_money) ? v.to_money : nil }
      end
    end
  end
end
