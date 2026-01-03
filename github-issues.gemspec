# frozen_string_literal: true

$LOAD_PATH << File.expand_path('lib', __dir__)
require 'github/issues/version'

Gem::Specification.new do |spec|
  spec.name        = 'github-issues'
  spec.version     = Github::Issues::VERSION
  spec.platform    = Gem::Platform::RUBY
  spec.authors     = ['Tobias Schäfer']
  spec.email       = ['github@blackox.org']

  spec.summary     = 'Analyse Github repository issues lifecycle.'
  spec.description = <<~DESC
    #{spec.summary}
  DESC
  spec.homepage    = 'https://github.com/tschaefer/github-issues'
  spec.license     = 'MIT'

  spec.files                 = Dir['lib/**/*']
  spec.bindir                = 'bin'
  spec.executables           = ['github-issues']
  spec.require_paths         = ['lib']
  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['source_code_uri']       = 'https://github.com/tschaefer/github-issues'
  spec.metadata['bug_tracker_uri']       = 'https://github.com/tschaefer/github-issues/issues'

  spec.add_dependency 'clamp', '~> 1.3.2'
  spec.add_dependency 'faraday-retry', '~> 2.4.0'
  spec.add_dependency 'hashie', '~> 5.1.0'
  spec.add_dependency 'octokit', '~> 10.0.0'
  spec.add_dependency 'pastel', '~> 0.8.0'
  spec.add_dependency 'sqlite3', '~> 2.9.0'
  spec.add_dependency 'tty-pager', '~> 0.14.0'
  spec.add_dependency 'tty-spinner', '~> 0.9.3'
  spec.add_dependency 'tty-table', '~> 0.12.0'
  spec.add_dependency 'unicode_plot', '~> 0.0.5'
  spec.add_dependency 'zeitwerk', '~> 2.7.1'
end
