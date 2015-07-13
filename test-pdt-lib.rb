require_relative "pdt-lib.rb"
require "test/unit"

include ProbabilisticDecisionTree

class TestInformationDomain < Test::Unit::TestCase

  def test_initialize
    assert_raise( ArgumentError ) { InformationDomain.new() }

    init1 = InformationDomain.new("Domain")
    assert_equal("Domain", init1.to_s)
  end

end



class TestCondition < Test::Unit::TestCase

  def test_initialize
    assert_raise( ArgumentError ) { Condition.new() }
  end

end

class TestSitution < Test::Unit::TestCase

  def test_initialize
    assert_raise( ArgumentError ) { Situation.new() }
  end

end

class TestResult < Test::Unit::TestCase

  def test_initialize
    assert_raise( ArgumentError ) { Result.new() }
  end

end



class TestDeamon < Test::Unit::TestCase

  def test_initialize
    assert_nothing_raised( ArgumentError ) { Deamon.new() }
  end

end
