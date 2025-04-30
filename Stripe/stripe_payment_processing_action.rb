require 'stripe'

# Description: Sublayer::Action for interacting with the Stripe API for payment processing.
# This action can handle creating charges, managing subscriptions, or retrieving payment information.
#
# Requires: 'stripe' gem
# \$ gem install stripe
# Or add `gem 'stripe'` to your Gemfile
#
# It is initialized with your Stripe secret key (accessible via the Stripe dashboard).
# You should store this key securely as an environment variable.
#
# Example usage: When you want to integrate AI-powered applications with e-commerce platforms for tasks like:
# - Creating charges for products or services
# - Managing user subscriptions
# - Retrieving payment details

class StripePaymentProcessingAction < Sublayer::Actions::Base
  def initialize(secret_key: nil)
    @secret_key = secret_key || ENV['STRIPE_SECRET_KEY']
    Stripe.api_key = @secret_key
  end

  def call(action:, **params)
    begin
      case action
      when :create_charge
        create_charge(params)
      when :create_subscription
        create_subscription(params)
      when :retrieve_payment_intent
        retrieve_payment_intent(params)
      else
        raise ArgumentError, "Invalid action: \#{action}\"
      end
    rescue Stripe::StripeError => e
      error_message = "Stripe error: \#{e.message}\"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_charge(params)
    response = Stripe::Charge.create(params)
    Sublayer.configuration.logger.log(:info, "Stripe charge created: \#{response.id}\")
    response
  end

  def create_subscription(params)
    response = Stripe::Subscription.create(params)
    Sublayer.configuration.logger.log(:info, "Stripe subscription created: \#{response.id}\")
    response
  end

  def retrieve_payment_intent(params)
    response = Stripe::PaymentIntent.retrieve(params[:payment_intent_id])
    Sublayer.configuration.logger.log(:info, "Stripe payment intent retrieved: \#{response.id}\")
    response
  end
end