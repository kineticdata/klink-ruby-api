require 'rake'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'lib/kinetic/link'

Rake::RDocTask.new do |rdoc|
  files =['README', 'CHANGELOG', 'lib/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README"
  rdoc.title = "Kinetic Link Ruby API"
  rdoc.rdoc_dir = 'doc'
  rdoc.options << '--line-numbers' << '--inline-source'
end

spec = Gem::Specification.new do |s|
  s.name = 'klink-ruby-api'
  s.summary = 'Ruby wrapper library for Kinetic Link.'
  s.version = Kinetic::Link::VERSION
  s.has_rdoc = true
  s.extra_rdoc_files = ['README', 'CHANGELOG']
  s.rdoc_options << '--line-numbers' << '--inline-source' << '--title' << "Kinetic Link Ruby API"
  s.author = 'John Sundberg'
  s.email = 'john.sundberg@kineticdata.com'
  s.homepage = 'http://www.kineticdata.com'
  s.files = %w(README Rakefile) + Dir.glob("{config,doc,lib,test}/**/*")
  s.require_path = "lib"
  s.rubyforge_project = 'N/A'
end
Rake::GemPackageTask.new(spec)do |p|
  p.gem_spec = spec
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*.rb']
end