module Common
  module Core
    module UserCode
      def self.included(base)
        base.class_eval do
          belongs_to :user
          belongs_to :login_code
          
          after_create :init
          
          validates_uniqueness_of :login_code_id, :allow_blank => true, :allow_nil => true
        end

        base.extend UserCodeClassMethods
      end

      def callback_url(base_url, controller, action)
        "#{base_url}/user_codes/#{self.login_code.code}/#{controller}/#{action}"
      end

      def pass_hash
        pass.present? ? Marshal.load(pass) : {}
      end
      

      private
      
      def init
        ::LoginCode.set_login_code_id(self)
      end

      module UserCodeClassMethods
        def new_code
          ::LoginCode.new_code
        end
      end
    end
  end
end
