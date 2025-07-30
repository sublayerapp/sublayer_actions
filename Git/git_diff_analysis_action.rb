# Description: Sublayer::Action responsible for analyzing git diffs and providing structured analysis.
# This action takes a git diff as input and returns a detailed analysis of the changes, including
# files modified, lines changed, and potential impact areas.
#
# It is initialized with either a git diff string or a commit range.
# Returns a hash containing structured analysis of the changes.
#
# Example usage: When you want to analyze code changes for automated code review workflows,
# change documentation generation, or impact analysis.

class GitDiffAnalysisAction < Sublayer::Actions::Base
  def initialize(diff: nil, commit_range: nil)
    @diff = diff
    @commit_range = commit_range
    
    if @diff.nil? && @commit_range.nil?
      raise ArgumentError, 'Either diff or commit_range must be provided'
    end
  end

  def call
    begin
      diff_content = @diff || get_diff_from_commits
      analyze_diff(diff_content)
    rescue StandardError => e
      error_message = "Error analyzing git diff: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def get_diff_from_commits
    raise StandardError, 'Git is not installed' unless system('which git > /dev/null 2>&1')
    
    diff = `git diff #{@commit_range}`
    if $?.success?
      diff
    else
      raise StandardError, 'Failed to get git diff'
    end
  end

  def analyze_diff(diff_content)
    analysis = {
      files_changed: [],
      total_additions: 0,
      total_deletions: 0,
      impact_areas: Set.new,
      changes_by_file: {}
    }

    current_file = nil
    
    diff_content.each_line do |line|
      case line
      when /^diff --git a/(.*) b/(.*)/
        current_file = $2
        analysis[:files_changed] << current_file
        analysis[:changes_by_file][current_file] = {
          additions: 0,
          deletions: 0,
          changed_lines: []
        }
        
        # Analyze potential impact areas based on file path
        impact_area = analyze_impact_area(current_file)
        analysis[:impact_areas].add(impact_area) if impact_area

      when /^@@.+@@/
        # Capture the line numbers/context
        analysis[:changes_by_file][current_file][:changed_lines] << line.strip

      when /^\+(?!\+\+|@@)/
        # Count additions
        analysis[:total_additions] += 1
        analysis[:changes_by_file][current_file][:additions] += 1

      when /^-(?!--|@@)/
        # Count deletions
        analysis[:total_deletions] += 1
        analysis[:changes_by_file][current_file][:deletions] += 1
      end
    end

    # Convert Set to Array for better JSON serialization
    analysis[:impact_areas] = analysis[:impact_areas].to_a

    # Add summary statistics
    analysis[:summary] = {
      total_files_changed: analysis[:files_changed].length,
      total_changes: analysis[:total_additions] + analysis[:total_deletions],
      change_ratio: calculate_change_ratio(analysis[:total_additions], analysis[:total_deletions])
    }

    Sublayer.configuration.logger.log(:info, "Successfully analyzed git diff with #{analysis[:summary][:total_files_changed]} files changed")
    analysis
  end

  def analyze_impact_area(file_path)
    case file_path
    when /^app\//
      'Application Code'
    when /^config\//
      'Configuration'
    when /^db\//
      'Database'
    when /^test\//
      'Tests'
    when /^lib\//
      'Libraries'
    when /^docs\//
      'Documentation'
    else
      'Other'
    end
  end

  def calculate_change_ratio(additions, deletions)
    total = additions + deletions
    return 0.0 if total == 0
    
    {
      additions_percentage: (additions.to_f / total * 100).round(2),
      deletions_percentage: (deletions.to_f / total * 100).round(2)
    }
  end
end