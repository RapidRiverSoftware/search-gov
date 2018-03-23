class Sites::UsersController < Sites::SetupSiteController
  include ::Hintable

  before_filter :load_hints, only: %i(create new)

  def index
    @users = @site.users
  end

  def new
    @user = @site.users.new
  end

  def create
    @user = User.find_by_email user_params[:email].strip
    if @user.nil?
      @user = User.new_invited_by_affiliate(current_user, @site, user_params)
      if @user.save
        @user.add_to_affiliate(@site, "@[Contacts:#{current_user.nutshell_id}]")
        message = "We've created a temporary account and notified #{@user.email} on how to login and to access this site."
        redirect_to site_users_path(@site), flash: { success: message }
      else
        render action: :new
      end
    elsif !@site.users.exists?(id: @user.id)
      @user.add_to_affiliate(@site, "@[Contacts:#{current_user.nutshell_id}]")
      Emailer.new_affiliate_user(@site, @user, current_user).deliver_now
      redirect_to site_users_path(@site), flash: { success: "You have added #{@user.email} to this site." }
    else
      @user = User.new user_params
      flash.now[:notice] = "#{@user.email} already has access to this site."
      render action: :new
    end
  end

  def destroy
    @user = User.find params[:id]
    @user.remove_from_affiliate(@site, "@[Contacts:#{current_user.nutshell_id}]")
    redirect_to site_users_path(@site), flash: { success: "You have removed #{@user.email} from this site." }
  end

  private

  def user_params
    @user_params ||= params.require(:user).permit(:contact_name, :email)
  end
end
