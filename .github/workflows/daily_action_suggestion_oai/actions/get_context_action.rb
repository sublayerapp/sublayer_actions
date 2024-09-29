class GetContextAction < Sublayer::Actions::Base
  def initialize(repo_path:)
    @repo_path = repo_path
  end

  def call
    result = `cd #{@repo_path} && git ls-files | while read -r file; do echo "File: $file"; cat "$file"; echo ""; done`
    result
  end
end
