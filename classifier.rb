require 'rubygems'
require 'yaml'
require 'stemmer'
require 'classifier'

bad_commits = YAML::load_file('bad_commits.yml')
good_commits = YAML::load_file('vim_commits.yml').concat(YAML::load_file('linux_commits.yml'))
classifier = Classifier::Bayes.new('bad', 'good')

bad_commits.each { |commit| classifier.train_bad commit }
good_commits.each { |commit| classifier.train_good commit }

if ARGV.length == 0
  $stderr.puts "Please provide a string to classify"
  exit 1
end

puts classifier.classify ARGV[0]
