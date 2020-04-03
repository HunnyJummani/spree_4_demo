# frozen_string_literal: true

module Spree
  module CheckoutControllerDecorator
    def self.prepended(base)
      base.class_eval do
        before_action :pay_with_payu, only: :update, if: :payment_with_payu?
      end
    end

    private

    def payment_with_payu?
      @order.state == 'payment' && payment_method.is_a?(Constants::PAYUIN_GATEWAY)
    end

    def pay_with_payu
      response = Payu::PaymentHandler.new(payment_method: payment_method, order: @order).send_payment

      if response.code == '200'
        render html: response.body.html_safe
      else
        redirect_to response['location']
      end
    end

    def payment_method
      pm_id = params.dig(:order, :payments_attributes).first[:payment_method_id]
      @payment_method ||= Spree::PaymentMethod.find_by(id: pm_id)
    end
  end
end

Spree::CheckoutController.prepend Spree::CheckoutControllerDecorator
