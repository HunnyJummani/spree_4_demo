module Spree
  module OrderDecorator
    def self.prepended(base)
      base.class_eval do
        has_many :payu_details, class_name: 'Spree::PayuDetail', dependent: :destroy

        def confirmation_required?
          false
        end
      end
    end
  end
end

Spree::Order.prepend Spree::OrderDecorator
