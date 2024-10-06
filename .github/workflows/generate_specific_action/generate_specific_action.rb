require "base64"
require "ostruct"

require "sublayer"
require "octokit"

# Load all Sublayer Actions, Generators, and Agents
Dir[File.join(__dir__, "actions", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "generators", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "agents", "*.rb")].each { |file| require file }

case ENV["AI_PROVIDER"]
when "openai"
  Sublayer.configuration.ai_provider = Sublayer::Providers::OpenAI
  Sublayer.configuration.ai_model = "gpt-4o-2024-08-06"
when "gemini"
  Sublayer.configuration.ai_provider = Sublayer::Providers::Gemini
  Sublayer.configuration.ai_model = "gemini-1.5-pro-latest"
when "claude"
  Sublayer.configuration.ai_provider = Sublayer::Providers::Claude
  Sublayer.configuration.ai_model = "claude-3-5-sonnet-20240620"
end

# Add custom Github Action code below:
repo = "sublayerapp/sublayer_actions"

existing_actions = GetContextAction.new(path: "#{ENV['GITHUB_WORKSPACE']}/sublayer_actions").call

new_action = ActionGenerator.new(idea: OpenStruct.new(title: ENV["ACTION_DESCRIPTION"], description: ENV["ACTION_DESCRIPTION"]), action_examples: existing_actions).generate

branch_name = "requested-action-#{ENV["AI_PROVIDER"]}-#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}"

GithubCreateBranchAction.new(
  repo: repo,
  base_branch: "main",
  new_branch: branch_name
).call

GithubCreateFileAction.new(
  repo: repo,
  branch: branch_name,
  file_path: new_action.file_path,
  file_content: new_action.content
).call

GithubCreatePRAction.new(
  repo: repo,
  base: "main",
  head: branch_name,
  title: "New Sublayer::Action: #{new_action.title}",
  body: new_action.description
).call
