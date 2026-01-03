# frozen_string_literal: true

require 'clamp'

module Github
  class Issues
    module App
      ##
      # Base command class
      #
      # Inherits from Clamp::Command and includes mixins and is inherited by
      # the specific command classes
      class Base < Clamp::Command
        include Github::Issues::App::Chart
        include Github::Issues::App::Exec
        include Github::Issues::App::Legend
        include Github::Issues::App::Options
        include Github::Issues::App::Statistics
        include Github::Issues::App::Table

        option ['-m', '--man'], :flag, 'show manpage' do # rubocop:disable Metrics/BlockLength
          manpage = <<~MANPAGE
            Name:
                github-issues - Analyse Github repository issues lifecycle.

            #{help}

            Description:
                github-issues is a command-line tool that helps you analyze and
                understand the issues lifecycle in any GitHub repository. It provides
                detailed statistics, visualizations, and insights about issues including:

                - Issue creation trends over time (yearly/monthly breakdowns)
                - Closing time statistics (average and median)
                - Label-based filtering and analysis
                - Visual charts and tables for data representation
                - Cached data for faster subsequent queries

            Commands:
                yearly REPOSITORY
                    Display yearly statistics for a repository.

                monthly YEAR REPOSITORY
                    Display monthly statistics for a specific year.

                labels REPOSITORY
                    Display all labels used in a repository.

            Options:
                --configuration-file FILE
                    Specify a configuration file (default: ~/.config/github-issues.json)

                --cache-path PATH
                    Specify cache path (default: ~/.cache/github-issues)

                --refresh INTERVAL
                    Set refresh interval (e.g., 30minutes, 2.5hours, 1day) (default: 24hours)

                --label LABEL
                    Filter by specific label (can be used multiple times; prefix with '!' to exclude)

                --[no-]finished
                    Show finished stats (default: false) (statistics about created and closed issues in the same period)

                --[no-]legend
                    Toggle legend display (default: true)

                --[no-]pager
                    Toggle output paging (default: false)

                --[no-]chart
                    Show bar chart instead of table (default: false)

                -v, --version
                    Show version information

                -m, --man
                    Show this manual page

            Examples:
                Display yearly statistics for a repository:
                    $ github-issues yearly rails/rails

                Display monthly statistics for a specific year:
                    $ github-issues monthly 2023 rails/rails

                Filter issues by multiple labels:
                    $ github-issues yearly rails/rails --label bug --label '!enhancement'

                Show monthly breakdown with chart visualization:
                    $ github-issues monthly 2023 rails/rails --chart

                Use with custom refresh interval:
                    $ github-issues yearly rails/rails --refresh 2hours

                List all labels in a repository:
                    $ github-issues labels rails/rails

            Configuration:
                For higher API rate limits, you can provide GitHub credentials through
                a JSON configuration file. The configuration file will be loaded from
                the path specified via --configuration-file (default: ~/.config/github-issues.json).

            Caching:
                Issue data is cached locally in the specified cache path --cache-path
                (default: ~/.cache/github-issues) to improve performance on subsequent
                queries. The cache is automatically refreshed based on the refresh interval
                (default: 24 hours).

            Author:
                Tobias Schäfer <github@blackox.org>

            Homepage:
                https://github.com/tschaefer/github-issues
          MANPAGE
          TTY::Pager.page(manpage)

          exit 0
        end

        option ['-v', '--version'], :flag, 'show version' do
          puts "github-issues #{Github::Issues::VERSION}"
          exit 0
        end
      end
    end
  end
end
