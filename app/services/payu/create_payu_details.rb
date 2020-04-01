# frozen_string_literal: true

module Payu
  class CreatePayuDetails
    attr_reader :params

    def initialize(_order, params)
      @params = params
    end

    def create
      payu_payment_method = Spree::PaymentMethod.find_by(type: Constants::PAYUIN_GATEWAY.to_s).id
      payu_payment = order.payments.find_by(payment_method_id: payu_payment_method)

      # Create Payu details for payment and order to be placed.
      payu_payment.create_payu_detail(mih_pay_id: params[:mihpayid],
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
                                      order_id: order.id)
    end

    private

    def order
      order_number = params[:txnid].split('-').first
      @order ||= Spree::Order.find_by(number: order_number)
    end
  end
end
