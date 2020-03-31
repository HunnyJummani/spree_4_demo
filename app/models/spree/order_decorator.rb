module Spree
  module OrderDecorator
    def self.prepended(base)
      base.class_eval do
        def confirmation_required?
          false
        end
      end
    end
  end
end

Spree::Order.prepend Spree::OrderDecorator
