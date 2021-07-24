






class Question
  #
  # Class to describe an Information Domain and hold the possible states.
  #

  def initialize(domain,states,description=nil)
    # The domain of information (aka: Question)
    @domain = domain.to_s
    # Possible States for the information domain
    @states = states.to_a
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
    puts @domain
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

class Answer
  def initialize(answer, situation)
    @answer = answer
    @situation = situation
  end
  def complete_answer(inquiry=nil)
    answer = ""
    answer << @situation.to_s << " "
    answer << to_s
    return answer
  end
  def to_s
    if @answer.class == String
      return @answer + " (100.0%) "
    elsif @answer.class == Array
      answer = ""
      @answer.sort.reverse.each do |prob|
        if prob[0] != 0.0
          answer << "#{prob[1]} (#{prob[0]*100}%) "
        end
      end
      return answer
    end
  end
end


# TODO: This is the DEAMON Class
class Inquiry
  def initialize(actions=nil,questions=nil,conditions=nil)
    @actions = actions.to_a ||= []
    @questions = questions.to_a ||= []
    @conditions = conditions ||= {}
  end
  def actions()
    return @actions
  end
  def questions()
    return @questions
  end
  def conditions()
    return @conditions
  end
  def add_action(*action)
    @actions.push(action).flatten!
  end
  def add_question(*question)
    n = question.flatten.size
    @questions.push(question).flatten!
    unless @conditions.empty?
      @conditions.each do |condition,action|
        condition.fill(nil,condition.size, n)
      end
    end
  end
  def add_condition(action, condition)
    if check_action_validity(action) and check_condition_validity(condition)
      @conditions[condition]=action
      return true
    end
    return false
  end
  def solve(situation)
    solution = "Not solvable"
    unless check_condition_validity(situation)
      return solution
    end

    # Deterministic Solution
    deterministic = get_deterministic_solution(situation)
    if deterministic
      return Answer.new( @actions[deterministic], situation )
    end

    # Probabilistic solution
    probabilistic = get_probabilistic_solution(situation)
    if probabilistic
      return Answer.new( probabilistic, situation )
    end

    return Answer.new( solution, situation )
  end

  def trainer()
    situation = []
    @questions.each{|q| situation.push q.ask()}
    puts "GIVEN THE SITUATION:\n" << situation.inspect << "\n\nWHAT WOULD YOU DO?\n"
    @actions.each_with_index do |action, idx|
      puts "(#{idx+1})\t#{action}"
    end
    answer = gets.to_i-1
    add_condition(answer, situation)
  end

private

  def get_deterministic_solution(situation)
    #
    # Returns not nil if @condition contains an exact match of situation
    #
    return @conditions[situation]
  end

  def get_probabilistic_solution(situation)
    #
    # Returns a probability matrix for every result iterating the @conditions hash (Exhaustive)
    #
    solution = nil
    probability_table = Array.new(@actions.size,0)

    @conditions.each do |condition_state,result|
      situation.each_with_index do |situation_state, idx|
        if !situation_state.nil? and !condition_state[idx].nil?
          # TODO: check above line... do both have to contain value to say s/t
          condition_state_is_array = condition_state[idx].class == Array
          situation_state_is_array = situation_state.class == Array

          if condition_state_is_array
            if situation_state_is_array
              # compare Array with Array (if Intersection is not empty)
              if !(condition_state[idx] & situation_state).empty?
                probability_table[result]+= 1
              end
            else
              # Compare Array with String
              if condition_state[idx].include?(situation_state)
                probability_table[result]+= 1
              end
            end
          else
            if situation_state_is_array
              # Compare String with Array
              if situation_state.include?(condition_state[idx])
                probability_table[result]+= 1
              end
            else
              # Compare String with String
              if condition_state[idx] == situation_state
                probability_table[result]+= 1
              end
            end
          end
        end
      end
    end

    #puts probability_table.inspect
    sum = probability_table.inject(:+)
    if sum > 0
      probability_table = probability_table.each_with_index.map{|x,i| [x/sum.to_f,@actions[i]]}
      return probability_table
    end
    return solution
  end

  def check_action_validity(action)
    if action.class == Fixnum and action < @actions.size
      return true
    end
    return false
  end
  def check_condition_validity(condition)
    if condition.class == Array and condition.size == @questions.size
      return true
    end
    return false
  end
end



# Setup Questions
time = Question.new "What is the current time of day?", [:night,:morning,:day,:evening]
temperature = Question.new "What is the current temperature?", [:very_cold,:cold,:temperate,:hot,:very_hot]
weather = Question.new "What is the current weather condition?", [:stormy,:rainy,:cloudy,:sunny]
shelter = Question.new "What type of shelter do you have closest by?", [:no_shelter,:temporary_shelter,:semi_permanent_shelter,:permanent_shelter]
shelter_distance = Question.new "What is the distance to closest shelter?", [:unknown,:very_close,:close,:far,:very_far], [nil,"up to 3 hours walking distance","up to 6 hours walking distance","up to 9 hours walking distance","more than 9 hours walking distance"]

# Setup Inquiry
shelter_inquiry = Inquiry.new
shelter_inquiry.add_action ["Nothing",
  "Find or build a temporary shelter",
  "Go to nearest known shelter location"]
shelter_inquiry.add_question [time, temperature, weather, shelter, shelter_distance]

# Add conditions
shelter_inquiry.add_condition 1, [nil, nil, nil, :no_shelter, nil]
shelter_inquiry.add_condition 1, [nil, nil, nil, nil, :unknown]
shelter_inquiry.add_condition 2, [:evening, nil, [:rainy, :stormy], nil, :very_close]
shelter_inquiry.add_condition 0, [:morning, nil, nil, :temporary_shelter, :very_close]





puts shelter_inquiry.conditions

puts shelter_inquiry.solve( [nil, nil, [:rainy, :stormy], nil, nil] )
puts shelter_inquiry.solve( [nil, nil, :rainy, nil, nil] )
puts shelter_inquiry.solve( [[:evening,:morning], nil, nil, nil, nil] )
puts shelter_inquiry.solve( [:evening, nil, nil, nil, nil] )








#time = ProbabilisticDecisionTree::InformationDomain.new( "What is the current time of day?",
#  [:night,:morning,:day,:evening],#
#  ["21-3h","3-9h","9-15h","15-21h"]
#)

#puts time

#time.add_state( :lune )
#time.add_state( :fume, "from here to there" )
#puts time.ask()

#puts time.inspect

#puts shelter_inquiry.questions
#puts shelter_inquiry.conditions
#puts
#shelter_inquiry.add_question [
#  Question.new("What is your weather forecast for the next 12 hours?", [:stormy,:rainy,:cloudy,:clear]),
#  Question.new("What is your energy level?", [:very_high,:high,:normal,:low,:very_low])
#]
#puts
#puts shelter_inquiry.questions
#puts shelter_inquiry.conditions
#puts

#shelter_inquiry.trainer()

#puts shelter_inquiry.conditions
#puts
#puts shelter_inquiry.solve( [nil, nil, nil, :no_shelter, nil] )
#puts shelter_inquiry.solve( [nil, nil, nil, nil, :unknown] )
#puts shelter_inquiry.solve( [nil, nil, nil, :no_shelter, :unknown] )
#puts shelter_inquiry.solve( [nil, nil, nil, :no_shelter, :very_close] ).complete_answer#(shelter_inquiry)
#puts shelter_inquiry.solve( [nil, nil, nil, nil, nil] )
