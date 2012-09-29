require 'rubygems'
require 'yaml'
require 'stemmer'
require 'classifier'

def extract_commits(path)
  files = []
  Dir.foreach(path) { |file| files << file }
  files.select { |f| f != '.' && f !=  '..' }
      .map { |f| YAML::load_file(path + f) }
      .flatten
end

def train_classifier
  extract_commits('data/training/bad_commits/').each { |commit| @classifier.train_bad commit }
  extract_commits('data/training/good_commits/').each { |commit| @classifier.train_good commit }
end

if ARGV.length == 0
  $stderr.puts "Please provide a string to classify"
  exit 1
end

@classifier = Classifier::Bayes.new('bad', 'good')
train_classifier
puts @classifier.classify ARGV[0]
