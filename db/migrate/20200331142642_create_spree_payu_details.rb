class CreateSpreePayuDetails < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_payu_details do |t|
      t.string :mih_pay_id
      t.string :status
      t.string :txnid
      t.string :payment_source
      t.string :pg_type
      t.string :bank_ref_num
      t.string :error
      t.string :error_message
      t.string :issuing_bank
      t.string :card_type
      t.string :card_num, length: 4
      t.references :payment, null: true
      t.references :order, null: false

      t.timestamps
    end
  end
end
