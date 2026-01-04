# frozen_string_literal: true

module Github
  class Issues
    module App
      ##
      # Command to show issue stats per year
      class Year < Base
        parameter 'REPOSITORY', 'the repository to analyze', required: true
        option '--format', 'FORMAT', 'specify output format (table, chart, json).', default: 'table'
        option '--label', 'LABEL', 'filter by label', multivalued: true
        option '--[no-]finished', :flag, 'show finished stats.', default: false
        option '--[no-]legend', :flag, 'do not print a legend.', default: true
        option '--[no-]pager', :flag, 'do not pipe output into a pager.', default: false

        def execute
          labels = @label_list || []
          run = exec_run(@repository, @cfgfile, @cachepath, @refresh)
          issues = exec_load(run, :per_year_filtered_by_labels, [labels])

          return exec_bailout('No issues found.') if issues.nil? || issues.empty?

          average = stats_seconds_to_days(run.all_average_closing_time)
          median  = stats_seconds_to_days(run.all_median_closing_time)
          extra   = "#{average} days average closing time. #{median} days median closing time."

          exec_output(issues, format, extra:)
        end
      end
    end
  end
end
