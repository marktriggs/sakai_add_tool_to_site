Adding tools to existing sites
==============================

# One-time setup instructions

## Check your sakai.properties

You will need to set some `sakai.properties` entries to make sure the
web services are accessible.  A minimal configuration:

     webservices.allow=127\\.0\\.0\\.1
     webservices.allowlogin=true

You'll need to restart Sakai for these changes to take effect.


## Bootstrap the script

Run the `bootstrap.sh` script.  This will download JRuby and
will interrogate your Sakai web services to build client stubs from
the WSDL definition:

     # This assumes you're running the script directly on your Sakai server
     ./bootstrap.sh http://localhost:8080/

You should see output like this:

     $ ./bootstrap.sh 'http://localhost:8080/'
     log4j:WARN No appenders could be found for logger (org.apache.axis.i18n.ProjectResourceBundle).
     log4j:WARN Please initialize the log4j system properly.
     log4j:WARN No appenders could be found for logger (org.apache.axis.i18n.ProjectResourceBundle).
     log4j:WARN Please initialize the log4j system properly.
     Note: Some input files use unchecked or unsafe operations.
     Note: Recompile with -Xlint:unchecked for details.
     added manifest
     adding: sakai/(in = 0) (out= 0)(stored 0%)
     adding: sakai/cle/(in = 0) (out= 0)(stored 0%)
     adding: sakai/cle/SakaiScript_PortType.class(in = 5581) (out= 1251)(deflated 77%)
     adding: sakai/cle/SakaiLoginService.class(in = 395) (out= 232)(deflated 41%)
     adding: sakai/cle/SakaiScriptService.class(in = 401) (out= 234)(deflated 41%)
     adding: sakai/cle/SakaiLoginServiceLocator.class(in = 3606) (out= 1735)(deflated 51%)
     adding: sakai/cle/SakaiScriptSoapBindingStub.class(in = 68228) (out= 19435)(deflated 71%)
     adding: sakai/cle/SakaiLogin_PortType.class(in = 365) (out= 219)(deflated 40%)
     adding: sakai/cle/SakaiLoginSoapBindingStub.class(in = 6233) (out= 2946)(deflated 52%)
     adding: sakai/cle/SakaiScriptServiceLocator.class(in = 3623) (out= 1722)(deflated 52%)


## Edit the configuration file

You will need to add your admin username, password and Sakai URL to
the `config.rb` file.  Just replace the example values that are
already there.


# Running the script

Now that we're all set up, you can run the script by providing a CSV
that tells it which tools to add to which sites.  From the script's
usage information:

> input.csv is a comma-separated file with rows like this:
>
>   site_id,tool_id,page_title,tool_title,force
>
> If the "force" column contains the string "yes", "true" or "1", the tool will be
> added to the site irrespective of whether there's already an instance of that
> tool_id there.  Otherwise, the tool will only be added if there isn't one
> already.
>
> For example a file like:
>
>   38dec74d-ad79-490e-a0cd-3ccd09275e14,sakai.podcasts,Podcasts,Podcasts
>   38dec74d-ad79-490e-a0cd-3ccd09275e14,sakai.podcasts,Podcasts,Podcasts
>
> will add the Podcasts tool once at most, while:
>
>   38dec74d-ad79-490e-a0cd-3ccd09275e14,sakai.podcasts,Podcasts,Podcasts,true
>   38dec74d-ad79-490e-a0cd-3ccd09275e14,sakai.podcasts,Podcasts,Podcasts,true
>
> will add two instances of the tool.


You can generate the CSV file using Excel or your text editor of
choice.  Generally we'll get the list of Site IDs by querying the
database directly.  Some examples:

     # Get all course sites
     select site_id from sakai_site where type = 'course';

     # Get all course sites from a particular term
     select ss.site_id
     from sakai_site ss
     inner join sakai_site_property ssp on ss.site_id = ssp.site_id
     where ss.type = 'course' AND
       ssp.name = 'term_eid' AND
       ssp.value = 'Fall_2014';


Output from running the script looks like this:

     $ ./add_tools_to_sites.sh config.rb sites.csv
     log4j:WARN No appenders could be found for logger (org.apache.axis.i18n.ProjectResourceBundle).
     log4j:WARN Please initialize the log4j system properly.
     Adding tool with ["ac4b9a94-71a4-4287-94e3-a8a304d7ca57", "sakai.podcasts", "Podcasts", "Podcasts"]
     success
     Adding tool with ["b489b706-5707-4ba5-99f1-d83450c50322", "sakai.podcasts", "Podcasts", "Podcasts"]
     success
     Adding tool with ["bac396ef-1b8a-4729-8d97-b8663da2645b", "sakai.podcasts", "Podcasts", "Podcasts"]
     success
