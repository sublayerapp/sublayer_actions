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
  Sublayer.configuration.ai_model = "gpt-4o-2024-08-06"
when "gemini"
  Sublayer.configuration.ai_provider = Sublayer::Providers::Gemini
  Sublayer.configuration.ai_model = "gemini-1.5-pro-latest"
when "claude"
  Sublayer.configuration.ai_provider = Sublayer::Providers::Claude
  Sublayer.configuration.ai_model = "claude-3-5-sonnet-20240620"
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

new_pr = GithubCreatePRAction.new(
  repo: repo,
  base: "main",
  head: branch_name,
  title: "New Sublayer::Action from #{ENV["AI_PROVIDER"]}: #{best_idea.title}",
  body: best_idea.description
).call

GithubAddPRLabelAction.new(repo: repo, pr_number: new_pr.number, label: "ai-generated").call
GithubAddPRLabelAction.new(repo: repo, pr_number: new_pr.number, label: ENV["AI_PROVIDER"]).call
