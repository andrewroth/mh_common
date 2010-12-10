module Common::Pat::User
  def self.included(base)
    base.class_eval do
      belongs_to :project
      belongs_to :viewer
    end
  end
end
