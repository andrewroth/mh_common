module Common::Pat::Profile
  def self.included(base)
    base.class_eval do
      belongs_to :project
      belongs_to :user, :foreign_key => "viewer_id"
    end
  end
end
