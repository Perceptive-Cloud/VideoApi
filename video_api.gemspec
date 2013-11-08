require "rake"

# run rake cruise:video_api_symlinks on build servers after any version changes here
spec = Gem::Specification.new do |s|
  s.name        = "video_api"
  s.version     = "1.1.8.5"
  s.summary     = "Wrapper library for the video API"
  s.description = "Provides helper libraries for Ruby access to the Twistage API"
  s.authors     = ["Twistage"]
  s.email       = "kbaird@twistage.com"
  s.files       = FileList["lib/**.rb", "spec/**.rb", "LICENSE", "README.md"]
  s.has_rdoc    = true
  s.platform    = Gem::Platform::RUBY
  s.add_dependency "json",       ">= 1.5.4"
  s.add_dependency "mime-types", ">= 1.16"
  s.license     = "3-Clause BSD"
end

