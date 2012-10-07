require 'rubygems'
require 'yaml'
require 'stemmer'
require 'classifier'

# Classifies commits as good or bad.
class CommitClassifier

  # Initializes the commit classifier - extracts the necessary data and does the
  # training.
  #
  # @param [String] do_tests whether the classifier should partition some of the
  # training data for testing or if it should all be used for training.
  def initialize(do_tests)
    @classifier = Classifier::Bayes.new('bad', 'good')
    @do_tests = do_tests
    get_data
    train
  end

  # Classifies the commit and returns a string representation of the result.
  #
  # @param [String] commit the commit to classify
  # @return [String] result of the classification. 'Good' or 'Bad'
  def classify(commit)
    @classifier.classify(commit)
  end

  # Runs tests on the training data and prints details. Assumes that the
  # classifier has already been trained.
  #
  # @return [void]
  def test
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

  private

  # Extracts training and testing commits.
  def get_data
    @training_bad, @testing_bad = extract_commits('data/bad_commits/')
    @training_good, @testing_good = extract_commits('data/good_commits/')
  end

  # Trains the classifier.
  def train
    @training_bad.each { |commit| @classifier.train_bad commit }
    @training_good.each { |commit| @classifier.train_good commit }
  end

  # Reads in commits from all the YAML files in a directory. Assumes that the
  # directory has only YAML files.
  #
  # @param [String] path
  # @return [Array<String>, Array<String] training data, testing data
  def extract_commits(path)
    files = []
    Dir.foreach(path) { |file| files << file }
    commits = files.select { |f| f != '.' && f !=  '..' }
        .map { |f| YAML::load_file(path + f) }
        .flatten
        .shuffle
    if @do_tests
      split_point = (commits.length * 0.9).floor
      [commits[0...split_point], commits[split_point...commits.length]]
    else
      [commits, []]
    end
  end

  # Counts the number of good and bad commits in an array of commits
  #
  # @param [Array<String>] commits array of commits to be identified
  # @return [Integer, Integer] good count, bad count
  def get_counts(commits)
    commits.reduce([[], []]) do |counts, commit|
      classification = self.classify(commit)
      if classification == 'Good'
        counts[0] << commit
      else
        counts[1] << commit
      end
      counts
    end
  end

  # Prints each of the incorrectly identified commits
  #
  # @param [Array<String>] arr array of incorrectly identified commits
  def print_failures(arr)
    if arr.length > 0
      puts "Failures:"
    end

    arr.each do |bad|
      puts "\t#{bad}"
    end
  end

  # Formats a number into printable output.
  #
  # @param [Float] n
  def format_ratio(n)
    "%2.2f\%" % (n * 100).to_s
  end
end
