# frozen_string_literal: true

require 'github/issues/app/base'

module Github
  class Issues
    module App
      ##
      # Command to show issues created per month in a given year
      class MonthCommand < BaseCommand
        parameter 'YEAR', 'the year to filter by', required: true do |value|
          Integer(value)
        end
        parameter 'REPOSITORY', 'the repository to analyze', required: true
        option '--label', 'LABEL', 'filter by label', multivalued: true
        option '--[no-]finished', :flag, 'show finished stats.', default: false
        option '--[no-]legend', :flag, 'do not print a legend.', default: true
        option '--[no-]pager', :flag, 'do not pipe output into a pager.', default: false
        option '--[no-]chart', :flag, 'show bar chart instead of table.', default: false

        def execute
          labels = @label_list || []
          run = exec_run(@repository, @cfgfile, @cachepath, @refresh)
          issues = exec_load(run, :per_month_filtered_by_labels, [year, labels])

          return exec_bailout('No issues found.') if issues.nil? || issues.empty?

          exec_output(issues)
        end
      end
    end
  end
end
