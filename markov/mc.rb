# encoding: utf-8

class MarkovChain # < Array
DEFAULT_SET = "abcdefghijklmnopqrstuvwxyzäöüABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ?.:,;".split('')
	def initialize(set=DEFAULT_SET)
		@set = set 
		@chain = Hash.new(0)
		
	end
	def train(arr)
		(0..arr.size-2).each do |pos|
			idx1 = get_idx_of(arr[pos])
			idx2 = get_idx_of(arr[pos+1])
			if idx1 and idx2
				@chain[[idx1,idx2]] ? @chain[[idx1,idx2]] += 1 : @chain[[idx1,idx2]] = 1
			end
		end
		return arr
	end
	def untrain(arr)
		(0..arr.size-2).each do |pos|
			idx1 = get_idx_of(arr[pos])
			idx2 = get_idx_of(arr[pos+1])
			if idx1 and idx2
				@chain[[idx1,idx2]] ? @chain[[idx1,idx2]] -= 1 : @chain[[idx1,idx2]] = 0
				if @chain[[idx1,idx2]] < 0
					@chain[[idx1,idx2]] = 0
				end
			end
		end
		return arr
	end
	def test(arr)
		probs = Array.new(arr.size, 0.0)
		(0..arr.size-2).each do |pos|
			idx1 = get_idx_of(arr[pos])
			idx2 = get_idx_of(arr[pos+1])
			if idx1 and idx2
				#puts [idx1,idx2].inspect
				probs[pos] = @chain[[idx1,idx2]] / get_total_of(idx1).to_f
			else
				probs[pos] = 1.0
			end
		end
		return arr, probs 
	end
private
	def get_idx_of(element)
		idx = @set.index(element)
		if not idx == nil
			return idx
		else
			add_element(element)
			return get_idx_of(element)
		end
	end
	def add_element(element)
		@set.push(element)
	end
	def get_total_of(idx)
		total = 0
		@chain.each{|k,v| if k[0]==idx then total+=v end }
		return total
	end
end


words_mc = MarkovChain.new()

filename = "words.txt"
words = File.readlines(filename)
#words = ["abc","abx"]
words.each_with_index do |word,idx|
	puts idx.to_f/words.size
	word = " " + word.chomp + " "
	words_mc.train(word.split(''))#puts word.inspect
end

puts words_mc.inspect
result = words_mc.test('Schlachtplan'.split(''))
result[1].each_index do |idx|
	puts "#{result[0][idx]} => #{result[0][idx+1]} :: #{result[1][idx]}"
end

# Generate connected sequences
p = [0.0]
s = []
sequences = []
result[1].each_index do |idx|
	if result[1][idx] < ( p.inject(:+)/p.size )
		# Start new sequence
		sequences.push(s.join())
		s = []
		p = [result[1][idx]]
	else
		p.push(result[1][idx])
	end
	# Append to sequence
	s.push(result[0][idx])#.push(result[0][idx+1])
end








puts sequences.inspect
