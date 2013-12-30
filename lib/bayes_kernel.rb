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
	
	# Save Object
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
  		def initialize(msg, results)
  			self[:message] = msg
  			best_guess = results.sort{|x,y| y[1] <=> x[1]}
  			self[:best_guess] = [best_guess[0][0],best_guess[0][1]]
  			self[:probabilites]= {}
  			results.each do |result|
  				self[:probabilites][result[0]]= result[1]
  			end
  		end
  	end
  
  
	#
	# Tokenizer inheritance - Unicode support and extended functionalities
	#
	class Tokenizer < Bishop::Tokenizer
		attr_accessor = :character_blacklist, :word_blacklist, :max_word_length
		def initialize()
			@character_blacklist = /[+*~]/
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
			result = BayesResult.new(string, super(string))
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



