# frozen_string_literal: true

module Spree
  module CheckoutControllerDecorator
    def self.prepended(base)
      base.class_eval do
        skip_before_action :verify_authenticity_token, only: [:update]
        before_action :pay_with_payu, only: :update, if: :order_in_payment?
      end
    end

    private

    def order_in_payment?
      @order.state == 'payment'
    end

    def pay_with_payu
      return if params[:order].blank? || params[:order][:payments_attributes].blank?

      pm_id = params[:order][:payments_attributes].first[:payment_method_id]
      payment_method = Spree::PaymentMethod.find(pm_id)

      return unless payment_method.is_a?(Spree::Gateway::Payu)

      response = Payu::PaymentHandler.new(payment_method: payment_method, order: @order).send_payment

      if response.code == '200'
        render html: response.body.html_safe
      else
        redirect_to response['location']
      end
    end
  end
end

Spree::CheckoutController.prepend Spree::CheckoutControllerDecorator
