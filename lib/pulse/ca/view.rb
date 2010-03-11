module Pulse
  module Ca
    module View

      def build_query_parts_custom_tables
        [ 'Access' ]
      end

      def build_query_parts_custom_tables_clause
        " LEFT JOIN #{Access.table_name} as Access on Person.#{_(:id, :person)} = Access.person_id"
      end

    end
  end
end
