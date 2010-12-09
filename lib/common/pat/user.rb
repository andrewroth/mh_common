module Common::Pat::User
  def self.included(base)
    base.class_eval do
      has_many :profiles, :foreign_key => "viewer_id"
      has_many :applns, :foreign_key => "viewer_id"
    end
  end
end
