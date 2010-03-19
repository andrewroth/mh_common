class ActiveSupport::OrderedHash
  def sorted_hash(&block)
    self.class[sort(&block)]
  end
end