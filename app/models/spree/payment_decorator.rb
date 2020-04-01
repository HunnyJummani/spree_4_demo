module Spree
  module PaymentDecorator
    def self.prepended(base)
      base.class_eval do
        has_one :payu_detail, class_name: 'Spree::PayuDetail', dependent: :destroy
      end
    end
  end
end

Spree::Payment.prepend Spree::PaymentDecorator
