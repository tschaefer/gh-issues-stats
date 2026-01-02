# frozen_string_literal: true

require 'pastel'
require 'tty-pager'
require 'tty-spinner'

require 'github/issues'

module Github
  class Issues
    module App
      ##
      # Mixin for execution methods
      module Exec
        private

        ##
        # Bail out of execution with an error message
        #
        # @param message [String] Error message to display
        def exec_bailout(message)
          warn Pastel.new.red.bold(message)
          exit 1
        end

        ##
        # Initialize and return the GitHub Issues instance
        #
        # @param repository [String] GitHub repository in 'owner/repo' format
        # @param config_file [String, nil] Path to the configuration file
        # @param refresh_interval [String, nil] Refresh interval for caching
        #
        # @return [Github::Issues] Initialized GitHub Issues instance
        def exec_run(repository, config_file, cache_path, refresh_interval)
          credentials = options_parse_configuration(config_file)
          refresh_seconds = options_parse_refresh_interval(refresh_interval)
          if cache_path.nil? || cache_path.empty?
            Github::Issues.new(
              repository,
              credentials:,
              refresh:
              refresh_seconds
            )
          else
            Github::Issues.new(
              repository,
              credentials:,
              cache: cache_path,
              refresh: refresh_seconds
            )
          end
        rescue Octokit::NotFound
          exec_bailout("Repository '#{repository}' not found.")
        rescue StandardError => e
          exec_bailout(e.message)
        end

        ##
        # Execute the specified method on the GitHub Issues instance with a
        # loading spinner
        #
        # @param run [Github::Issues] GitHub Issues instance
        # @param method [Symbol] Method to call on the instance
        # @param args [Array] Arguments to pass to the method
        #
        # @return [Object] Result of the method call
        def exec_load(run, method, args)
          results = nil
          spinner = TTY::Spinner.new(':spinner Fetching data ...', format: :dots, clear: true)
          spinner.run("Done.\n") do
            results = run.send(method, *args)
          end

          results
        end

        def exec_output(issues, extra: nil)
          content = chart? ? chart_create(issues) : table_create(issues, finished?)
          legend = legend_create(issues, legend?, extra:)

          TTY::Pager.new(enabled: pager?).page("#{content}#{legend}")
        end
      end
    end
  end
end
