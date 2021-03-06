#
# Cardinal Bayesian Classifier
#
#
# This module is a port of the Bishop Bayesian classifier distributed by 
# Matt Mower <self@mattmower.com>, Copyright 2005.
#
# This Ruby port is Copyright 2010 Philipp Rollinger <philipp.rollinger@gmx.de> and is free software;
# you can distribute it and/or modify it under the terms of version 2.1 of the GNU
# Lesser General Public License as published by the Free Software Foundation.
#


require_relative 'bishop.rb'
require_relative 'statistic-lib.rb'

#$KCODE = 'u'

#
# Extending Bishop classes
#
module Bishop
  
  # Allows transition between saved Bishop::BayesData coupled with Cardinal::BayesData Functionality
  class BayesData
    
    #Returns the maximum counted token for a specified pool
    def max_counted_token(n=1)
      max = self.data.to_a.sort {|a,b| b[1] <=> a[1]}
      return max[0..n-1]
    end
    
    #Returns the minimum counted token for a specified pool
    def min_counted_token(n=1)
      min = self.data.to_a.sort {|a,b| a[1] <=> b[1]}
      return min[0..n-1]
    end
    
    #Returns all token in BayesData
    def all_tokens
      token_array = []
      self.data.each do |token, count|
	token_array.push( token )
      end
      return token_array
    end
    
    #Returns all token counts in BayesData
    def all_token_counts
      token_array = []
      self.data.each do |token, count|
	token_array.push( count )
      end
      return token_array
    end
    
  end
  
end

