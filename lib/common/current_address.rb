module Common
  module Core
    module CurrentAddress
      def self.included(base)
        base.class_eval do
          load_mappings
          validates_format_of   _(:email),
                                :with       => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i,
                                :message    => 'must be valid'
          before_create :set_address_type
        end
      end

      def set_address_type
        self.address_type = "current"
      end
    end
  end
end
