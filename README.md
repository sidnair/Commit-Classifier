# Commit classifier

Simple script that classifies commits as good or bad. It uses a naive Bayes
model.

## Usage
Running `ruby src/driver.rb -t` will partition the data into test and training
data and output its accuracy.

Running `ruby src/driver.rb "my commit message"` will train the classifier on all
the available training data and then classify the specified commit.

You can generate documentation with `yardoc`.
