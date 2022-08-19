# frozen_string_literal: true

require_relative "cbtest/version"
require "coinbase/wallet"

module Cbtest
  class Error < StandardError; end

  class Wallet
    def initialize(_options = {})
      @api_key = ENV["COINBASE_API_KEY"]
      @api_secret = ENV["COINBASE_API_SECRET"]
    end

    def client
      @connection ||= Coinbase::Wallet::Client.new(api_key: @api_key, api_secret: @api_secret)
    end

    def account
      client.primary_account
    end

    def fiat_balance
      "#{fiat_account.native_balance['amount'].to_f} #{fiat_account.native_balance['currency']}"
    end

    def buys
      account.list_buys
    end

    def payment_method_fiat
      OpenStruct.new client.payment_methods.select { |h| h["type"] == "fiat_account" }.first
    end

    def payment_methods
      client.payment_methods
    end

    # wallet address to receive BTC
    def btc_receive_address
      address = account.addresses.first["address"]
      IO.popen('pbcopy', 'w') { |pipe| pipe.puts address }
      puts "send money to #{address}"
    end

    # amount ob BTC in my conibase wallet
    def btc_amount
      "#{account['balance']['amount']} => #{account.native_balance['amount'].to_f} #{account.native_balance['currency']}"
    end

    # current btc price in EU
    def btc_price
      client.buy_price(currency_pair: "BTC-EUR")
    end

    # w.send_btc("0.0001", "some_btc_wallt_address")
    def send_btc(amount, address)
      account.send(to: address, amount: amount, currency: "BTC", description: "btc sent to #{address}")
    end

    # buy_btc(0.001)
    def buy_btc(btc_amount)
      puts "btc price: #{btc_price}"
      raise "that is too much BTC #{btc_amount}" if btc_amount > 0.001

      buy = account.buy(amount: btc_amount, currency: "BTC", commit: false, payment_method: payment_method_fiat.id)
      puts "commit buy #{buy.id}"
      sleep 1
      account.commit_buy(buy.id)
    end

    def transactions
      account.transactions
    end

    def last_transaction
      account.transactions(limit: 1).first
    end

    private

    def fiat_account
      ac = OpenStruct.new payment_method_fiat.fiat_account
      OpenStruct.new client.account(ac.id)
    end

  end
end
