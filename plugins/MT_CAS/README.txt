= Configuration =
You need to specify the following three configuration directives in your mt-config.cgi.

; AuthenticationModule
: Must be "CAS"
; AuthLoginURL
: The URL where CAS is on.  Do NOT include the "/login" part.  For example, it should be like http://localhost:8080/cas for the default installation of CAS server.
; AuthLogoutURL
: The URL where a user can logout from CAS.  DO include the "/logout" part.  For example, it should be like http://localhost:8080/cas/logout for the default installation of CAS server.

== Example ==
 CGIPath http://sixapart.jp/mt/
  
 ObjectDriver DBI::mysql
 Database mt
 DBUser user
 DBPassword password
  
 AuthenticationModule CAS
 AuthLoginURL http://localhost:8080/cas
 AuthLogoutURL http://localhost:8080/cas/logout

= External Library =
The plugin contains modified version of AuthCAS module in its extlib directory, which was originally obtained from the PerlCAS project [1].  However it is modified so it works on the environment on which author of the plugin implemented the plugin.  You may want to use the original version of AuthCAS module particularly if you want to use SSL connection to CAS.

[1] http://sourcesup.cru.fr/projects/perlcas// 

= Community Templates =
If you use the plugin with Community Blog or Community Forum template sets, or to be more precise, if you use the plugin with GlobalJavascript global template, You have to modify the template in a line.

Find mtSignIn function, and modify the line below

 var url = '<$mt:CGIPath$><$mt:CommunityScript>?__mode=login&blog_id=<$mt:BlogID$>';

... to below

 var url = '<$mt:CGIPath$><$mt:CommunityScript>?__mode=cas_login&blog_id=<$mt:BlogID$>';

... so it will request "__mode=cas_login" instead of "__mode=login".
