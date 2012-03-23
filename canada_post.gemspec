# encoding: UTF-8

Gem::Specification.new do |s|
  s.platform     = Gem::Platform::RUBY
  s.name         = 'canada_post'
  s.version      = '0.1.0'
  s.author       = 'Alex Tsokurov'
  s.email        = 'me@ximik.net'
  s.summary      = 'A Simple Ruby Class that communicates with Canada Post Server and provides a shipping estimate.'
  s.homepage     = 'http://github.com/Ximik/CanadaPost'

  s.files        = `git ls-files`.split("\n")

  s.add_dependency 'builder'

  s.has_rdoc = true
  s.extra_rdoc_files << 'README.rdoc'
end
