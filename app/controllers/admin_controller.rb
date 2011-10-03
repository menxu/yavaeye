before "/admin" do
  redirect "/admin-login" if !session['admin']
end

before "/admin*" do
  @models = Module.constants.map{|c| Module.const_get c }.select do |c|
    (c.is_a? Class) and (c.include? Mongoid::Document)
  end
end

before "/admin/*" do
  redirect "/admin-login" if !session['admin']
  /\/admin\/(?<model_name>\w+)/ =~ request.path
  next if (!model_name or model_name == 'secret')
  @model = Module.const_get(model_name.camelize) rescue next
  @fields =
    if @model.respond_to?(:admin_fields)
      @model.admin_fields
    else
      @model.fields.map do |(name, ty)|
        next if %w[_type id _id created_at updated_at deleted_at].include?(name)
        next if (ty.type == Hash or ty.type == Array)
        ty = ty.type == Boolean ? 'checkbox' : 'text'
        [name, ty, "#{model_name}[#{name}]", "#{model_name}_#{name}"]
      end
    end
  @fields.compact!
end

get "/admin-login" do
  slim (Secret.first_time ? :'admin/secret' : :'admin/login'), layout: :admin
end

post "/admin-login" do
  if Secret.first_time
    if params[:p] != params[:p_confirm] or params[:p].size < 6
      @error = "Password not match or too short"
      slim :'admin/secret', layout: :admin
    else
      initialize_admin
      session['admin'] = true
      flash[:notice] = "Admin data initialized"
      redirect "/admin"
    end
  elsif !(Secret.validate_admin_password params[:p])
    slim :'admin/login', layout: :admin
  else
    session['admin'] = true
    redirect "/admin"
  end
end

get "/admin-logout" do
  session.delete 'admin'
  redirect "/admin-login"
end

get "/admin/?" do
  slim :'admin/index', layout: :admin
end

get "/admin/secret" do
  slim :'admin/secret', layout: :admin
end

post "/admin/secret" do
  if params[:p] != params[:p_confirm] or params[:p].size < 6
    @error = "Password not match or too short"
    slim :'admin/secret', layout: :admin
  else
    initialize_admin
    flash[:notice] = "Updated"
    redirect "/admin"
  end
end

get "/admin/:model/?" do
  per_page = 20
  current_page = params[:p].to_i - 1
  current_page = 0 if current_page < 0
  @fields = @model.fields.select do |(name)|
    ! %w[_type _id created_at updated_at deleted_at].include? name
  end
  @objects = @model.desc(:created_at).skip(current_page * per_page).limit(per_page)
  slim :'model/index', layout: :admin
end

get "/admin/:model/new" do
  @object = @model.new
  slim :'model/new', layout: :admin
end

post "/admin/:model/?" do |model|
  @object = @model.new(params[model.singularize])
  if @object.save
    flash[:notice] = 'object was successfully created.'
    redirect "/admin/#{model}/#{@object.id}/edit"
  else
    slim :'model/new', layout: :admin
  end
end

get "/admin/:model/:id/edit" do
  @object = @model.find(params[:id])
  slim :'model/edit', layout: :admin
end

put "/admin/:model/:id/?" do |model|
  @object = @model.find(params[:id])
  if @object.update_attributes(params[model.singularize])
    flash[:notice] = 'object was successfully updated.'
    redirect "/admin/#{model}/#{@object.id}/edit"
  else
    slim :'model/edit', layout: :admin
  end
end

delete "/admin/:model/:id/?" do |model|
  object = @model.find(params[:id])
  # account has special proceed with current_account
  if object != current_account && object.destroy
    flash[:notice] = 'object was successfully destroyed.'
  else
    flash[:error] = 'failed to delete object'
  end
  redirect "/admin/#{model}"
end