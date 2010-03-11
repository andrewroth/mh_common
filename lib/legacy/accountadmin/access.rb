module Legacy
  module Accountadmin
    module Access

      def self.included(base)
        base.class_eval do
          belongs_to :user, :class_name => "User", :foreign_key => "viewer_id"
          belongs_to :person, :class_name => "Person", :foreign_key => "person_id"
        end
      end

    end
  end
end
