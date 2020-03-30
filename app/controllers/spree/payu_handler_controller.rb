# frozen_string_literal: true

module Spree
  class PayuHandlerController < Spree::StoreController
    skip_before_action :verify_authenticity_token
    before_action :check_response_authorized

    def success
      session[:payu_response] = params
      default_payment = {
        payments_attributes: [{
          source: nil,
          payment_method_id: payment_method.try(:id),
          amount: order.total
        }]
      }
      if order.update(default_payment)
        order.next
        redirect_to checkout_state_path(order.state)
      else
        logger.error(" --------  ERROR  -------- \nPAyu Payment Failure: Unable to create payment using parameters: #{order.errors.full_messages.join(', ')}")
        false
      end
    end

    def fail
      redirect_to checkout_state_path(order.state)
    end


    private

    def check_response_authorized
      calculated_hash = Payu::RequestBuilder.new(payment_method: payment_method, order: order).payment_resp_hash

      if params[:hash] !=  calculated_hash
        redirect_to checkout_state_path(order.state), notice: 'Something went wrong'
      end
    end

    def payment_method
      @payment_method ||= Spree::PaymentMethod.find_by(type: 'Spree::PaymentMethod::Payu')
    end

    # params[:txnid] = "R695945340-asdasf"
    def order
      @order ||= Spree::Order.find_by(number: params[:txnid].split('-').first)
    end
  end
end
