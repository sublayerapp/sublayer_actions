require "base64"

require "sublayer"
require "octokit"

# Load all Sublayer Actions, Generators, and Agents
Dir[File.join(__dir__, "actions", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "generators", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "agents", "*.rb")].each { |file| require file }

Sublayer.configuration.ai_provider = Sublayer::Providers::Gemini
Sublayer.configuration.ai_model = "gemini-1.5-pro-latest"

# Add custom Github Action code below:

repo = "sublayerapp/sublayer_actions"
pr_number = ENV["PR_NUMBER"]

pr_changes = GetPRChangesAction.new(repo: repo, pr_number: pr_number).call
file_info = GetPRFileInfoAction.new(repo: repo, pr_number: pr_number).call

use_cases = SublayerActionUseCaseGenerator.new(pr_changes: pr_changes).call

message = <<~MESSAGE
      🎉 **New Sublayer::Action just merged: #{file_info[:file_name]}**
      🔗 [View on GitHub](<#{file_info[:file_url]}>)

      #{pr_changes[:body]}

      This action is designed to be used in the following ways:
      #{use_cases.map { |use_case| "• #{use_case}" }.join("\n")}
    MESSAGE

DiscordSendMessageAction.new(webhook_url: ENV["DISCORD_WEBHOOK_URL"], message: message).call
