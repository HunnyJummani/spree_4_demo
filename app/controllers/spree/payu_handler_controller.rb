# frozen_string_literal: true

module Spree
  class PayuHandlerController < Spree::StoreController
    skip_before_action :verify_authenticity_token
    #before_action :check_response_authorized

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

        if order.completed?
          @current_order = nil
          flash['order_completed'] = true
          redirect_path = spree.order_path(order, nil)
        end
      else
        logger.error(" --------  ERROR  -------- \nPAyu Payment Failure: Unable to create payment using parameters: #{order.errors.full_messages.join(', ')}")
        redirect_path = checkout_state_path(order.state)
      end

      redirect_to redirect_path
    end

    def fail
      redirect_to checkout_state_path(order.state)
    end


    private

    def check_response_authorized
      if params[:hash] !=  calculated_hash
        redirect_to checkout_state_path(order.state), alert: 'Something went wrong'
      end
    end

    def calculated_hash
      @calculated_hash ||= Payu::RequestBuilder.new(payment_method: payment_method, order: order).payment_resp_hash(txnid: params[:txnid], status: params[:status])
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
