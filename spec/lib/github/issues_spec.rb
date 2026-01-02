# frozen_string_literal: true

require 'time'
require 'fileutils'

require 'github/issues'

RSpec.describe Github::Issues do
  describe '.new' do
    context 'when repository does not exist' do
      before do
        stub_request(
          :get,
          'https://api.github.com/repos/repo/notfound'
        )
          .to_return(
            status: 404,
            body: '',
            headers: {}
          )
        stub_const('Github::Issues::CACHE_DIR', Dir.mktmpdir)
      end

      after do
        FileUtils.remove_entry_secure(Github::Issues::CACHE_DIR)
      end

      it 'raises an Octokit::NotFound error' do
        expect { described_class.new('repo/notfound') }
          .to raise_error(Octokit::NotFound)
      end
    end

    context 'with invalid credentials' do
      before do
        stub_request(
          :get,
          'https://api.github.com/repos/repo/forbidden'
        )
          .to_return(
            status: 403,
            body: '',
            headers: {}
          )
        stub_const('Github::Issues::CACHE_DIR', Dir.mktmpdir)
      end

      after do
        FileUtils.remove_entry_secure(Github::Issues::CACHE_DIR)
      end

      it 'raises an Octokit::Forbidden error' do
        expect { described_class.new('repo/forbidden') }
          .to raise_error(Octokit::Forbidden)
      end
    end

    context 'when repository exist' do
      before do
        stub_request(
          :get,
          'https://api.github.com/repos/repo/existing'
        )
          .to_return(
            status: 200,
            body: '',
            headers: {}
          )

        stub_request(
          :get,
          'https://api.github.com/repos/repo/existing/issues?direction=desc&per_page=100&sort=created&state=all'
        )
          .to_return(
            status: 200,
            body: '[]',
            headers: { 'Content-Type' => 'application/json' }
          )
        stub_const('Github::Issues::CACHE_DIR', Dir.mktmpdir)
      end

      after do
        FileUtils.remove_entry_secure(Github::Issues::CACHE_DIR)
      end

      it 'creates a new instance of Github::Issues' do
        issues = described_class.new('repo/existing')
        expect(issues).to be_a(described_class)
      end

      it 'creates a cache directory' do
        expect(Dir.exist?(Github::Issues::CACHE_DIR)).to be true
      end
    end
  end

  describe '.labels' do
    let(:labels) { ['bug', 'enhancement', 'help wanted', 'urgent'] }

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
      stub_const('Github::Issues::CACHE_DIR', Dir.mktmpdir)
    end

    after do
      FileUtils.remove_entry_secure(Github::Issues::CACHE_DIR)
    end

    it 'returns all unique labels' do
      issues = described_class.new('octodog/bark').labels
      expect(issues).to eq(labels)
    end
  end

  describe '.all' do
    let(:issue) do
      {
        'closed_at' => Time.parse('2012-01-15T09:20:10Z'),
        'created_at' => Time.parse('2011-04-22T13:33:48Z'),
        'id' => 2,
        'labels' => %w[bug enhancement],
        'number' => 4711,
        'state' => 'closed',
        'url' => 'https://github.com/octodog/bark/issues/4711'
      }
    end

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
      stub_const('Github::Issues::CACHE_DIR', Dir.mktmpdir)
    end

    after do
      FileUtils.remove_entry_secure(Github::Issues::CACHE_DIR)
    end

    it 'returns all issues' do
      issues = described_class.new('octodog/bark').all
      expect(issues.size).to eq(4)
    end

    it 'returns issues with correct attributes' do
      issues = described_class.new('octodog/bark').all
      expect(issues.last).to eq(issue)
    end
  end

  describe '.filtered_by_labels' do
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
      stub_const('Github::Issues::CACHE_DIR', Dir.mktmpdir)
    end

    after do
      FileUtils.remove_entry_secure(Github::Issues::CACHE_DIR)
    end

    context 'when labels match' do
      it 'returns filtered issues' do
        issues = described_class.new('octodog/bark').filtered_by_labels(['bug'])
        expect(issues.size).to eq(4)
        issues.each do |issue|
          expect(issue.labels).to include('bug')
        end
      end
    end

    context 'when labels do not match' do
      it 'returns an empty array' do
        issues = described_class.new('octodog/bark').filtered_by_labels(['nonexistent'])
        expect(issues).to be_empty
      end
    end

    context 'when labels exclude' do
      it 'returns issues excluding specified labels' do
        issues = described_class.new('octodog/bark').filtered_by_labels(['!enhancement'])
        expect(issues.size).to eq(3)
      end
    end

    context 'when both include and exclude labels are provided' do
      it 'returns issues matching include labels and excluding exclude labels' do
        issues = described_class.new('octodog/bark').filtered_by_labels(['bug', '!help wanted'])
        expect(issues.size).to eq(3)
        issues.each do |issue|
          expect(issue.labels).to include('bug')
          expect(issue.labels).not_to include('help wanted')
        end
      end
    end
  end

  describe '.all_average_closing_time' do
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
      stub_const('Github::Issues::CACHE_DIR', Dir.mktmpdir)
    end

    after do
      FileUtils.remove_entry_secure(Github::Issues::CACHE_DIR)
    end

    it 'returns the correct average closing time for all issues' do
      issues = described_class.new('octodog/bark')
      expect((issues.all_average_closing_time / 86_400).round).to eq(230)
    end
  end

  describe 'avverage_closing_time_filtered_by_labels' do
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
      stub_const('Github::Issues::CACHE_DIR', Dir.mktmpdir)
    end

    after do
      FileUtils.remove_entry_secure(Github::Issues::CACHE_DIR)
    end

    it 'returns the correct average closing time for filtered issues' do
      issues = described_class.new('octodog/bark')
      expect((issues.average_closing_time_filtered_by_labels(['bug']) / 86_400).round).to eq(230)
      expect((issues.average_closing_time_filtered_by_labels(['enhancement']) / 86_400).round).to eq(268)
    end
  end

  describe 'all_median_closing_time' do
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
      stub_const('Github::Issues::CACHE_DIR', Dir.mktmpdir)
    end

    after do
      FileUtils.remove_entry_secure(Github::Issues::CACHE_DIR)
    end

    it 'returns the correct median closing time for all issues' do
      issues = described_class.new('octodog/bark')
      expect((issues.all_median_closing_time / 86_400).round).to eq(268)
    end
  end

  describe 'median_closing_time_filtered_by_labels' do
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
      stub_const('Github::Issues::CACHE_DIR', Dir.mktmpdir)
    end

    after do
      FileUtils.remove_entry_secure(Github::Issues::CACHE_DIR)
    end

    it 'returns the correct median closing time for filtered issues' do
      issues = described_class.new('octodog/bark')
      expect((issues.median_closing_time_filtered_by_labels(['bug']) / 86_400).round).to eq(268)
      expect((issues.median_closing_time_filtered_by_labels(['enhancement']) / 86_400).round).to eq(268)
    end
  end

  describe 'per_year' do
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
      stub_const('Github::Issues::CACHE_DIR', Dir.mktmpdir)
    end

    after do
      FileUtils.remove_entry_secure(Github::Issues::CACHE_DIR)
    end

    it 'returns issues grouped per year' do
      issues = described_class.new('octodog/bark').per_year
      expect(issues.keys).to contain_exactly(2011, 2012)
    end

    it 'returns expected keys per year' do
      issues = described_class.new('octodog/bark').per_year
      issues.each_key do |year|
        expect(issues[year].size).to eq(4)
        expect(issues[year].keys).to contain_exactly('created', 'closed', 'finished', 'stats')
      end
    end

    it 'returns expected stats per year' do
      issues = described_class.new('octodog/bark').per_year
      issues.each_key do |year|
        expect(issues[year].stats.keys).to contain_exactly('ratio', 'close_time')
        expect(issues[year].stats.ratio.keys).to contain_exactly('all', 'finished')
        expect(issues[year].stats.close_time.keys).to contain_exactly('all', 'finished')
        expect(issues[year].stats.close_time.all.keys).to contain_exactly('average', 'median')
        expect(issues[year].stats.close_time.finished.keys).to contain_exactly('average', 'median')
      end
    end
  end

  describe '.per_year_filtered_by_labels' do
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
      stub_const('Github::Issues::CACHE_DIR', Dir.mktmpdir)
    end

    after do
      FileUtils.remove_entry_secure(Github::Issues::CACHE_DIR)
    end

    it 'returns issues grouped per year filtered by labels' do
      issues = described_class.new('octodog/bark').per_year_filtered_by_labels(['help wanted'])
      expect(issues.keys).to contain_exactly(2011)
    end
  end

  describe '.per_month' do
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
      stub_const('Github::Issues::CACHE_DIR', Dir.mktmpdir)
    end

    after do
      FileUtils.remove_entry_secure(Github::Issues::CACHE_DIR)
    end

    it 'returns issues grouped per month' do
      issues = described_class.new('octodog/bark').per_month(2011)
      expect(issues.keys).to contain_exactly(8, 4, 9, 5, 1)
    end

    it 'returns expected keys per month' do
      issues = described_class.new('octodog/bark').per_month(2011)
      issues.each_key do |month|
        expect(issues[month].size).to eq(4)
        expect(issues[month].keys).to contain_exactly('created', 'closed', 'finished', 'stats')
      end
    end

    it 'returns expected stats per month' do
      issues = described_class.new('octodog/bark').per_month(2011)
      issues.each_key do |month|
        expect(issues[month].stats.keys).to contain_exactly('ratio', 'close_time')
        expect(issues[month].stats.ratio.keys).to contain_exactly('all', 'finished')
        expect(issues[month].stats.close_time.keys).to contain_exactly('all', 'finished')
        expect(issues[month].stats.close_time.all.keys).to contain_exactly('average', 'median')
        expect(issues[month].stats.close_time.finished.keys).to contain_exactly('average', 'median')
      end
    end
  end

  describe '.per_month_filtered_by_labels' do
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
      stub_const('Github::Issues::CACHE_DIR', Dir.mktmpdir)
    end

    after do
      FileUtils.remove_entry_secure(Github::Issues::CACHE_DIR)
    end

    it 'returns issues grouped per month filtered by labels' do
      issues = described_class.new('octodog/bark').per_month_filtered_by_labels(2011, ['help wanted'])
      expect(issues.keys).to contain_exactly(8, 9)
    end
  end
end
