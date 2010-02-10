module Common
  module MinistryCampus
    def self.included(base)
      base.class_eval do
        belongs_to :ministry
        belongs_to :campus
      end
    end

    def <=>(mc)
      self.campus.name <=> mc.campus.name
    end
  end
end
