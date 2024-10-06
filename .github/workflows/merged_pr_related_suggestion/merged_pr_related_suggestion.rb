require "base64"

require "sublayer"
require "octokit"

# Load all Sublayer Actions, Generators, and Agents
Dir[File.join(__dir__, "actions", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "generators", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "agents", "*.rb")].each { |file| require file }

case ENV["AI_PROVIDER"]
when "openai"
  Sublayer.configuration.ai_provider = Sublayer::Providers::OpenAI
when "gemini"
  Sublayer.configuration.ai_provider = Sublayer::Providers::Gemini
when "claude"
  Sublayer.configuration.ai_provider = Sublayer::Providers::Claude
end

Sublayer.configuration.ai_model = ENV["AI_MODEL"]
Sublayer.configuration.logger = Sublayer::Logging::DebugLogger.new

repo = "sublayerapp/sublayer_actions"
pr_number = ENV["PR_NUMBER"]

pr_changes = GetPRChangesAction.new(repo: repo, pr_number: pr_number).call

existing_actions = GetContextAction.new(path: "#{ENV['GITHUB_WORKSPACE']}/sublayer_actions").call

action_ideas = RelatedActionIdeasGenerator.new(pr_changes: pr_changes, existing_actions: existing_actions).generate

best_idea = action_ideas.max_by { |idea| idea.usefulness_score.to_i }

new_action = ActionGenerator.new(idea: best_idea, action_examples: existing_actions).generate

branch_name = "pr-related-suggestion-#{pr_number}-#{ENV["AI_PROVIDER"]}-#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}"

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
  title: "New Sublayer::Action: #{best_idea.title}",
  body: best_idea.description
).call
