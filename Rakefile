require 'rake'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'

Rake::RDocTask.new do |rdoc|
  files =['README', 'CHANGELOG', 'ROADMAP', 'lib/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README"
  rdoc.title = "Klink Api"
  rdoc.rdoc_dir = 'doc'
  rdoc.options << '--line-numbers' << '--inline-source'
end

spec = Gem::Specification.new do |s|
  s.name = 'klink-api'
  s.summary = 'Ruby wrapper library for Kinetic Link.'
  s.version = File.open('config/VERSION', 'r') {|f| f.read }
  s.has_rdoc = true
  s.extra_rdoc_files = ['README', 'CHANGELOG', 'ROADMAP']
  s.rdoc_options << '--line-numbers' << '--inline-source' << '--title' << "Klink Api"
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