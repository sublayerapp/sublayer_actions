require 'brakeman'

# Description: Sublayer::Action responsible for performing a security audit on Ruby on Rails code repositories
# using Brakeman to identify potential vulnerabilities and suggest fixes.
#
# This action can be used to ensure the security of your codebase by running regular security audits.
#
# Example usage: Use this action to audit your Rails application codebase for vulnerabilities
# and receive a summary of potential security issues.

class CodeSecurityAuditAction < Sublayer::Actions::Base
  def initialize(repo_path:)
    @repo_path = repo_path
    @report = nil
  end

  def call
    begin
      run_security_audit
      Sublayer.configuration.logger.log(:info, "Security audit completed successfully for #{@repo_path}")
      @report
    rescue StandardError => e
      error_message = "Error performing security audit: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def run_security_audit
    tracker = Brakeman.run(app_path: @repo_path)
    @report = tracker.report.to_markdown
  end
end