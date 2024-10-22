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

Sublayer.configuration.logger = Sublayer::Logging::DebugLogger.new

# Add custom Github Action code below:

code_repo_path = "#{ENV['GITHUB_WORKSPACE']}/sublayer"
action_repo_path = "#{ENV['GITHUB_WORKSPACE']}/sublayer_actions"

code_context = GetContextAction.new(path: code_repo_path).call
action_code_context = GetContextAction.new(path: action_repo_path).call

action_ideas = ActionIdeasGenerator.new(code_context: code_context, action_code_context: action_code_context).generate
best_idea = action_ideas.sort_by { |idea| idea.usefulness_score.to_i }.reverse.first
new_action = ActionGenerator.new(idea: best_idea, action_examples: action_code_context).generate

branch_name = "daily-action-suggestion-#{ENV["AI_PROVIDER"]}-#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}"
repo = "sublayerapp/sublayer_actions"

GithubCreateBranchAction.new( repo: repo, base_branch: "main", new_branch: branch_name).call
GithubCreateFileAction.new( repo: repo, branch: branch_name, file_path: new_action.file_path, file_content: new_action.content).call
new_pr = GithubCreatePRAction.new( repo: repo, base: "main", head: branch_name, title: "(#{ENV["AI_PROVIDER"]}): #{best_idea.title}", body: best_idea.description).call

GithubAddPRLabelAction.new(repo: repo, pr_number: new_pr.number, label: "ai-generated").call
GithubAddPRLabelAction.new(repo: repo, pr_number: new_pr.number, label: ENV["AI_PROVIDER"]).call
