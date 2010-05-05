module Pulse
  module Ca
    module Person

      def self.included(base)
        base.class_eval do
          def gender()
            case gender_id
            when CIM_MALE_GENDER_ID
              US_MALE_GENDER_ID
            when CIM_FEMALE_GENDER_ID
              US_FEMALE_GENDER_ID
            else
              nil
            end
          end
        end
      end
    end
  end
end
