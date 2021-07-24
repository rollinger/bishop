#
# ProbabilisticDecisionTree (Copyright by Philipp Rollinger 2015)
#

=begin
The Deamon holds InformationDomains, Results and Conditions and resolves to a
set of Results and their probability of being true.
The Conditions are combinations of the possible states of the InformationDomains
and are the basis for the inference.

The inference process starts with a more or less incomplete Situation (being
itself a type of Condition). The deamon identifies the missing InformationDomain
with the highest information value and investigates the information.
At each iteration of the inference process the deamon has a probability guess.

FUTURE:
- The InformationDomains should be interconnected and weighted by importance so
that the deamon might further optimize the investigation process.
=end


# TODO:
# OK Refactor "action" to more general like response or result
# OK Comment every class and method
# O Do I need Situation class ? => delete?

module ProbabilisticDecisionTree
#
# BEGIN MODULE ProbabilisticDecisionTree
#

  class InformationDomain
    #
    # Class to describe an Information Domain and hold the possible states.
    #

    attr_reader :id, :domain, :states

    def initialize(id, domain, states=nil,description=nil)
      # ID Symbol identifying the InformationDomain
      @id = id.to_sym
      # The domain of information (aka: Question)
      @domain = domain.to_s
      # Possible States for the information domain
      @states = states.to_a ||= []
      # Optional: Description of each state
      @description = description.to_a ||= Array.new(@states.size,"")
    end

    def add_state(state, description=nil)
      #
      # Adds one new state to the information domain (optional the description)
      #
      @states.push(state).flatten!
      if description.nil?
        @description.push(nil)
      else
        @description.push( description )
      end
    end

    def ask()
      #
      # Interface printing the states and returning an answer
      #
      puts @question
      @states.each_with_index do |s,i|
        puts "(#{i+1})\t#{s}\t#{@description[i]}"
      end
      answer = gets.to_i-1
      return @states[answer]
    end

    def to_s
      #
      # Class Print Method
      #
      return @domain
    end

  end
  #
  # END CLASS InformationDomain
  #

  class ConditionsHash < Hash
    #
    # Holds a known Condition for the PDT
    #
    def initialize(domain_pointer, results_pointer)
      #
      # Overwrites initialize methods and adds pointers to the result and domain arrays
      #
      super()
      @domains = domain_pointer
      @results = results_pointer
    end

    def match(situation)
      #
      # Calculates the match between situation and every condition for each result
      #
      return nil unless validate_key(situation)
      situation_size = situation.size
      results_size = @results.size
      probability_table = Array.new(results_size,0.0)

      self.each do |condition,result|

        matching = Array.new(situation_size,0)

        condition.each_index do |idx|
          if condition[idx].nil? and !situation[idx].nil?
            # Anything can match with something!
            matching[idx]+= 1
          elsif !condition[idx].nil? and !situation[idx].nil?
            # Enforce Array for Intersection Test
            condition[idx].class == Array ? temp_condition = condition[idx] : temp_condition = [condition[idx]]
            situation[idx].class == Array ? temp_situation = situation[idx] : temp_situation = [situation[idx]]
            # INTERSECTION TEST
            if !(temp_condition & temp_situation).empty?
              matching[idx]+= 1
            else
              matching[idx]-= 1
            end
          end
        end

        #puts "#{condition} \n #{situation} \n::: #{matching} => #{result}"
        value = matching.inject(:+)/situation_size.to_f
        probability_table[result]+= ( value )
        @results[result].add_match_value(value)
      end
      # Calculate and return probability table
      #puts probability_table.inspect
      return probability_table
    end

    def []=(key,val)
      #
      # Overwrites normal accessor method
      #
      key = validate_key(key)
      val = validate_val(val)
      super(key,val) if !key.nil? and !val.nil?
    end

    def expand_keys(n=1)
      #
      # Add n times nil values to all keys which size is != @domains.size
      #
      ss = @domains.size
      keys.each do |k|
        ks = k.size
        k.fill(nil, ks, n) if ss - ks == n
      end
    end

  private

    def validate_key(key)
      #
      # Validates correct key class, size and content
      #
      if key.class == Array and key.size == @domains.size and !key.flatten.compact.empty?
        key.each_with_index do |element,index|
          if element.class == Array
            element.each do |e|
              # key not valid and not nil
              return nil if !e.nil? and !@domains[index].states.include?(e)
            end
          else
            # key not valid and not nil
            return nil if !element.nil? and !@domains[index].states.include?(element)
          end
        end
        return key
      end
      # key has wrong class or size or contains only nils
      return nil
    end

    def validate_val(val)
      #
      # Validates Fixnum is not out of range and converts Symbol to index
      #
      if val.class == Fixnum
        return val if val < @results.size
      elsif val.class == Symbol
        return validate_val( @results.index{|r| r.id == val } )
      end
      return nil
    end

  end
  #
  # END CLASS Condition
  #

  class Situation
    #
    # Holds a Situation the PDT
    #

    def initialize(result)
      super
    end

    def to_s
      super
    end

  end
  #
  # END CLASS Situation
  #

  class Result
    #
    # Holds a possible Decision Result of the PDT
    #

    attr_reader :id, :result, :probability

    def initialize(id, result)
      # The verbose result (aka. Action) or Endpoint
      @id = id.to_sym
      @result = result.to_s
      @probability = nil
    end

    def tainted?
      if @probability.nil? then return false else return true end
    end

    def reset_probability()
      if tainted? then @probability = nil end
    end

    def add_match_value(value)
      return false if value.class != Float
      if @probability.nil?
        @probability = value
      else
        @probability += value
      end
      return @probability
    end

    def to_s
      #
      # Class Print Method
      #
      if @probability.nil?
        return @result
      else
        return "#{@result} (#{@probability})"
      end
    end

  end
  #
  # END CLASS Results
  #

  class Daemon
    #
    # The Daemon that handles the Probabilistic Decision Tree
    #

    attr_accessor :results, :domains

    def initialize()
      @results = []
      @domains = []
      @conditions = ConditionsHash.new(@domains,@results)
    end

    def add_result(id, result)
      #
      # Adds a Result to Daemon
      #
      @results.push( Result.new(id, result) )
    end

    def add_domain(id, domain, states=nil, description=nil)
      #
      # Adds a InformationDomain to the Daemon and updates all conditions by one
      #
      @domains.push( InformationDomain.new( id, domain, states, description) )
      @conditions.expand_keys(1)
    end

    def add_condition(key,value)
      #
      # Adds a Condition to ConditionsHash
      #
      @conditions[key]=value
    end

    def add_rule(result, *rules)
      #
      # Better interface to add_condition
      #
      condition = Array.new(@domains.size, nil)
      rules.each_slice(2) do |tuple|
        idx = @domains.index{|d| d.id == tuple[0] }
        if tuple[1].class == Array
          intersection = @domains[idx].states & tuple[1]
          intersection = nil if intersection.empty?
          condition[idx] = intersection
        else
          condition[idx] = tuple[1] if @domains[idx].states.include?(tuple[1])
        end
      end
      add_condition(condition,result)
    end

    def solve(situation,reset=true)
      #
      # Public Interface for solving the situation
      #
      solution = "Not solvable"
      unless check_situation_validity(situation)
        return solution
      end

      # Untaint all Results
      reset_result_probabilities() if reset

      # Probabilistic solution
      probabilistic = @conditions.match(situation)
      if probabilistic
         #return [ probabilistic, situation ]
         return @results.sort { |a,b| b.probability <=> a.probability }
      end

      return solution
    end

    def to_s
      #
      # Class Print Method
      #
      return self
    end

    def self.deserialize(filename)
      #
      # Class Method that returns the complete unmarshaled Object
      #
      begin
        obj = nil
        File.open(filename, "r") do |file|
          obj = Marshal.load(file)
        end
        return obj
      rescue
        if filename.nil?
          puts "No File specified."
        else
          puts "File #{filename} does not exists."
        end
        exit(0)
      end
    end

    def serialize(filename)
      #
      # Serialize the class to a file
      #
      File.open(filename, "w") do |file|
        file.puts Marshal.dump( self )
      end
    end

private

  def check_situation_validity(situation)
    if situation.class == Array and situation.size == @domains.size
      return true
    end
    return false
  end

  def reset_result_probabilities()
    @results.each do |r|
      r.reset_probability
    end
  end

  end
  #
  # END CLASS Deamon
  #

  class Trainer
    #
    # Training interface for a Daemon
    #

    def initialize(daemon)
      @daemon = daemon
    end

    def train_by_cmd(verbose=true)
      system "clear"
      if verbose
        print_system_variables
        puts
      end
      cmd = gets()
      puts "@daemon.add_rule(#{cmd})"
    end

  private

    def print_system_variables()
      puts "POSSIBLE RESULTS:"
      @daemon.results.each {|r| puts "#{r.id.inspect}\t#{r.result}" }
      puts "POSSIBLE DOMAINS:"
      @daemon.domains.each {|d| puts "#{d.id.inspect}\t#{d.domain}\t#{d.states.inspect}" }
    end

  end
  #
  # END CLASS Situation
  #

end
#
# END MODULE ProbabilisticDecisionTree
#
