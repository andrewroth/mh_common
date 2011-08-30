module Common
  module Core
    module EventGroup
      def self.included(base)
        base.class_eval do

          has_many :events
          
          validates_no_association_data :events

          acts_as_tree
        end
      end

      def to_s_with_eg_path
        "#{eg_path}"
      end

      def eg_path
        visited = { self => true }

        eg_path = ''
        node = self
        while !node.nil?
          eg_path = eg_path.empty? ? node.title : (node.title + ' - ' + eg_path)
          node = node.parent

          if visited[node]
            node = nil
          else
            visited[node] = true
          end
        end

        eg_path
      end

    end
  end
end
