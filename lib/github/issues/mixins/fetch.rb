# frozen_string_literal: true

require 'octokit'
require 'time'

module Github
  class Issues
    ##
    # Mixin for fetching issues from GitHub and the database
    module Fetch
      private

      ##
      # Ensure the database is up-to-date with issues from GitHub, if the
      # refresh interval has passed or if there are no issues in the database,
      # fetch issues from GitHub and update the database
      #
      # @param database [Database] Issues database
      # @param refresh [Integer] Refresh interval in seconds
      # @param credentials [Hash] GitHub API credentials
      # @param repository [String] GitHub repository (e.g., 'owner/repo')
      #
      # @return [void]
      def ensure_issues_loaded(database, refresh, credentials, repository)
        return unless database.needs_update?(refresh) || database.count_issues.zero?

        fetch_and_update_issues(database, credentials, repository)
      end

      ##
      # Fetch issues from GitHub and update the database
      #
      # @param database [Database] Issues database
      # @param credentials [Hash] GitHub API credentials
      # @param repository [String] GitHub repository (e.g., 'owner/repo')
      #
      # @return [void]
      def fetch_and_update_issues(database, credentials, repository)
        cached_timestamp = database.cache_timestamp
        fetch_timestamp = Time.now

        if cached_timestamp
          new_issues = fetch_issues_from_github(
            credentials,
            repository,
            since: cached_timestamp
          )

          database.store_issues(new_issues, fetch_timestamp) unless new_issues.empty?
        else
          all_issues = fetch_issues_from_github(credentials, repository)
          database.store_issues(all_issues, fetch_timestamp)
        end
      end

      ##
      # Fetch issues from GitHub
      #
      # @param credentials [Hash] GitHub API credentials
      # @param repository [String] GitHub repository (e.g., 'owner/repo')
      # @param since [Time, nil] Optional timestamp to fetch issues updated since this time
      #
      # @return [Array<Sawyer::Resource>] The fetched issues
      def fetch_issues_from_github(credentials, repository, since: nil)
        octokit = Octokit::Client.new(credentials)
        octokit.auto_paginate = true

        options = {
          state: 'all',
          sort: 'created',
          direction: 'desc'
        }
        options[:since] = since.utc.iso8601 if since

        octokit.issues(repository, options)
               .reject { |issue| issue.pull_request || issue.draft }
      end

      def github_repository_exist!(credentials, repository)
        octokit = Octokit::Client.new(credentials)
        octokit.repository(repository)
      end

      ##
      # Fetch issues from the database applying the given labels filter
      #
      # @param database [Database] Issues database
      # @param labels [Array<String>, nil] Labels to filter issues by
      #
      # @return [Array<Hashie::Mash>] Filtered issues
      def fetch_issues_from_database(database, labels: nil)
        return database.all_issues if labels.nil? || labels.empty?

        include_labels, exclude_labels = group_include_exclude_labels(labels)

        database.all_issues.select do |issue|
          has_includes = include_labels.all? { |label| issue.labels.include?(label) }
          has_excludes = exclude_labels.any? { |label| issue.labels.include?(label) }
          has_includes && !has_excludes
        end
      end

      ##
      # Separating include and exclude labels
      #
      # @param labels [Array<String>] Labels to filter issues by
      #
      # @return [Array<Array<String>, Array<String>>] Include and exclude labels
      def group_include_exclude_labels(labels)
        include_labels = labels.reject { |label| label.start_with?('!') }
        exclude_labels = labels.select { |label| label.start_with?('!') }.map { |label| label[1..] }

        [include_labels, exclude_labels]
      end
    end
  end
end
