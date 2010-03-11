module Legacy
  module Accountadmin
    module AccountadminAccesscategory

      def self.included(base)
        base.class_eval do
          has_many :accountadmin_accessgroups, :foreign_key => :accesscategory_id

          validates_presence_of _(:key)
          validates_uniqueness_of _(:key)
          validates_length_of _(:key), :maximum => 50
          validates_format_of _(:key), :with => /\[*\]/, :message => "must be surrounded by brackets, for example: [key7]"
          validates_no_association_data :accountadmin_accessgroups
        end
      end

    end
  end
end
