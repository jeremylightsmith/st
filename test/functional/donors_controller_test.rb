require File.dirname(__FILE__) + '/../test_helper'

class DonorsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  def setup
    # allows you to inspect email notifications
    @emails = ActionMailer::Base.deliveries
    @emails.clear
  end
  
  test "A new donor request results in an empty donor template" do
    get :new
    assert_template 'new'
    assert_response :success
  end
  
  test "Successful donor creation redirects to Signup Completed flow" do
    assert_difference Donor, :count, 1 do
      post :create, :donor => min_donor_props
    end
    donor = Donor.find_by_login(min_donor_props[:login])
    assert_redirected_to donor_path(donor)
    assert_equal flash[:notice], :email_signup_thanks.l_with_args(:email => donor.email)
    
    assert_equal 1, @emails.size
    assert_equal "[SaveTogether] Your SaveTogether account has been activated!", @emails[0].subject
  end
  
  test "Donor does not receive registration email if configuration turned off" do
    donor_setting_restore = SaveTogether::Notifications.donors
    SaveTogether::Notifications.donors = false
    
    post :create, :donor => min_donor_props
    assert_equal 0, @emails.size
    
    SaveTogether::Notifications.donors = donor_setting_restore
  end
  
  test "Unsuccessful donor creation renders the new template" do
    assert_difference Donor, :count, 0 do
      post :create, :donor => min_donor_props(:login => nil)
    end
    assert_template 'new'
    assert_response :success
  end

  test "Successful donor creation with pledge in session" do
    saver = users(:saver)
    session[:pledge_id] = invoices(:pledge).id
    session[:saver_id] = saver.id

    assert_difference Donor, :count, 1 do
      post :create, :donor => min_donor_props
    end
    donor = Donor.find_by_login(min_donor_props[:login])
    assert_redirected_to :controller => :pledges, :action => :savetogether_ask
    assert_equal flash[:notice], :email_signup_thanks.l_with_args(:email => donor.email)

    assert !session[:pledge_id].nil?
    assert !session[:saver_id].nil?

    assert !session[:user].nil?
    user = Donor.find(session[:user])
    assert !user.nil?
  end

  test "Unsuccessful donor creation with pledge in session" do
    saver = users(:saver)
    session[:pledge_id] = invoices(:pledge).id
    session[:saver_id] = saver.id

    assert_difference Donor, :count, 0 do
      post :create, :donor => min_donor_props(:login => nil)
    end
    assert_template 'new'
    assert_response :success

    assert !session[:pledge_id].nil?
    assert !session[:saver_id].nil?
  end
  
  test "Donors can be indexed" do
    get :index
    assert_template 'index'
    assert_response :success
  end

  protected
  
  def min_donor_props(options = {})
    {
      
      :login => "a@b.com",
      :first_name => "Min",
      :last_name => "Donor",
      :login_confirmation => "a@b.com",
      :password => "foo2thebar",
      :password_confirmation => "foo2thebar",
      :birthday => 21.years.ago
      
    }.merge(options)
    
  end

end
