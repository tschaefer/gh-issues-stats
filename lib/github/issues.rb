# frozen_string_literal: true

require 'fileutils'
require 'hashie'

require 'github/issues/database'
require 'github/issues/mixins/statistics'
require 'github/issues/mixins/fetch'
require 'github/issues/mixins/group'

module Github
  ##
  # Main class for analyzing GitHub issues
  class Issues
    include Statistics
    include Fetch
    include Group

    CACHE_DIR = File.join(Dir.home, '.cache', 'github-issues').freeze
    DATABASE_NAME = 'issues.db'

    ##
    # Repository to analyze (e.g., 'owner/repo')
    attr_reader :repository

    ## Cache path for storing database file
    attr_reader :cache

    ##
    # Credentials for GitHub API access
    attr_reader :credentials

    ##
    # Database instance for storing and retrieving issues
    attr_reader :database

    ##
    # Refresh interval in seconds for updating the stored issues
    attr_reader :refresh

    ##
    # Initialize the Issues analyzer
    #
    # @param repository [String] GitHub repository (e.g., 'owner/repo')
    # @param cache [String] Path to cache directory
    # @param credentials [Hash] Optional GitHub API credentials
    # @param refresh [Integer] Refresh interval in seconds (default: 86400)
    #
    # @return [Github::Issues] The initialized issues analyzer
    def initialize(repository, cache: CACHE_DIR, credentials: {}, refresh: 86_400)
      @repository = repository
      @credentials = credentials
      @refresh = refresh

      dir = File.join(cache, repository)
      FileUtils.mkdir_p(dir)
      @cache = dir

      database_path = File.join(dir, DATABASE_NAME)
      github_repository_exist!(credentials, repository) unless File.exist?(database_path)
      @database = Database.new(database_path)

      at_exit do
        database.close
      end
    end

    ##
    # Get all unique labels from the issues
    #
    # @return [Array<String>] List of unique labels
    def labels
      ensure_issues_loaded(database, refresh, credentials, repository)
      database.all_labels
    end

    ##
    # List all issues
    #
    # @return [Array<Hashie::Mash>] List of issues
    def all
      ensure_issues_loaded(database, refresh, credentials, repository)
      fetch_issues_from_database(database)
    end

    ##
    # List issues filtered by labels
    #
    # @param labels [Array<String>] List of labels to filter issues
    #
    # @return [Array<Hashie::Mash>] List of filtered issues
    def filtered_by_labels(labels)
      ensure_issues_loaded(database, refresh, credentials, repository)
      fetch_issues_from_database(database, labels:)
    end

    ##
    # Total average closing time of all issues
    #
    # @return [Float] Average closing time in seconds
    def all_average_closing_time
      average_closing_time_filtered_by_labels([])
    end

    ##
    # Total average closing time of all issues filtered by labels
    #
    # @param labels [Array<String>] List of labels to filter issues
    #
    # @return [Float] average closing time in seconds
    def average_closing_time_filtered_by_labels(labels)
      ensure_issues_loaded(database, refresh, credentials, repository)
      list = fetch_issues_from_database(database, labels:)
      return 0 if list.empty?

      closed = list.select { |issue| issue.state == 'closed' }
      stats_average_closing_time(closed)
    end

    ##
    # Total median closing time of all issues
    #
    # @return [Float] Median closing time in seconds
    def all_median_closing_time
      median_closing_time_filtered_by_labels([])
    end

    ##
    # Total median closing time of all issues filtered by labels
    #
    # @param labels [Array<String>] List of labels to filter issues
    #
    # @return [Float] Median closing time in seconds
    def median_closing_time_filtered_by_labels(labels)
      ensure_issues_loaded(database, refresh, credentials, repository)
      list = fetch_issues_from_database(database, labels:)
      return 0 if list.empty?

      closed = list.select { |issue| issue.state == 'closed' }
      stats_median_closing_time(closed)
    end

    ##
    # Issues grouped per year with optional statistics
    #
    # @param stats [Boolean] Whether to include statistics for each year
    #
    # @return [Hashie::Mash] Issues grouped by year with optional statistics
    def per_year(stats: true)
      per_year_filtered_by_labels([], stats:)
    end

    ##
    # Issues grouped per year filtered by labels with optional statistics
    #
    # @param labels [Array<String>] List of labels to filter issues
    # @param stats [Boolean] Whether to include statistics for each year
    #
    # @return [Hashie::Mash] Issues grouped by year with optional statistics
    def per_year_filtered_by_labels(labels, stats: true)
      ensure_issues_loaded(database, refresh, credentials, repository)
      list = fetch_issues_from_database(database, labels:)
      return if list.empty?

      hash = group_by_period(list)
      hash.each_key { |year| hash[year][:stats] = stats_combined(hash[year]) } if stats

      Hashie::Mash.new(hash)
    end

    ##
    # Issues grouped per month for a specific year with optional statistics
    #
    # @param year [Integer] Year to filter issues
    # @param stats [Boolean] Whether to include statistics for each month
    #
    # @return [Hashie::Mash] Issues grouped by month with optional statistics
    def per_month(year, stats: true)
      per_month_filtered_by_labels(year, [], stats:)
    end

    ##
    # Issues grouped per month for a specific year filtered by labels with
    # optional statistics
    #
    # @param year [Integer] Year to filter issues
    # @param labels [Array<String>] List of labels to filter issues
    # @param stats [Boolean] Whether to include statistics for each month
    #
    # @return [Hashie::Mash] Issues grouped by month with optional statistics
    def per_month_filtered_by_labels(year, labels, stats: true)
      ensure_issues_loaded(database, refresh, credentials, repository)
      list = fetch_issues_from_database(database, labels:)
      return if list.empty?

      list = list.select { |issue| issue.created_at.year == year }
      return if list.empty?

      hash = group_by_period(list, period: :month)
      hash.each_key { |month| hash[month][:stats] = stats_combined(hash[month]) } if stats

      Hashie::Mash.new(hash)
    end
  end
end
