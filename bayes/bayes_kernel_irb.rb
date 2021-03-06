# encoding: UTF-8
#
# Bayes Persistent Kernel IRB Session
#



# Include Statements
require 'irb'
require_relative 'lib/bayes_kernel.rb'
require_relative 'lib/mantra_kernel.rb'


"""
#
# IRB Utility Functions
#
# Start of Session:
# > test = Cardinal::BayesKernel.load('data/sensory_dimensions_in_semantics')
# > test.export_pools_data( 'data/sensory_dimensions_in_semantics_data')
# > old_extract = load('emails_to_2013');0
def save(object, filename)
	data = Marshal.dump(object)
	File.open(filename, 'w') do |file|  
	  file.puts data
	end  
end
def load(filename)
	data = File.read(filename)
	return Marshal.load(data)
end
"""
#
# Start IRB Console
#
IRB.setup nil
IRB.conf[:MAIN_CONTEXT] = IRB::Irb.new.context
require 'irb/ext/multi-irb'
IRB.irb nil, self

"""
#
# Development tests
#
test1 = Cardinal::BayesKernel.new :test1
test2 = Cardinal::BayesKernel.factory :test2
test3 = Cardinal::BayesKernel.factory :test2

p test1
puts
p test2
puts
p test3
"""
