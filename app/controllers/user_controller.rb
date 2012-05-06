# encoding: UTF-8

post '/user' do
  @user = User.new\
    email: session[:user_email],
    gravatar_id: session[:user_gravatar_id],
    name: params[:user][:name]
  if @user.save
    session.delete_if { |k, v| k.to_s.start_with? 'user' }
    session[:user_id] = @user.id.to_s
    flash[:notice] = '用户创建成功'
    { redirect: '/' }.to_json
  else
    { error: { user: @user.errors } }.to_json
  end
end
