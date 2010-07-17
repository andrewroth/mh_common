module Common
  module Core
    module Au
    
      module User
        def self.included(base)
        	base.extend UserClassMethods
        end
        
				module UserClassMethods
				
					# Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
					def authenticate(login, plain_password)
						u = find(:first, :conditions => _(:old_username) + " = '#{login}'")
						u && u.authenticated?(plain_password) ? u : nil
					end
					
					# Changed for SL Intranet legacy passwords
					def encrypt(plain_password)
						md5_password = Digest::MD5.hexdigest(plain_password)
						#base64_password = Base64.encode64(md5_password).chomp
						#base64_password
					end
			  end
			end
    end
  end
end