module Common
  module Core
    module UserCode
      def self.included(base)
        base.class_eval do
          belongs_to :user
          belongs_to :login_code
          
          after_create :init
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
        lc = ::LoginCode.new
        lc.save!
        self.login_code_id = lc.id
        self.save!
      end

      module UserCodeClassMethods
        def new_code
          ::LoginCode.new_code
        end
      end
    end
  end
end
