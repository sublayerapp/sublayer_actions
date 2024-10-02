class StripeChargeCustomerAction < Sublayer::Actions::Base
  def initialize(customer_id:, amount:, currency: 'usd', **kwargs)
    super(**kwargs)
    @customer_id = customer_id
    @amount = amount
    @currency = currency

    Stripe.api_key = ENV['STRIPE_SECRET_KEY']
  end

  def call
    begin
      charge = Stripe::Charge.create(
        amount: @amount,
        currency: @currency,
        customer: @customer_id
      )

      # Log success
      logger.info "Successfully charged customer #{@customer_id} amount #{@amount} #{@currency.upcase}"

      charge
    rescue Stripe::StripeError => e
      # Log error
      logger.error "Error charging customer: #{e.message}"
      raise e
    end
  end
end