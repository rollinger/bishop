# encoding: UTF-8
#
# Bayes Persistent Kernel Implementation
#
# The library extends the Object Base Class adding

require_relative 'bishop.rb'

#
# Extends Object Base Class with BPK related functions and marshalling 
#
class Object
	#
	# General Marshalling Methods
	#
	
	# Save an Object
	def save(filename=nil)
		@marshal_filename = filename if filename
		data = Marshal.dump(self)
		if @marshal_filename
			begin
				File.open(@marshal_filename, 'w') do |file|  
				  file.puts data
				end
			rescue
				@marshal_filename = nil
			end
		end
		return @marshal_filename
	end
	
	# Load Object (Classmethod)
	def self.load(filename)
		begin
			data = File.read(filename)
			return Marshal.load(data)
		rescue
			return nil
		end
	end
	
	
	
	#
	# Bayes Persistent Kernel Methods
	#
	
	# Get all kernels in Object Space (Classmethod); Returns Hash: name=>object
	def self.get_all_bayes_kernels(kernel_klass=Cardinal::BayesKernel)
		kernels = {}
		ObjectSpace.each_object kernel_klass do |kernel|
		  kernels[kernel.name]= kernel
		end
		return kernels
	end
	
	# Get specific kernels in Object Space (Classmethod)
	def self.get_bayes_kernel_by_name( kernel_name, kernel_klass=Cardinal::BayesKernel )
		kernels = self.class.get_all_bayes_kernels( kernel_klass )
		return kernels[kernel_name]
	end
	
	# Classifies self with a given kernel; Returns Category
	def guess( kernel_name, kernel_klass=Cardinal::BayesKernel )
		kernel = self.class.get_bayes_kernel_by_name( kernel_name,kernel_klass )
		return kernel.guess( self.to_s )
	end
	
	# Trains self on the kernel in the category. Returns true 
	def train( kernel_name, category, kernel_klass=Cardinal::BayesKernel )
		kernel = self.class.get_bayes_kernel_by_name( kernel_name,kernel_klass )
		return kernel.train( category, self.to_s )
	end
end



#
# Extending Bishop classes
#
module Bishop
	# Hook for future extensions on the bishop implementation
end



