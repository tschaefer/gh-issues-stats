# frozen_string_literal: true

require 'tty-table'

module Github
  class Issues
    module App
      ##
      # Main command class
      class Command < Base
        option '--configuration-file', 'FILE', 'configuration file', attribute_name: :cfgfile
        option '--cache-path', 'PATH', 'cache path', attribute_name: :cachepath
        option '--refresh', 'INTERVAL', 'refresh interval (e.g., 30minutes, 2.5hours, 1day)'

        subcommand 'yearly', 'Show issues per year.', Year
        subcommand 'monthly', 'Show issues per month.', Month
        subcommand 'labels', 'List all labels.', Labels
      end
    end
  end
end
