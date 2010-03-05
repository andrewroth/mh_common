require 'futils'

namespace :db do
  namespace :migrate do
    namespace :copy do
      Dir["#{File.dirname(__FILE__)}/../../db/migrate/*"].each do |dir|
        Dir["#{dir}/*"].each do |file|
          File.copy file, Rails.root.join("db/migrate/")
        end
      end
    end
  end
end
