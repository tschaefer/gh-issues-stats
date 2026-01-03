# frozen_string_literal: true

require 'sqlite3'
require 'json'
require 'time'

module Github
  class Issues
    ##
    # Database class manages the SQLite database for storing GitHub issues
    class Database
      include Marshal
      include Schema
      include Store

      ##
      # Database connection handle
      attr_reader :connection

      ##
      # Path to the database file
      attr_reader :path

      ##
      # Initialize the Database instance
      #
      # @param path [String] Path to the SQLite database file
      #
      # @return [Github::Issues::Database] Initialized Database instance
      def initialize(path)
        @path = path
        @connection = SQLite3::Database.new(@path)
        @connection.results_as_hash = true

        schema_create(connection)
      end

      ##
      # Close the database connection
      def close
        connection.close
      end

      ##
      # Store a list of issues and update the last fetch timestamp
      #
      # @param issues [Array<Sawyer::Ressource>] List of issues to store
      # @param timestamp [Time] Timestamp of the fetch operation
      #
      # @return [void]
      def store_issues(issues, timestamp)
        connection.transaction do
          issues.each do |issue|
            store_issue(connection, issue)
          end
          store_metadata(connection, 'last_fetch', timestamp.utc.iso8601)
        end
      end

      ##
      # Retrieve all stored issues from the database
      #
      # @return [Array<Issues>] List of stored issues
      def all_issues
        rows = connection.execute('SELECT * FROM issues ORDER BY created_at DESC')
        rows.map { |row| marshal_issue(row) }
      end

      ##
      # Retrieve all unique labels from the stored issues
      #
      # @return [Array<String>] List of unique labels
      def all_labels
        rows = connection.execute('SELECT labels FROM issues')
        label_set = Set.new
        rows.each do |row|
          labels = JSON.parse(row['labels'] || '[]')
          labels.each do |label|
            label_set.add(label)
          end
        end
        label_set.to_a
      end

      ##
      # Count the total number of stored issues
      #
      # @return [Integer] Total number of issues
      def count_issues
        connection.get_first_value('SELECT COUNT(*) FROM issues')
      end

      ##
      # Determine if the database needs to be updated based on the age of the
      # last fetch timestamp
      #
      # @param max_age_seconds [Integer] Maximum age in seconds before the database is considered stale
      #
      # @return [Boolean] True if the database needs to be updated, false
      # otherwise
      def needs_update?(max_age_seconds = 86_400)
        timestamp = cache_timestamp
        return true unless timestamp

        (Time.now - timestamp) >= max_age_seconds
      end

      ##
      # Retrieve a metadata value by key
      #
      # @param key [String] Metadata key
      #
      # @return [String, nil] Metadata value or nil if not found
      def metadata(key)
        row = connection.get_first_row('SELECT value FROM metadata WHERE key = ?', key)
        return nil unless row

        row['value']
      end

      ##
      # Retrieve the timestamp of the last fetch operation
      #
      # @return [Time, nil] Timestamp of the last fetch or nil if not found
      def cache_timestamp
        timestamp_str = metadata('last_fetch')
        return nil unless timestamp_str

        Time.parse(timestamp_str)
      end
    end
  end
end
