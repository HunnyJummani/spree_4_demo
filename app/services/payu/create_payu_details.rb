# frozen_string_literal: true

module Payu
  class CreatePayuDetails
    attr_reader :params

    def initialize(_order, params)
      @params = params
    end

    def create
      # Create Payu details for payment and order to be placed.
      Spree::PayuDetail.create(payu_detail_params)
    end

    private

    def order
      order_number = params[:txnid].split('-').first
      @order ||= Spree::Order.find_by(number: order_number)
    end

    def payu_detail_params
      {
        mih_pay_id: params[:mihpayid],
        status: params[:status],
        txnid: params[:txnid],
        payment_source: params[:payment_source],
        pg_type: params[:PG_TYPE],
        bank_ref_num: params[:bank_ref_num],
        error: params[:error],
        error_message: params[:error_Message],
        issuing_bank: params[:issuing_bank],
        card_type: params[:card_type],
        card_num: params[:cardnum].last(4),
        order: order,
        payment: payu_payment
      }
    end

    def payu_payment
      @payu_payment ||= order.payments.find_by(payment_method_id: payment_method_id)
    end

    def payment_method_id
      @payment_method_id ||= Spree::PaymentMethod.find_by(type: Constants::PAYUIN_GATEWAY.to_s).id
    end
  end
end
