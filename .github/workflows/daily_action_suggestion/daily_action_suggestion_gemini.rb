require "base64"

require "sublayer"
require "octokit"

# Load all Sublayer Actions, Generators, and Agents
Dir[File.join(__dir__, "actions", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "generators", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "agents", "*.rb")].each { |file| require file }

Sublayer.configuration.ai_provider = Sublayer::Providers::Gemini
Sublayer.configuration.ai_model = "gemini-1.5-pro-latest"
Sublayer.configuration.logger = Sublayer::Logging::DebugLogger.new

# Add custom Github Action code below:

code_repo_path = "#{ENV['GITHUB_WORKSPACE']}/sublayer"
action_repo_path = "#{ENV['GITHUB_WORKSPACE']}/sublayer_actions"

code_context = GetContextAction.new(path: code_repo_path).call
action_code_context = GetContextAction.new(path: action_repo_path).call

action_ideas = ActionIdeasGenerator.new(code_context: code_context, action_code_context: action_code_context).generate
best_idea = action_ideas.sort_by { |idea| idea.usefulness_score.to_i }.reverse.first
new_action = ActionGenerator.new(idea: best_idea).generate

branch_name = "daily-action-suggestion-gemini-#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}"
repo = "sublayerapp/sublayer_actions"

GithubCreateBranchAction.new( repo: repo, base_branch: "main", new_branch: branch_name).call
GithubCreateFileAction.new( repo: repo, branch: branch_name, file_path: new_action.file_path, file_content: new_action.content).call
GithubCreatePRAction.new( repo: repo, base: "main", head: branch_name, title: best_idea.title, body: best_idea.description).call
