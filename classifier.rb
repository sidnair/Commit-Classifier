require 'rubygems'
require 'yaml'
require 'stemmer'
require 'classifier'

def extract_commits(path, do_tests)
  files = []
  Dir.foreach(path) { |file| files << file }
  commits = files.select { |f| f != '.' && f !=  '..' }
      .map { |f| YAML::load_file(path + f) }
      .flatten
      .shuffle
  if do_tests
    split_point = (commits.length * 0.9).floor
    [commits[0...split_point], commits[split_point...commits.length]]
  else
    [commits, []]
  end
end

def get_data(do_tests)
  @training_bad, @testing_bad = extract_commits('data/bad_commits/', do_tests)
  @training_good, @testing_good = extract_commits('data/good_commits/', do_tests)
end

def train_classifier
  @training_bad.each { |commit| @classifier.train_bad commit }
  @training_good.each { |commit| @classifier.train_good commit }
end

def test_classifier()
  def format_ratio(ratio)
    "%2.2f\%" % (ratio * 100).to_s
  end
  false_good, true_bad = get_counts(@testing_bad)
  true_good, false_bad = get_counts(@testing_good)

  correct = true_good.length + true_bad.length
  total = correct + false_bad.length + false_good.length
  ratio = format_ratio(1.0 * correct / total)

  bad_total = false_good.length + true_bad.length
  bad_ratio = format_ratio(1.0 * true_bad.length / bad_total)

  good_total = true_good.length + false_bad.length
  good_ratio = format_ratio(1.0 * true_good.length / good_total)

  puts "Accuracy: #{ratio} (#{correct} of #{total})"

  puts "Bad commit accuracy: #{bad_ratio} (#{true_bad.length} of #{bad_total})"
  print_failures(true_bad)

  puts "Good commit accuracy: #{good_ratio} (#{true_good.length} of #{good_total})"
  print_failures(true_good)
end

def print_failures(arr)
  if arr.length > 0
    puts "Failures:"
  end

  arr.each do |bad|
    puts "\t#{bad}"
  end
end

def get_counts(commits)
  commits.reduce([[], []]) do |counts, commit|
    classification = @classifier.classify(commit)
    if classification == 'Good'
      counts[0] << commit
    else
      counts[1] << commit
    end
    counts
  end
end

if ARGV.length == 0
  $stderr.puts 'Please do one of the following:'
  $stderr.puts 'ruby classifier.rb -t // runs tests'
  $stderr.puts 'ruby classifier.rb "commit message to check"'
  exit 1
end

do_tests = (ARGV[0] == '-t')
@classifier = Classifier::Bayes.new('bad', 'good')
get_data(do_tests)
train_classifier
if do_tests
  test_classifier
else
  puts @classifier.classify ARGV[0]
end
