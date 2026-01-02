# frozen_string_literal: true

module Github
  class Issues
    ##
    # Mixin for grouping issues by time periods
    module Group
      private

      ##
      # Groups issues by a given period (:year, :month) and returns a hash with
      # keys as period values and values as hashes containing arrays of
      # created, closed, and finished issues
      #
      # @param list [Array<Hashie::Mash>] List of issues to group
      # @param period [Symbol] Period to group by (:year or :month)
      #
      # @return [Hashie::Mash]
      def group_by_period(list, period: :year)
        created  = list.group_by { |issue| issue.created_at.send(period) }
        created  = group_compact(created)

        closed   = list.group_by { |issue| issue.closed_at&.send(period) }
        closed   = group_compact(closed)

        finished = list.select do |issue|
          issue.state == 'closed' && issue.created_at.send(period) == issue.closed_at.send(period)
        end
        finished = finished.group_by { |issue| issue.created_at.send(period) }
        finished = group_compact(finished)

        group_merge(created, closed, finished)
      end

      ##
      # Group compaction helper removes nil keys and ensures no nil values in
      # the group hash
      #
      # @param group [Hashie::Mash] Group of issues
      #
      # @return [Hashie::Mash]
      def group_compact(group)
        group = group.reject { |k, _| k.nil? }
        group.each { |k, v| group[k] = [] if v.nil? }

        group
      end

      ##
      # Merges created, closed, and finished issue groups into a single hash
      # ensuring all keys are present in the final hash
      #
      # @param created [Hashie::Mash] Group of created issues
      # @param closed [Hashie::Mash] Group of closed issues
      # @param finished [Hashie::Mash] Group of finished issues
      #
      # @return [Hashie::Mash] Merged group of issues
      def group_merge(created, closed, finished)
        keys = created.keys | closed.keys | finished.keys
        keys.sort!.reverse!

        keys.each_with_object({}) do |key, hash|
          hash[key] = {
            created: created[key] || [],
            closed: closed[key] || [],
            finished: finished[key] || []
          }
        end
      end
    end
  end
end
