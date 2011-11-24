require 'test/unit'

class HumanParseExceptionHandlerTest < Test::Unit::TestCase
  include DatabaseHelpers
  
  def setup
    HumanParseExceptionHandler.truncate_exception_tables
  end
  
  # TESTS
  
  def test_bad_input
    exc_handler = HumanParseExceptionHandler.new
    assert_raise(RuntimeError) do
      result = exc_handler.get_human_result_for_string([],{})
    end
    assert_raise(RuntimeError) do
      result = exc_handler.get_human_result_for_string({},"no exception type passed")
    end
  end
    
  # This is a brand-new importer, it shouldn't have any human-matched entries associated
  def test_initialization
    exc_handler = HumanParseExceptionHandler.new
    new_str = exc_handler.get_human_result_for_string("foobar","ParseException")
    assert_equal(false, new_str)
  end

  # We are going to search the DB, make sure quotes don't get in the way
  def test_sql_escaped
    exc_handler = HumanParseExceptionHandler.new
    new_str = exc_handler.get_human_result_for_string("fo'ob\"ar","ParseException")
    assert_equal(false, new_str)
  end

  # Now add a string match, and then test it
  def test_match_resolution
    exc_handler = HumanParseExceptionHandler.new
    new_str = exc_handler.get_human_result_for_string("foobar","ParseException")
    assert_equal(false, new_str)
    
    exc_handler.add_human_result_for_string("foobar","ParseException","FOOBAR")
    assert_equal("FOOBAR",exc_handler.get_human_result_for_string("foobar","ParseException"))
  end
  
end