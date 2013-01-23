class SitesController < ApplicationController

  layout 'std'

  before_filter :granted

  # GET /sites
  # GET /sites.xml
  def index

    @sites = (@active_user == :admin ? SiteStats.all : @active_user.site_stats)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @sites }
    end
  end

  # GET /sites/1
  # GET /sites/1.xml
  def show
    @site = @active_user.site(params[:id])
    #@log = @site.logs.reverse[0,100]
    @log = params[:logs] == 'all' ? @site.last_logs(100000) : @site.last_logs
    @log_n = @site.last_logs_n

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @site }
    end
  end

  # GET /sites/new
  # GET /sites/new.xml
  def new
    @site = Site.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @site }
    end
  end

  # GET /sites/1/edit
  def edit
    @site = @active_user.site(params[:id])
    @action = :edit
    render :template => 'sites/new'
  end

  # POST /sites
  # POST /sites.xml
  def create
    @site = Site.new(params[:site])
    @site.user = @active_user

    respond_to do |format|
      if @site.save
        format.html { redirect_to(@site, :notice => 'Site was successfully created.') }
        format.xml  { render :xml => @site, :status => :created, :location => @site }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @site.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /sites/1
  # PUT /sites/1.xml
  def update
    @site = @active_user.site(params[:id])
    # no password update when hash is supplied
    params[:site].delete(:password) if params[:site] && (params[:site][:password] == @site.password)

    @action = :edit
    respond_to do |format|
      if @site.update_attributes(params[:site])
        format.html { redirect_to(@site, :notice => 'Site was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @site.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /sites/1
  # DELETE /sites/1.xml
  def destroy
    @site = @active_user.site(params[:id])
    @site.destroy

    respond_to do |format|
      format.html { redirect_to(sites_url) }
      format.xml  { head :ok }
    end
  end

end
