# frozen_string_literal: true

module Spree
  class PayuHandlerController < Spree::StoreController
    skip_before_action :verify_authenticity_token
    def success
      @order = Spree::Order.find_by(number: params[:txnid])
      payment_method = Spree::PaymentMethod.find_by(name: 'PayUMoney')
      session[:payu_response] = params
      default_payment = {
        payments_attributes: [{
          source: nil,
          payment_method_id: payment_method.try(:id),
          amount: @order.total
        }]
      }
      if @order.update(default_payment)
        @order.next
        redirect_to checkout_state_path(@order.state)
      else
        logger.error(" --------  ERROR  -------- \nPAyu Payment Failure: Unable to create payment using parameters: #{@order.errors.full_messages.join(', ')}")
        false
    end
    end

    def fail
      @order = Spree::Order.find_by(number: params[:txnid])
      redirect_to checkout_state_path(@order.state)
    end
end
end
