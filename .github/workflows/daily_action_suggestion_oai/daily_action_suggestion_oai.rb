require "base64"

require "sublayer"
require "octokit"

# Load all Sublayer Actions, Generators, and Agents
Dir[File.join(__dir__, "actions", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "generators", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "agents", "*.rb")].each { |file| require file }

Sublayer.configuration.ai_provider = Sublayer::Providers::OpenAI
Sublayer.configuration.ai_model = "gpt-4o"

# Add custom Github Action code below:

code_repo_path = "#{ENV['GITHUB_WORKSPACE']}/sublayer"
action_repo_path = "#{ENV['GITHUB_WORKSPACE']}/sublayer-actions"

code_context = GetContextAction.new(repo_path: code_repo_path).call
action_code_context = GetContextAction.new(repo_path: action_repo_path).call

action_ideas = ActionIdeasGenerator.new(code_context: code_context, action_code_context: action_code_context).generate
sorted_ideas = action_ideas.sort_by { |idea| idea.usefulness_score.to_i }.reverse
best_idea = sorted_ideas.first
new_action = ActionGenerator.new(idea: best_idea).generate

branch_name = "daily-action-suggestion-oai-#{Time.now.strftime("%Y-%m-%d")}"
repo = "sublayerapp/sublayer-actions"

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
  title: best_idea.title,
  body: best_idea.description
).call

