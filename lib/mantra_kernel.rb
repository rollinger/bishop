#encoding: utf-8

class String
	# Returns the 
	def markov_position(lang='en-en')
	end
	# Returns an array of unicode byte representations
	def to_bytes()
		return self.chars.map(&:ord)
	end
	# Returns a Mantra::Wave Object
	def to_wave(amplitude=1.0)
		return Mantra::Wave.new(self.to_bytes, amplitude)
	end
end



module Mantra

	PI = Math::PI
	NORMAL_AMPLITUDE = 1.0	
		
	class Wave < Array
		def initialize(periode, amplitude=NORMAL_AMPLITUDE)
			if periode.class == Array
				periode.each{|p| add( p, amplitude ) }
			elsif periode.class == Float
				add( periode, amplitude )
			end
		end
		def add( periode, amplitude=NORMAL_AMPLITUDE )
			self << [periode, amplitude]
		end
		def y(x)
			return self.map{|func| func[1]*Math.sin(func[0]*x) }.inject(:*)
		end
		def plot(range=0..2*PI, step=0.1)
			points = []
			range.step(step){|x| points.push( [x, y(x)] ) }
			return points
		end	
	end
	
	
	# Word Wave defined by its utterance and associated Concepts
	class Mantra < Wave
		def initialize(string)
			@string = string
			string.to_bytes.each{|b| add(b, 1.0) }
		end
	end
	
	
	
	# Concept defined by its associated concepts
	class Concept < Wave
		def initialize(*waves)
			waves.each do |wave|
				add( wave, 1.0 )
			end
		end
	end
	
end



cheese = Mantra::Mantra.new("Käse")
gouda = Mantra::Mantra.new("Gouda")
edamer = Mantra::Mantra.new("Edamer")
cheese_concept = Mantra::Concept.new(gouda,edamer)

puts cheese.inspect
puts gouda.inspect
puts edamer.inspect
puts cheese_concept.inspect


#a.add(2.0)
#a.add(3.0)
#a.add(-111.0)

#puts a.inspect

#puts a.y(1.1111)

#a.plot().each{|x| puts x.inspect }

