# Description: Base class for Asana actions that abstracts away access_token handling and provides an Asana client instance to subclasses

class AsanaBase < Sublayer::Actions::Base
  def initialize(access_token: nil)
    @access_token = access_token || ENV["ASANA_ACCESS_TOKEN"]
    @client = Asana::Client.new do |c|
      c.authentication :access_token, @access_token
    end
  end
end