#
# Defining Cardinal Module, inherited from Bishop | Renaming the module
#
module Cardinal

  	#Including the Bishop Functions - Cardinal implementation
  	include Bishop
  
  
  
	#
	# Bayes inheritance
	#
	class BayesData < Bishop::BayesData
	
		def get_closest_match_for(word, threshold=2)
			if @data.has_key? word
				return [word, @data[word]]
			else
				ld_array = []
				@data.each do |entry,freq|
					ld = Cardinal.levenshtein_distance(word, entry)
					# Return Match if it has a distance of 1
					if ld == 1
						return [entry, @data[entry]]
					else
						ld_array.push([ld,entry])
					end
				end
				# Return closest match if not greater than threshold else return nil
				ld_array = ld_array.sort
				if ld_array[0][0] <= threshold
					return [ld_array[0][1], @data[ld_array[0][1]]] 
				else
					return nil
				end
			end
		end
	end
	
	
	
	#
	# BayesResult - Holds information about Result
	#
  	class BayesResult < Hash
  		def initialize(msg, results, kernel)
				self[:kernel] = kernel  			
				self[:message] = msg
				unless results.empty?
  				best_guess = results.sort{|x,y| y[1] <=> x[1]}
  				self[:best_guess] = [best_guess[0][0],best_guess[0][1]]
  				self[:probabilites]= {}
  				results.each do |result|
  					self[:probabilites][result[0]]= result[1]
  				end
				else
					self[:best_guess] = nil
				end
  		end
		# Method to initiate the feedback loop to the kernel	
		def feedback(value)
			if value == true
				self[:kernel].train( self[:best_guess][0], self[:message] )
			elsif value == false
				self[:kernel].untrain( self[:best_guess][0], self[:message] )
			else
				self[:kernel].untrain( self[:best_guess][0], self[:message] )
				self[:kernel].train( value.to_s, self[:message] )
			end
		end
  	end
  
  
	#
	# Tokenizer inheritance - Unicode support and extended functionalities
	#
	class Tokenizer < Bishop::Tokenizer
		attr_accessor = :character_blacklist, :word_blacklist, :max_word_length
		def initialize()
			@character_blacklist = //#/[+*~.:,;#?!]/
			@word_blacklist = []
			@max_word_length = 50
		end
		def tokenize( item )
		  item.split( /\s+/ ).map do |i|
			token = i.split( /\-/ ).map { |token| token.downcase.gsub( @character_blacklist, "" ) }.join( "-" )
		  end.reject { |t| t == "" || t == "-" || @word_blacklist.include?(t) || t.size > @max_word_length }
		end
	end
  


	#
	# Bayes Persistent Kernel Interface - inherited from Bishop
	#
	class BayesKernel < Bishop::Bayes

		attr_reader :name
		attr_accessor :levenshtein_mode

		@@instance_collector = []
		
		@levenshtein_mode = false
		

		# Factory method to prevent duplicates - used instead of new
		def self.factory( name, tokenizer = nil, data_class = BayesData, &combiner )
			# Check if BayesKernel.new would create a duplicate (checked on klass and name)
			BayesKernel.all_instances().each do |instance|
				return instance if instance.name == name.to_sym
			end
			return BayesKernel.new( name, tokenizer = nil, data_class = BayesData, &combiner )
		end

		# Access to instance_collector
		def self.all_instances()
			return @@instance_collector
		end

		# Initializes a new BayesKernel.new()
		def initialize( name, tokenizer = nil, data_class = BayesData, &combiner )
			@name = name.to_sym
			super( tokenizer, data_class, &combiner )
			# Add instance to instance_collector
			@@instance_collector << self
		end
		
		#
	  	# Export interface for the pools data
	  	#
	  	# Exports the data in the pools
		def export_pools_data( file )
		  	File.open( file, 'w' ) { |f| YAML.dump( self.pools, f ) }
		end
		
		# Imports the data into the pools
		def import_pools_data( file )
		  begin
		    File.open( file ) do |f| 
		    	self.pools = YAML.load( f )
			  	self.pools.each { |pool_name,pool| pool.data.default = 0.0 }
			  	self.corpus = self.pools['__Corpus__']
			  	self.dirty = true
		    end
		  rescue Errno::ENOENT
		    # File does not exist
		  end
		end
		
		
		# Extends Guessing Interface - Returns a Guess Hash with more information
		def guess(string)
			result = BayesResult.new(string, super(string), kernel=self)
		end
		
		# Calls guess for every token in the string
		# Returns a latent semantic index array
		def latent_semantic_indexing(string)
			lsimap = []
			@tokenizer.tokenize(string).each do |token|
				lsimap.push( guess(token) )
			end
			return lsimap
		end
		
		# Override get_props: not existing words should return closest levenstein match (1..cutoff)
		def get_probs( pool, words )
			if @levenshtein_mode
		  		return words.map { |word| pool.get_closest_match_for(word) }.compact.sort
		  	else
		  		return super( pool, words )
		  end
		end
	end
	
	
	
	#
	# Bayes Pattern Recognition Kernel
	#
	class BayesPatternRecognitionKernel
		def initialize()
		end
	end
	
	
	
	#
	# Markov State Implementation
	#
	class MarkovStates < Hash
		def initialize()
			super
		end
		def train(source,target)
			if self.has_key?(source)
				if self[source].has_key?(target)
					self[source][target]+=1
				else
					self[source][target]=1
				end
			else
				self[source]= {target=>1}
			end
		end
		def untrain(source,target)
			if self.has_key?(source) and self[source].has_key?(target) 
				self[source][target]-=1
				if self[source][target] <= 0
					self[source].delete(target)
				end
				if self[source].empty?
					self.delete(source)
				end
			end
		end
		
		# Returns a Hash of probabilities for source; nil if source not present
		def probabilities_for(source)
			if self.has_key?(source)
				total = self[source].values.inject(:+).to_f
				return Hash[*self[source].map{|key,value| [key,value/total] }.flatten]
			end
			return nil
		end
		
		# Returns the probability for source => target; nil if none found
		def probability_for(source, target)
			next_states = probabilities_for(source)
			unless next_states.nil?
				return next_states[target]
			end
			return nil
		end
		
		# Returns the next state for source
		def next_state_for(source)
			return probabilities_for(source).sort[0][0]
		end
	end
	
	
	
	#
	# Markov Chain Implementation
	#
	class MarkovKernel
	
		attr_reader :name, :markovproperty
		attr_accessor :states
		
		def initialize(name, separator = ' ', markovproperty=true)
			@name = name
			@separator = separator
			@markovproperty = markovproperty
			@states = MarkovStates.new()
		end
		
		# Returns Array of probabilities for a string
		def match_probabilities(string, index_shift=[0,1])
			match_probabilities = []
			sequence = string.split(@separator).push(nil)
			sequence.each_index do |index|
				unless sequence[index].nil?
					match_probabilities.push( @states.probability_for(sequence[index+index_shift[0]], sequence[index+index_shift[1]]) )
				end
			end
			return match_probabilities
		end
		
		# Returns the Average of the probabilities of the match
		def match(string)
			probabilities = match_probabilities(string)
			return probabilities.inject(:+).to_f/probabilities.size
		end
		
		# Trains a sequence of states
		def train(string)
			sequence = string.split(@separator).push(nil)
			sequence.each_index do |index|
				unless sequence[index].nil?
					@states.train(sequence[index],sequence[index+1])
				end
			end
		end
		
		# Untrains a sequence of states
		def untrain(string)
			sequence = string.split(@separator).push(nil)
			sequence.each_index do |index|
				unless sequence[index].nil?
					@states.untrain(sequence[index],sequence[index+1])
				end
			end
		end
	end
	
	
	
	
	class Context < MarkovKernel
		# Returns smooth moving probability regions of markov realizations (left to right)
		def moving_probabilities(source, sensitivity=0.33)
			potential = 0.0
			moving_match = []
			match_probabilities(source).each do |prob|
				if prob.nil?
					potential-= sensitivity
					if potential < 0.0 then potential = 0.0 end
				else
					potential+= prob
				end
				moving_match.push(potential)
			end
			return moving_match
		end
		# Returns smooth moving probability regions of reverse markov realizations (right to left)
		def reverse_moving_probabilities(source, sensitivity=0.33)
			return moving_probabilities(source.reverse, sensitivity).reverse
		end
		
		# Returns 
		def cumulative_markers(source)
			match_probabilities = match_probabilities(source).map{|x| x.nil? ? 0.0 : x}
			markers = []
			marker_potential = 0.0
			match_probabilities.each_with_index do |prob,index|
				if match_probabilities[index+1].nil? or match_probabilities[index+1] <= 0.0
					marker_potential+= prob
					markers[index] = marker_potential
					marker_potential= 0.0
				else
					marker_potential+= prob
					markers[index] = 0.0
				end
			end
			return markers
		end
		def reverse_cumulative_markers(source)
			return cumulative_markers(source.reverse).reverse
		end
	end
	
	class ContextPatternRecognition
	
		attr_accessor :sensitivity
		
		def initialize(name, separator = '')
			@name = name
			@separator = separator
			@sensitivity = 0.33
			@left_context = Context.new("left", @separator)
			@right_context = Context.new("right", @separator)
			@target = Context.new("target", @separator)
		end
		def train(source, target)
			decomposed_source = source.split(target)
			@left_context.train(decomposed_source[0])
			@right_context.train(decomposed_source[1])
			@target.train(target)
		end
		def untrain(source, target=nil)
			if target
				decomposed_source = source.split(target)
				@left_context.untrain(decomposed_source[0])
				@right_context.untrain(decomposed_source[1])
				@target.untrain(target)
			else
				@left_context.untrain(source)
				@right_context.untrain(source)
			end
		end
		
		# Returns left and right gravity distributions (high values indicate probable cutoff)
		def moving_match_gravities(source)
			left_gravity = []
			right_gravity = []
			
			left_moving_match = @left_context.moving_probabilities(source,@sensitivity)
			left_target_moving_match = @target.reverse_moving_probabilities(source,@sensitivity)
			right_target_moving_match = @target.moving_probabilities(source,@sensitivity)
			right_moving_match = @right_context.reverse_moving_probabilities(source,@sensitivity)
			
			left_moving_match.each_index{|index| left_gravity[index]= left_moving_match[index]+left_target_moving_match[index]}
			right_moving_match.each_index{|index| right_gravity[index]= right_moving_match[index]+right_target_moving_match[index]}
			
			return left_gravity, right_gravity
		end
		
		# Returns the match Result	
		def match(source)
			left_gravity, right_gravity = moving_match_gravities(source)
			
			left_marker = left_gravity.sort[-1]
			right_marker = right_gravity.sort[-1]
			
			if left_marker > right_marker
				left_marker = [left_gravity.index(left_marker),left_marker]
				right_marker = right_gravity[left_marker[0]..-1].sort[-1]
				right_marker = [right_gravity[left_marker[0]..-1].index(right_marker)+left_marker[0],right_marker]
			else
				right_marker = [right_gravity.index(right_marker),right_marker]
				left_marker = left_gravity[0..right_marker[0]].sort[-1]
				left_marker = [left_gravity[0..right_marker[0]].index(left_marker),left_marker]
			end
			
			return [ left_marker,right_marker,source.split(@separator)[left_marker[0]..right_marker[0]].join(@separator) ]
		end
	end
	
	
	
	# 
	class PlatoMultiVectorKernel
		def initialize()
			@library = []
			@
		end
	end
	
	    
	#
	# Module Functions
	#
	# Calculates Levenshtein Distance for s to t; the numbers of operations getting from s to t
	def self.levenshtein_distance(s, t)
		m = s.length
		n = t.length
		return m if n == 0
		return n if m == 0
		d = Array.new(m+1) {Array.new(n+1)}
		(0..m).each {|i| d[i][0] = i}
		(0..n).each {|j| d[0][j] = j}
		(1..n).each do |j|
			(1..m).each do |i|
		  		d[i][j] = if s[i-1] == t[j-1]  # adjust index into string
			          d[i-1][j-1]       # no operation required
			        else
			          [ d[i-1][j]+1,    # deletion
			            d[i][j-1]+1,    # insertion
			            d[i-1][j-1]+1,  # substitution
			          ].min
			        end
				end
	  		end
	  	d[m][n]
	end
  
end




