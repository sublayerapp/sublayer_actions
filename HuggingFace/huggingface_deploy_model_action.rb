require 'huggingface_hub'

# Description: Sublayer::Action responsible for deploying models to HuggingFace's model hosting service.
# This action enables automated deployment of models directly from Sublayer workflows,
# making it easy to integrate custom or fine-tuned models into production environments.
#
# Requires: 'huggingface_hub' gem
# $ gem install huggingface_hub
# Or add `gem 'huggingface_hub'` to your Gemfile
#
# It is initialized with:
# - repo_id: The repository ID where the model will be deployed (e.g., 'username/model-name')
# - model_path: Local path to the model files
# - task_type: The type of task the model performs (e.g., 'text-classification', 'token-classification')
# - framework: The framework used (e.g., 'pytorch', 'tensorflow')
# Optional:
# - private: Whether the model should be private (default: false)
# - readme_content: Content for the model's README.md file
#
# Returns the URL of the deployed model on HuggingFace.
#
# Example usage: When you want to deploy a fine-tuned or custom model to HuggingFace
# for production use or sharing with the community.

class HuggingFaceDeployModelAction < Sublayer::Actions::Base
  def initialize(repo_id:, model_path:, task_type:, framework:, private: false, readme_content: nil)
    @repo_id = repo_id
    @model_path = model_path
    @task_type = task_type
    @framework = framework
    @private = private
    @readme_content = readme_content || generate_default_readme
    @api = HuggingFace::Hub::Client.new(api_token: ENV['HUGGINGFACE_API_TOKEN'])
  end

  def call
    begin
      validate_inputs
      create_or_update_repo
      upload_model_files
      update_model_card

      model_url = "https://huggingface.co/#{@repo_id}"
      Sublayer.configuration.logger.log(:info, "Successfully deployed model to #{model_url}")
      model_url
    rescue HuggingFace::Hub::Error => e
      error_message = "HuggingFace API error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error deploying model: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def validate_inputs
    raise StandardError, 'Model path does not exist' unless File.directory?(@model_path)
    raise StandardError, 'Invalid repository ID format' unless @repo_id.match?(/^[\w-]+\/[\w-]+$/)
    validate_task_type
    validate_framework
  end

  def validate_task_type
    valid_tasks = ['text-classification', 'token-classification', 'question-answering',
                   'summarization', 'translation', 'text-generation', 'fill-mask',
                   'sentence-similarity', 'image-classification', 'object-detection']
    unless valid_tasks.include?(@task_type)
      raise StandardError, "Invalid task type. Must be one of: #{valid_tasks.join(', ')}"
    end
  end

  def validate_framework
    valid_frameworks = ['pytorch', 'tensorflow', 'jax', 'keras']
    unless valid_frameworks.include?(@framework)
      raise StandardError, "Invalid framework. Must be one of: #{valid_frameworks.join(', ')}"
    end
  end

  def create_or_update_repo
    @api.create_repo(
      repo_id: @repo_id,
      private: @private,
      exists_ok: true
    )
  end

  def upload_model_files
    Dir.glob(File.join(@model_path, '**', '*')).each do |file_path|
      next if File.directory?(file_path)
      
      relative_path = file_path.sub("#{@model_path}/", '')
      @api.upload_file(
        path_or_fileobj: file_path,
        path_in_repo: relative_path,
        repo_id: @repo_id,
        commit_message: "Upload model file: #{relative_path}"
      )
    end
  end

  def update_model_card
    @api.upload_file(
      path_or_fileobj: StringIO.new(@readme_content),
      path_in_repo: 'README.md',
      repo_id: @repo_id,
      commit_message: 'Update model card'
    )
  end

  def generate_default_readme
    <<~README
      # #{@repo_id.split('/').last}

      This model was deployed using the Sublayer AI Framework.

      ## Model Information
      - Task Type: #{@task_type}
      - Framework: #{@framework}
      - Repository: #{@repo_id}

      ## Usage
      ```python
      from transformers import AutoModel, AutoTokenizer

      model = AutoModel.from_pretrained("#{@repo_id}")
      tokenizer = AutoTokenizer.from_pretrained("#{@repo_id}")
      ```
    README
  end
end