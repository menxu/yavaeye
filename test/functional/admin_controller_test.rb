require_relative "../test_helper"

class AdminControllerTest < FunctionalTestCase
  def setup
    login
    session['admin'] = true
    @user_params = Factory.build(:user).attributes.keep_if do |k, v|
      %w[nick credentials gravatar_id].include? k
    end
  end

  def test_index
    access_protected :get, '/admin/user'
  end

  def test_edit
    access_protected :get, "/admin/user/#{@user.id}/edit"
  end

  def test_csrf_create
    count = User.count
    post '/admin/user', {user: @user_params}
    assert_equal count, User.count
  end

  def test_create
    count = User.count
    post '/admin/user', with_csrf(user: @user_params), @env
    assert_equal count + 1, User.count
  end

  def test_create_with_invalid_json
    count = User.count
    @user_params['unfollowing_ids'] = "{}"
    post "/admin/user", with_csrf(user: @user_params)
    assert_equal count, User.count
  end

  def test_update_with_json
    user = Factory(:user)
    put "/admin/user/#{user.id}", with_csrf(user: {'unfollowing_ids' => [@user.id].to_json})
    user.reload
    assert_equal [@user.id.to_s], user.unfollowing_ids
  end

  def test_index_nav
    get '/admin/user', {}
    assert_select 'a[href="/admin/user/new"]'
    assert_select 'a[href="/admin/user"]'
  end

  def test_new_nav 
    get '/admin/user/new', {}
    assert_select 'a[href="/admin/user/new"]'
    assert_select 'a[href="/admin/user"]'
  end

  def test_edit_nav 
    get "/admin/user/#{@user.id}/edit", {}
    assert_select 'a[href="/admin/user/new"]'
    assert_select 'a[href="/admin/user"]'
    assert_select %|a[href="/admin/user/#{@user.id}/edit"]|
  end

  private

  def access_protected verb, url
    send verb, url, {}
    assert_equal 200, status
    send verb, url
    assert_equal 302, status
  end

end

