require 'rexml/document'
require 'rexml/xpath'

class SakaiWS

  @login = false
  @session = false

  attr_reader :session


  def initialize(user, pass, url)
    @login = Java::SakaiCle::SakaiLoginServiceLocator.new.getSakaiLogin(java.net.URL.new("#{url}/sakai-axis/SakaiLogin.jws"))
    @client = Java::SakaiCle::SakaiScriptServiceLocator.new.getSakaiScript(java.net.URL.new("#{url}/sakai-axis/SakaiScript.jws"))

    @client.setMaintainSession(true)

    @client.setTimeout(300000)
    @session = @login.login(user, pass)
  end


  def timeout=(val)
    @client.setTimeout(val)
  end


  # Retry a SOAP request a couple of times before giving up.  This is required
  # for the note about LDAP bugs in the header.
  def retry_call(method, *args)
    last_exception = false

    5.times do
      begin
        return @client.send(method, *args)
      rescue org.apache.axis.AxisFault => e
        print "*** SOAP call failed (#{method}(#{args.inspect}) - #{e}:  Retrying request!\n"
        last_exception = e
      end
    end

    throw last_exception
  end


  def site_exists?(siteid)
    resp = retry_call(:check_for_site, @session, siteid)

    return resp
  end


  def set_site_properties(siteid, site_properties)
    site_properties.each do |property, value|
      if property and value
        retry_call(:set_site_property, @session, siteid, property, value)
      end
    end
  end


  def set_realm_provider_id(realm, provider_id)
    retry_call(:set_authz_group_provider_id, @session, realm, provider_id)
  end


  def create_site(siteid, title, description, site_properties,
                  site_type, tool_list, opts = {})
    retry_call(:add_new_site,
               @session,    # sessionid
               siteid,      # siteid
               title,       # title
               description, # description
               '',          # shortdesc
               '',          # iconurl
               '',          # infourl
               false,       # joinable
               'Student',   # joinerrole
               (opts[:published] || false), # published
               false,       # publicview
               '',          # skin
               site_type     # type
               )


    if site_type == "course"
      set_site_properties(siteid, site_properties)
    end


    tool_list.each do |tool|
      # Need to set this sakaiPage.customTitle property to make the title stick
      # http://collab.sakaiproject.org/pipermail/sakai-dev/2011-January/010447.html

      if tool[:site_types] && !tool[:site_types].include?(site_type)
        # This tool isn't applicable to this site type, so skip it.
        next
      end

      two_column = (tool[:left_column_tools] || tool[:right_column_tools]) ? 1 : 0

      retry_call(:add_new_page_to_site,
                 @session,            # sessionid
                 siteid,              # siteid
                 tool[:pagetitle],    # pagetitle
                 two_column           # pagelayout (single column)
                 )

      if tool[:pagetitle] == "Home"
        retry_call(:add_config_property_to_page,
                   @session,
                   siteid,
                   tool[:pagetitle],
                   "is_home_page",
                   "true"
                   )
      end

      retry_call(:add_config_property_to_page,
                 @session,               # sessionid
                 siteid,                 # siteid
                 tool[:pagetitle],       # pagetitle
                 "sitePage.customTitle", # propname
                 "true"                  # propvalue
                 )

      if two_column == 1
        [[:left_column_tools, 0], [:right_column_tools, 1]].each do |k, col|
          tool[k].each_index do |row|
            retry_call(:add_new_tool_to_page,
                       @session,                   # sessionid
                       siteid,                     # siteid
                       tool[:pagetitle],           # pagetitle
                       tool[k][row][:tooltitle],   # tooltitle
                       tool[k][row][:toolid],      # toolid
                       "#{row},#{col}"             # layouthints
                       )
          end
        end
      else
        retry_call(:add_new_tool_to_page,
                   @session,                   # sessionid
                   siteid,                     # siteid
                   tool[:pagetitle],           # pagetitle
                   tool[:tooltitle],           # tooltitle
                   tool[:toolid],              # toolid
                   ""                          # layouthints
                   )
      end
    end
  end


  def add_member(siteid, userid, role)
    resp = retry_call(:add_member_to_site_with_role,
               @session, # sessionid'
               siteid,   # siteid
               userid,   # eid
               role      # roleid
               )

    print "Added #{userid} to #{siteid} with role #{role}: #{resp}\n"

    return resp
  end


  def role_exists?(group, role)
    resp = retry_call(:check_for_role_in_authz_group,
                      @session, group, role)

    return resp
  end


  def realm_exists?(realm)
    resp = retry_call(:check_for_authz_group,
                      @session, realm)

    return resp
  end


  def add_realm(realm)
    resp = retry_call(:add_new_authz_group,
                      @session, realm)

    return resp
  end


  def add_role(group, role)
    resp = retry_call(:add_new_role_to_authz_group,
                      @session, group, role, role)

    return resp
  end


  def remove_role(group, role)
    resp = retry_call(:remove_role_from_authz_group,
                      @session, group, role, role)

    return resp
  end


  def add_function_to_role(group, role, function)
    resp = retry_call(:allow_function_for_role,
                      @session, group, role, function)

    return resp
  end


  def remove_function_from_role(group, role, function)
    resp = retry_call(:disallow_function_for_role,
                      @session, group, role, function)

    return resp
  end


  def remove_member(siteid, userid)
    resp = retry_call(:remove_member_from_site,
               @session, #    sessionid'
               siteid,   # siteid
               userid   # eid
               )

    print "Removed #{userid} from #{siteid}: #{resp}\n"

    return resp
  end


  def add_tool_and_page_to_site(siteid, page_title, tool_title, toolid)
    retry_call(:add_tool_and_page_to_site,
               @session,
               siteid,
               toolid,
               page_title,
               tool_title,
               0,
               1000,            # end!
               false)
  end


  def site_has_tool?(siteid, toolid)
    result = retry_call(:get_pages_and_tools_for_site,
                        @session,
                        siteid)

    doc = REXML::Document.new(result)

    REXML::XPath.each doc, '//tool-id' do |tool|
      if tool.text == toolid
        return true
      end
    end

    false
  end


  def remove_site(siteid)
    resp = retry_call(:remove_site, @session, siteid)

    print "Removed #{siteid}: #{resp}\n"

    return resp
  end


  def remove_sites(siteids)
    resp = retry_call(:remove_sites, @session, siteids)

    print "Removed #{siteids.inspect}: #{resp}\n"

    return resp
  end



  def close
    if @login and @session
        @login.logout(@session)
    end
  end
end
