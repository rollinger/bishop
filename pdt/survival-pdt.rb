

require_relative "pdt-lib.rb"

include ProbabilisticDecisionTree



#
# Setup ProbabilisticDecisionTree DEAMON
#
survival = Daemon.new
#
# Setup Results
#
survival.add_result :build_temp_shelter, "Build a temporary shelter"
survival.add_result :find_temp_shelter, "Find a natural temporary shelter"
survival.add_result :goto_near_shelter, "Go to nearest known shelter location"
survival.add_result :nothing, "Nothing"
#
# Setup InformationDomains
#
survival.add_domain :time, "What is the current time of day?", [:night,:morning,:day,:evening]
survival.add_domain :temperature, "What is the current temperature?", [:very_cold,:cold,:temperate,:hot,:very_hot]
survival.add_domain :weather, "What is the current weather condition?", [:stormy,:rainy,:cloudy,:sunny]
survival.add_domain :shelter, "What type of shelter do you have closest by?", [:no_shelter,:temporary_shelter,:semi_permanent_shelter,:permanent_shelter]
survival.add_domain :shelter_distance, "What is the distance to closest shelter?", [:unknown,:very_close,:close,:far,:very_far], [nil,"up to 3 hours walking distance","up to 6 hours walking distance","up to 9 hours walking distance","more than 9 hours walking distance"]
#
# Add conditions
#
survival.add_condition [[:morning, :day, :evening], [:very_cold,:cold,:temperate], [:cloudy,:sunny], :no_shelter, :unknown], :build_temp_shelter
survival.add_condition [:night, [:temperate,:hot,:very_hot], [:stormy,:rainy], :no_shelter, :unknown], :find_temp_shelter
survival.add_condition [:evening, nil, nil, [:temporary_shelter,:semi_permanent_shelter,:permanent_shelter], :very_close], :goto_near_shelter
survival.add_condition [[:morning,:day], nil, nil, [:temporary_shelter,:semi_permanent_shelter,:permanent_shelter], :very_close], :nothing

survival.add_rule :find_temp_shelter, :time, :night


#survival.serialize("data/survival.pdt")



=begin
#survival.add_rule :goto_near_shelter, :shelter, :temporary_shelter
#survival.add_rule :nothing, :time, [:morning, :day, :noon], :temperature, [:temperate, :hot], :weather, :sunny


situations = [ [:morning,:temperate,:cloudy,:permanent_shelter,:very_close],
  [:evening,:temperate,:sunny,:permanent_shelter,:very_close],
  [:night,nil,nil,:permanent_shelter,:very_close],
  [:night,nil,nil,:permanent_shelter,[:unknown,:very_close,:close,:far,:very_far]]
]
situations.each do |situation|
  puts
  puts situation.inspect
  test = survival.solve situation
  puts test#.inspect
end

#puts survival.inspect
=end
