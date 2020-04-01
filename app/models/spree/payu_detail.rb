module Spree
  class PayuDetail < ApplicationRecord
    belongs_to :payment, class_name: 'Spree::Payment'
    belongs_to :order, class_name: 'Spree::Order'
  end
end
