module Legacy
  module Hrdb
    module CimHrdbPriv

      def self.included(base)
        base.class_eval do
          belongs_to :person
          belongs_to :priv
        end
      end

    end
  end
end
