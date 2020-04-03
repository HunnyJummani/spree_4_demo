# frozen_string_literal: true

module Spree
  class PayuHandlerController < Spree::StoreController
    skip_before_action :verify_authenticity_token
    before_action :check_response_authorized

    def success
      if order.update_from_params(payu_parmas, permitted_checkout_attributes, request.headers.env)
        order.temporary_address = !params[:save_user_address]
        unless order.next
          flash[:error] = order.errors.full_messages.join("\n")
          redirect_to(checkout_state_path(order.state)) && return
        end
        if order.completed?
          current_order = nil
          flash['order_completed'] = true
          Payu::CreatePayuDetails.new(order, params).create
          redirect_to spree.order_path(order, nil)
        else
          redirect_to checkout_state_path(order.state)
        end
      else
        redirect_to checkout_state_path(order.state)
      end
    end

    def fail
      Payu::CreatePayuDetails.new(order, params).create
      redirect_to checkout_state_path(order.state), alert: 'Something went wrong.'
    end

    private

    def payu_parmas
      ActionController::Parameters.new('_method' => 'patch', order: ActionController::Parameters.new(payments_attributes: [ActionController::Parameters.new(payment_method_id: payment_method.id, response_code: params[:mihpayid])]))
    end

    def check_response_authorized
      if params[:hash] != calculated_hash
        redirect_to checkout_state_path(order.state), alert: 'Something went wrong'
      end
    end

    def calculated_hash
      @calculated_hash ||= Payu::RequestBuilder.new(payment_method: payment_method, order: order).payment_resp_hash(params)
    end

    def payment_method
      @payment_method ||= Spree::PaymentMethod.find_by(type: Constants::PAYUIN_GATEWAY.to_s)
    end

    # params[:txnid] = "R695945340-asdasf"
    def order
      @order ||= Spree::Order.find_by(number: params[:txnid].split('-').first)
    end
  end
end
