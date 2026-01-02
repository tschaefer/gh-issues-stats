# frozen_string_literal: true

require 'tty-table'

require 'github/issues/app/base'

module Github
  class Issues
    module App
      ##
      # Command to list labels in a repository
      class LabelsCommand < BaseCommand
        TABLE_COLUMNS = 3

        parameter 'REPOSITORY', 'the repository to analyze', required: true

        def execute
          run = exec_run(@repository, @cfgfile, @cachepath, @refresh)
          labels = exec_load(run, :labels, [])
          rows = []
          labels.each_slice(TABLE_COLUMNS) do |slice|
            (TABLE_COLUMNS - slice.size).times { slice << '' } if slice.size < TABLE_COLUMNS
            rows << slice
          end
          table = TTY::Table.new(rows: rows)
          puts table.render(border_class: TTY::Table::Border::Null, resize: true, multiline: true)
          puts "\nTotal labels: #{labels.size}"
        end
      end
    end
  end
end
