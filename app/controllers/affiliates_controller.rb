class AffiliatesController < AffiliateAuthController
  before_filter :require_affiliate, :except=> [:index]
  before_filter :setup_affiliate, :only=> [:edit, :update, :push_content_for, :destroy]

  def index
  end

  def edit
    @affiliate.staged_domains = @affiliate.domains
    @affiliate.staged_header = @affiliate.header
    @affiliate.staged_footer = @affiliate.footer
  end

  def new
    @affiliate = Affiliate.new
  end

  def create
    @affiliate = Affiliate.new(params[:affiliate].merge(:user_id=>@current_user.id))
    if @affiliate.save
      @affiliate.update_attributes(
        :domains => @affiliate.staged_domains,
        :header => @affiliate.staged_header,
        :footer => @affiliate.staged_footer)
      flash[:success] = "Affiliate successfully created"
      redirect_to account_path
    else
      render :action => :new
    end
  end

  def update
    @affiliate.attributes = params[:affiliate]
    if @affiliate.save
      @affiliate.update_attribute(:has_staged_content, true)
      flash[:success]= "Staged changes to your affiliate successfully."
      redirect_to account_path
    else
      render :action => :edit
    end
  end

  def push_content_for
    @affiliate.update_attributes(
      :has_staged_content=> false,
      :domains => @affiliate.staged_domains,
      :header => @affiliate.staged_header,
      :footer => @affiliate.staged_footer)
    flash[:success] = "Staged content is now visible"
    redirect_to account_path
  end

  def destroy
    @affiliate.destroy
    flash[:success]= "Affiliate deleted"
    redirect_to account_path
  end

end
