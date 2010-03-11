module Legacy
  module Stats
    module Prcmethod

      def self.included(base)
        base.class_eval do
          has_many :prc, :class_name => 'Prc', :primary_key => _(:id), :foreign_key => _(:id)
        end
      end

      module PrcmethodClassMethods

        # This method will return an array of all the prc method descriptions
        def find_methods()
          find(:all, :select => _(:description)).collect{ |m| [m.description] }
        end

        # This method will return the method id associated with a given description
        def find_method_id(description)
          find(:first, :conditions => {_(:description) => description})["#{_(:id)}"]
        end

        # This method will return the method description associated witha  given id
        def find_method_description(id)
          find(:first, :conditions => {_(:id) => id})["#{_(:description)}"]
        end
      end
    end
  end
end
