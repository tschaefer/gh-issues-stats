# frozen_string_literal: true

require 'fileutils'
require 'time'

require 'github/issues'

RSpec.describe 'Update Issues Scenario' do # rubocop:disable RSpec/DescribeClass
  before do
    stub_request(
      :get,
      'https://api.github.com/repos/octodog/bark'
    )
      .to_return(
        status: 200,
        body: '',
        headers: {}
      )

    stub_request(
      :get,
      'https://api.github.com/repos/octodog/bark/issues?direction=desc&per_page=100&sort=created&state=all'
    )
      .to_return(
        status: 200,
        body: File.read('spec/fixtures/issues.json'),
        headers: { 'Content-Type' => 'application/json' }
      )

    stub_request(
      :get,
      "https://api.github.com/repos/octodog/bark/issues?direction=desc&per_page=100&since=#{Time.now.utc.iso8601}&sort=created&state=all"
    )
      .to_return(
        status: 200,
        body: File.read('spec/fixtures/issues_updated.json'),
        headers: { 'Content-Type' => 'application/json' }
      )

    stub_const('Github::Issues::CACHE_DIR', Dir.mktmpdir)
  end

  after do
    FileUtils.remove_entry_secure(Github::Issues::CACHE_DIR)
  end

  it 'updates issues from GitHub API after refresh interval expires' do
    issues = Github::Issues.new('octodog/bark').filtered_by_labels(%w[urgent])
    expect(issues.size).to eq(1)
    expect(issues.first.state).to eq('open')
    expect(issues.first.number).to eq(8888)

    allow(Time).to receive(:now).and_return(Time.now.utc + (2 * 86_400)) # 2 days later

    issues = Github::Issues.new('octodog/bark').filtered_by_labels(%w[urgent])
    expect(issues.size).to eq(2)
    expect(issues.last.state).to eq('closed')
    expect(issues.last.number).to eq(8888)
  end
end
