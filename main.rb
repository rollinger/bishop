#
#
#
require_relative "pdt-lib.rb"

include ProbabilisticDecisionTree

filename = ARGV[0]

daemon = Daemon.deserialize(filename)

trainer = Trainer.new(daemon)

trainer.train_by_cmd(verbose=true)

#daemon.serialize(filename)
