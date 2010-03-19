module Legacy
  module Hrdb
    module Gender

      def self.included(base)
        base.class_eval do
          validates_no_association_data :people

          has_many :people, :foreign_key => _(:gender_id, :person)
        end

        base.extend GenderClassMethods
      end

      # these constants must equal their respective records in the genders table
      MALE = "Male"
      FEMALE = "Female"
      UNKNOWN = "???"

      module GenderClassMethods
        def get_all_genders(order_field = :id, order = "DESC")
          order = order.upcase
          order = "DESC" if (order != "ASC" && order != "DESC")

          Gender.all(:order => _(order_field) + " " + order + ", " + _(:id) + " " + order)
        end
      end

    end
  end
end
