require 'rubygems'
require 'yaml'
require 'stemmer'
require 'classifier'

def extract_commits(path)
  files = []
  Dir.foreach(path) { |file| files << file }
  commits = files.select { |f| f != '.' && f !=  '..' }
      .map { |f| YAML::load_file(path + f) }
      .flatten
      .shuffle
  split_point = (commits.length * 0.9).floor
  [commits[0...split_point], commits[split_point...commits.length]]
end

def get_data
  @training_bad, @testing_bad = extract_commits('data/bad_commits/')
  @training_good, @testing_good = extract_commits('data/good_commits/')
end

def train_classifier
  @training_bad.each { |commit| @classifier.train_bad commit }
  @training_good.each { |commit| @classifier.train_good commit }
end

def test_classifier
  def format_ratio(ratio)
    "%2.2f\%" % (ratio * 100).to_s
  end
  false_good, true_bad = get_counts(@testing_bad)
  true_good, false_bad = get_counts(@testing_good)

  correct = true_good + true_bad
  total = correct + false_bad + false_good
  ratio = format_ratio(1.0 * correct / total)

  bad_total = false_good + true_bad
  bad_ratio = format_ratio(1.0 * true_bad / bad_total)

  good_total = true_good + false_bad
  good_ratio = format_ratio(1.0 * true_good / good_total)

  puts "Accuracy: #{ratio} (#{correct} of #{total})"
  puts "Bad commit accuracy: #{bad_ratio} (#{true_bad} of #{bad_total})"
  puts "Good commit accuracy: #{good_ratio} (#{true_good} of #{good_total})"
end

def get_counts(commits)
  classifications = commits.map { |commit| @classifier.classify commit }
  classifications.reduce([0, 0]) do |counts, classification|
    if classification == 'Good'
      [counts[0] + 1, counts[1]]
    else
      [counts[0], counts[1] + 1]
    end
  end
end

@classifier = Classifier::Bayes.new('bad', 'good')
get_data
train_classifier
test_classifier
