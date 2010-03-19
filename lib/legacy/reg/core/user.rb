module Legacy
  module Reg
    module Core
      module User

        def self.included(base)
          base.class_eval do
            has_many :super_admins
            has_many :event_admins
            has_many :accesses
          end
        end

      end
    end
  end
end
