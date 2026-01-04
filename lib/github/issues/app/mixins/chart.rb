# frozen_string_literal: true

require 'hashie/mash'
require 'unicode_plot'

module Github
  class Issues
    module App
      ##
      # Mixin to create charts for issues data
      module Chart
        private

        ##
        # Create charts for the given issues data
        #
        # @param issues [Hashie::Mash] Issues data
        #
        # @return [String] Rendered charts
        def chart_create(issues)
          values = chart_determine_values(issues)

          if %w[true 1].include?(ENV.fetch('NO_COLOR', 'false').upcase)
            "#{chart_plot_created(values)}\n\n" \
              "#{chart_plot_closed(values)}\n\n" \
              "#{chart_plot_created_closed_ratio(values)}"
          else
            chart_plot_created(values).render
            chart_plot_closed(values).render
            chart_plot_created_closed_ratio(values).render
          end
        end

        def chart_determine_values(issues)
          values = Hashie::Mash.new(
            {
              labels: [],
              created_counts: [],
              closed_counts: [],
              created_closed_ratios: []
            }
          )

          issues.each do |period, data|
            values.labels << period.to_s
            values.created_counts << (data.created&.size || 0)
            values.closed_counts << (data.closed&.size || 0)
            values.created_closed_ratios << data.stats.ratio.all.round(2)
          end

          values
        end

        ##
        # Create the created issues barplot
        #
        # @return [UnicodePlot::Barplot] Created issues barplot
        def chart_plot_created(data)
          UnicodePlot.barplot(
            data.labels,
            data.created_counts,
            title: 'Created',
            color: :red,
            width: 60
          )
        end

        ##
        # Create the closed issues barplot
        #
        # @return [UnicodePlot::Barplot] Closed issues barplot
        def chart_plot_closed(data)
          UnicodePlot.barplot(
            data.labels,
            data.closed_counts,
            title: 'Closed',
            color: :green,
            width: 60
          )
        end

        ##
        # Create the created/closed ratio barplot
        #
        # @return [UnicodePlot::Barplot] Created/Closed ratio barplot
        def chart_plot_created_closed_ratio(data)
          UnicodePlot.barplot(
            data.labels,
            data.created_closed_ratios,
            title: 'Created/Closed Ratio',
            color: :blue,
            width: 60
          )
        end
      end
    end
  end
end
