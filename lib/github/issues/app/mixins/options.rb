# frozen_string_literal: true

require 'json'

module Github
  class Issues
    module App
      ##
      # Mixin for option parsing methods
      module Options
        DEFAULT_CONFIG_FILE = File.join(Dir.home, '.config/github-issues.json').freeze

        private

        ##
        # Parse refresh interval option and transforms strings like
        # '30minutes', '2hours', '1day' into seconds
        #
        # @param interval [String, nil] Refresh interval string
        #
        # @return [Float] Refresh interval in seconds
        def options_parse_refresh_interval(interval)
          interval ||= '24hours'
          match = interval.match(/^(\d+(?:\.\d+)?)(seconds?|minutes?|hours?|days?)$/)

          unless match
            raise "Invalid refresh interval format: '#{interval}'. " \
                  "Use format like '30minutes', '2hours', '1day'"
          end

          value = match[1].to_f
          unit = match[2]

          case unit
          when /^seconds?$/
            value
          when /^minutes?$/
            value * 60
          when /^hours?$/
            value * 60 * 60
          when /^days?$/
            value * 60 * 60 * 24
          else
            raise "Unknown time unit: #{unit}"
          end
        end

        ##
        # Parse configuration file option and loads JSON configuration from the
        # specified file or default location
        #
        # @param file [String, nil] Path to configuration file
        #
        # @return [Hash] Configuration options
        def options_parse_configuration(file)
          file ||= DEFAULT_CONFIG_FILE
          File.exist?(file) ? JSON.load_file(file).transform_keys(&:to_sym) : {}
        rescue JSON::ParserError
          raise "Failed to parse configuration file '#{file}'"
        end

        ##
        # Parse cache path option and returns the specified path or
        # a default cache path
        #
        # @param path [String, nil] Path to cache directory
        #
        # @return [String] Cache directory path
        def options_parse_cache_path(path)
          path || File.join(Dir.home, '.cache', 'github-issues')
        end
      end
    end
  end
end
