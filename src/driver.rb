require './src/commit_classifier'

if ARGV.length == 0
  $stderr.puts 'Please do one of the following:'
  $stderr.puts 'ruby classifier.rb -t // runs tests'
  $stderr.puts 'ruby classifier.rb "commit message to check"'
  exit 1
end

do_tests = (ARGV[0] == '-t')
classifier = CommitClassifier.new(do_tests)
if do_tests
  classifier.test
else
  puts classifier.classify ARGV[0]
end
