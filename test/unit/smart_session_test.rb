require File.join(File.dirname(__FILE__), '../test_helper')

Struct.new 'CGISession', :session_id
class SmartSessionTest < Test::Unit::TestCase
  fixtures :sessions
  # Replace this with your real tests.
  def setup
    @cgi_session = Struct::CGISession.new '123456'  
  end
  
  def test_simultaneous_access_session_already_created
    setup_base_session do |base_session|
      base_data = base_session.restore
      base_data[:last_viewed_page] = 'home'
    end
        
    do_simultaneous_session_access do |first_data, second_data|
      first_data[:user_id] = 123
      first_data[:last_viewed_page] = 'news'
      second_data[:favourite_food] = 'pizza'
    end
    
    assert_final_session :user_id => 123, :favourite_food => 'pizza', :last_viewed_page => 'news'
  end
  
  def test_simultaneous_access_session_not_created
    do_simultaneous_session_access do |first_data, second_data|
      first_data[:user_id] = 123
      second_data[:favourite_food] = 'pizza'
    end
    
    assert_final_session :user_id => 123, :favourite_food => 'pizza'
  end
  
  def test_simultaneous_access_delete_keys
    
    setup_base_session do |base_session|
      base_data = base_session.restore
      base_data.merge! :key_to_delete => 123, :key_to_preserve => 456
    end
    
    do_simultaneous_session_access do |first_data, second_data|
      first_data.delete :key_to_delete
      first_data[:user_id] = 789
      first_data[:key_to_preserve] = 123
      second_data[:favourite_food] = 'pizza'
    end
    
    assert_final_session :key_to_preserve => 123, :favourite_food => 'pizza', :user_id => 789
  end
  
  private
  
  def assert_final_session expected
    consolidated_session = SmartSessionStore.new(@cgi_session)
    assert_equal expected, consolidated_session.restore
  end
  
  def setup_base_session
    base_session = SmartSessionStore.new(@cgi_session)
    yield base_session if block_given?
    base_session.close
  end
  
  def do_simultaneous_session_access
    first_session = SmartSessionStore.new(@cgi_session)
    second_session = SmartSessionStore.new(@cgi_session)
    
    first_data = first_session.restore
    second_data = second_session.restore
    
    yield first_data, second_data
    
    first_session.close
    second_session.close
  end
end
