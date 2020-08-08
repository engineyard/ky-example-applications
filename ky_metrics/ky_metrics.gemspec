$:.push File.expand_path("../lib", __FILE__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ky_metrics"
  s.version     = "0.1.0"
  s.authors     = ["Ilias Giannoulas"]
  s.email       = ["igiannoulas@engineyard.com"]
  s.homepage    = "https:///engineyard.com"
  s.summary     = "Summary of KyMetrics."
  s.description = "Description of KyMetrics."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
 
  #s.add_dependency "rails", "~> 5.0.7", ">= 5.0.7.2"

  #s.add_development_dependency "sqlite3"
end
