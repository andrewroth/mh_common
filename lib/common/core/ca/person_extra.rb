module Common
  module Core
    module Ca
      module PersonExtra

        def self.included(base)
          base.class_eval do
            belongs_to :person
          end
        end
        
      end
    end
  end
end
