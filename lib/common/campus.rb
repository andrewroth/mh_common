module Common
  module Campus
    def self.included(base)
      base.class_eval do
        has_many :campus_involvements
        has_many :people, :through => :campus_involvements
        has_many :groups
        # has_many :bible_studies
        has_many :ministry_campuses, :include => :ministry
        has_many :ministries, :through => :ministry_campuses, :order => ::Ministry.table_name+'.'+_(:name, :ministry)
        has_many :dorms
      end
    end

    # returns <abbrev> the abbreviated name of campus if it exists, 
    # otherwise <name> the fullname
    def short_name
      self.abbrv.to_s.empty? ? self.name : self.abbrv
    end

    # Comperable - allows campuses to be compared based on their names
    def <=>(other)
      name <=> other.name
    end

    #liquid_methods
    def to_liquid
      { "name" => name }
    end
  end
end