#
# Defining Cardinal Module, inherited from Bishop | Renaming the module
#
module Cardinal
  #Including the Bishop Functions
  include Bishop
  
  #
  # Bayes inheritance
  #
  class BayesData < Bishop::BayesData
  end
  
  #
  # Tokenizer inheritance
  #
  class Tokenizer < Bishop::Tokenizer
  end
  
  #
  # Bayes inheritance
  #
  class Bayes < Bishop::Bayes
    
    # Is this a new, empty Cardinal Instance?
    def empty?
    	return self.pools.length == 1 ? true : false
    end
    
    #
    # Token System Inspection Methods
    #
    
    #Returns array of pool_names
    def get_pool_names(corpus = false)
      pool_name_array = []
      self.pools.each do |pool_name, pool|
	unless corpus == false && pool_name == '__Corpus__'
	  pool_name_array.push(pool_name)
	end
      end
      return pool_name_array
    end
    
    #Returns array system wide tokens
    def get_all_tokens()
      return self.corpus.all_tokens
    end
    
    #Returns if token is present in system
    def has_token?( token )
      return self.corpus.data.has_key?( token )
    end
    
    #Returns the system wide token with maximum count
    def get_max_system_token_count
      max = []
      get_pool_names.each do |pool_name|
	max.push( self.pools[pool_name].max_counted_token[0] )
      end
      max = max.sort {|a,b| b[1] <=> a[1]}
      #puts max.inspect
      return max[0]        
    end
    
    #Returns the n best tokens (lowest deviance)
    def get_best_tokens(n=10)
      best = get_all_tokens_deviance.sort {|a,b| a[1] <=> b[1]}
      return best[0..n-1]
    end
    #Returns the n worst tokens (highest deviance)
    def get_worst_tokens(n=10)
      worst = get_all_tokens_deviance.sort {|a,b| b[1] <=> a[1]}
      return worst[0..n-1]
    end
    #Returns the n worst and best tokens (highest & lowest deviance)
    def get_best_and_worst_tokens(n=10)
      list = get_all_tokens_deviance.sort {|a,b| a[1] <=> b[1]}
      best = list[0..n-1]
      worst = list[-n, n]
      return  {:best => best, :worst => worst}
    end
    
    #Stems the deviance distribution of the token system
    def stem_token_deviance( filter_count=nil )
      list = get_all_tokens_deviance( filter_count ).map! {|e| e[1] }
      return Stat.stem( Stat.recode_float(list, [0.0..1.0,1.0..2.0,2.0..3.0,3.0..4.0,4.0..5.0,5.0..6.0,6.0..7.0] ) )

	#list = get_all_tokens_deviance.map! {|e| e[1] }
	#return Stat.stem( Stat.recode_float(list, [0.0..1.0,1.0..2.0,2.0..3.0,3.0..4.0,4.0..5.0,5.0..6.0,6.0..7.0] ) )

    end
    
    #Stems the token count distribution of the token system
    def stem_token_count
      list = get_all_tokens_count.map! {|e| e[1] }
      return Stat.stem(list)
    end
    
    #
    
    
    #
    # General purpose token counts query. nil means all tokens || pools
    #
    def token_counts( token=nil, pool_name=nil )
      if token.nil? 
	
	if pool_name.nil? #token and pool is nil | system total count
	  
	  systemtotal = 0.0
	  self.pools.each do |pool_name, pool|
	    systemtotal += pool.token_count
	  end
	  return systemtotal
	  
	else #token nil pool specified | pool total count
	  
	  pooltotal = self.pools[pool_name].token_count
	  return pooltotal
	  
	end
	
      else
	
	if pool_name.nil? #token specified & pool is all | token total count
	  
	  tokentotal = 0.0
	  self.pools.each do |name,pool|
	    unless name == '__Corpus__'
	      tokentotal += token_counts( token, name )
	    end
	  end
	  return tokentotal
	  
	else #token and pool specified
	  
	  token_count = self.pools[pool_name].data[token]
	  return token_count
	  
	end
	
      end
    end
    
    #
    # Aliases for general purpose token_counts method
    #
    #Returns the total token counts for all pools
    def get_system_total()
      return token_counts( nil ,nil )
    end
    #Returns the total token counts for specified pools
    def get_pool_total(pool_name)
      return token_counts( nil, pool_name )
    end
    # Returns the total count of a token over all pools
    def get_token_total( token )
      return token_counts( token, nil )
    end
    # Returns the number of token counts in specific pool
    def get_token_counts( token, pool_name )
      return token_counts( token, pool_name )
    end
    
    #
    # General purpose token relation query. numerator and divider must be a float from token_counts method
    #
    def token_relation( numerator, divider )
      return numerator / divider
    end
    #
    # Aliases for general purpose token_relation method
    #
    # token total / system total
    def get_token_total_to_system_total(token)
      return token_relation( get_token_total(token), get_system_total )
    end
    # pool total / system total
    def get_pool_total_to_system_total(pool_name)
      return token_relation( get_pool_total(pool_name), get_system_total )
    end
    # token total / pool total
    def get_token_total_to_pool_total(token, pool_name)
      return token_relation( get_token_total(token), get_pool_total(pool_name) )
    end
    # specific token / system total
    def get_specific_token_to_system_total(token, pool_name)
      return token_relation( get_token_counts(token,pool_name), get_system_total )
    end
    # specific token / pool total
    def get_specific_token_to_pool_total(token, pool_name, divider_pool_name)
      return token_relation( get_token_counts(token,pool_name), get_pool_total(divider_pool_name) )
    end
    # specific token / specific
    def get_specific_token_to_specific_token( t1, p1, t2, p2 )
      return token_relation( get_token_counts(t1, p1), get_token_counts(t2, p2) )
    end
    
    
    # Return an array of token counts for a specified token in each pool (Excluding __Corpus__)
    def token_count_vector( token )
      token_pool_counts = []
      self.pools.each do |pool_name, pool|
	unless pool_name == '__Corpus__'
	  token_pool_counts.push( get_token_counts( token, pool_name ) )
	end
      end
      return token_pool_counts
    end
    
    
    #
    # Deviance Calculations
    #
    # Calculates the (Cumulated total) deviance of a token list
    def deviance_of_token_list( token_list, total=true, exclude_nils=true )
      #exclude non occuring items
      if exclude_nils == true
	token_list.delete_if {|t| !has_token?(t) }
      end
      #Deviance Calculations
      if total == true #calcs the cumulative total
	dev = 0.0
	token_list.each do |token|
	  dev += get_token_deviance( token )
	end
	return dev / token_list.length
      else #Calcs deviance for each token
	dev = []
	token_list.each do |token|
	  dev.push( [ token, get_token_deviance( token ) ] )
	end
	return dev
      end
    end
    #Returns the cumulated deviance of a specified token in all pools
    def get_token_deviance( token )
      vector = token_count_vector( token )
      return Stat.relative_deviance(vector)
      # The closer to 0.0 the better the discriminancy of the token between categories
    end
    #Returns the cumulated token deviance of a specified pool
    def get_pool_deviance( pool_name )
      pool_token_list = pool_tokens(pool_name)
      return deviance_of_token_list( pool_token_list )
    end
    #Returns the cumulated pool deviances of the system
    def get_system_deviance
      system_deviance = 0.0
      pool_names = get_pool_names
      pool_names.each {|name| system_deviance += get_pool_deviance( name ) }
      return system_deviance / pool_names.length
    end
    #Returns the complete token / deviance list
    def get_all_tokens_deviance( target_count=nil )
      token_deviance_list = []
      get_all_tokens.each do |token|
	if target_count.nil?
	  token_deviance_list.push([ token, get_token_deviance( token ) ] )
	else
	  d = get_token_deviance( token )
	  c = get_token_total( token )
	  token_deviance_list.push([ token, d ] ) unless c == target_count
	end
      end
      return token_deviance_list
    end
    #Returns the complete token / count list
    def get_all_tokens_count(target_deviance=nil)
      token_count_list = []
      get_all_tokens.each do |token|
	if target_deviance.nil?
	  token_count_list.push([ token, get_token_total( token ) ] )
	else
	  d = get_token_deviance( token )
	  c = get_token_total( token )
	  token_count_list.push([ token, c ] ) unless d == target_deviance
	end
      end
      return token_count_list
    end
    #Returns a list of token | count | deviance | 
    def get_token_count_and_deviance
      token_list = []
      get_all_tokens.each do |token|
	token_list.push([ token, get_token_total( token ), get_token_deviance( token ) ] )
      end
      return token_list
    end
    #Returns the correlation coeff of count and deviance
    def correlation_count_deviance
      c = []; d = []
      get_all_tokens.each do |token|
	c.push( get_token_total( token ) )
	d.push( get_token_deviance( token ) )
      end
      return [c,d]
    end

    
    
    
    
    
    
    #
    # Likelihood-Ratio-Index (coefficient of uncertainty)
    #
    #Correlation of token for a specified pool, PRE lambda Coefficient. 
    def prediction_power( token )
      e1 = 0.0
      e0 = 0.0
      system_total = get_system_total
      max_token_count = get_max_system_token_count
      e0 = system_total - max_token_count[1]
      
      get_pool_names.each do |pool_name|
	e1 += ( get_token_total(token) - get_token_counts(token, pool_name) )
      end
      return [e1,e0,1-(e1/e0)]
    end
    
 
    
    #
    # Guess interfaces
    #
    
    # Call this method to classify a "message", using only the discriminant tokens.  
    # The return value will be an array containing tuples 
    # (pool, probability) for each pool which
    # is a likely match for the message.
    def guess_by_deviance( msg )
      tokens = get_tokens_with_deviance_cutoff( msg )
      res = {}
      
      pool_probs.each do |pool_name,pool|
	p = get_probs( pool, tokens )
	if p.length != 0
	  res[pool_name] = self.combiner.call( p, pool_name )
	end    
      end
      
      res.sort
    end
    
    #Returns the tokens of input excluding those that are above cutoff
    def get_tokens_with_deviance_cutoff( input, cutoff=0.0 )
      cutoff_tokens = []
      token_list = self.tokenizer.tokenize( input )
      tokens_deviance = deviance_of_token_list( token_list, total=false )
      deviance_mean = deviance_of_token_list( token_list, total=true )
      # Cutoff Procedure
      tokens_deviance.each do |tok|
	unless tok[1] > deviance_mean
	  cutoff_tokens.push( tok[0] )
	end
      end
	
      return cutoff_tokens
    end
    
  end
  
end

##
## Test Script
##

test = Cardinal::Bayes.new

p test
