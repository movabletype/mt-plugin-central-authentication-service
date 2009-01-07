= Configuration =
You need to specify the following three configuration directives in your mt-config.cgi.

; AuthenticationModule
: Must be "CAS"
; AuthLoginURL
: The URL where CAS is on.  Do NOT include the "/login" part.  For example, it should be like http://localhost:8080/cas for the default installation of CAS server.
; AuthLogoutURL
: The URL where a user can logout from CAS.  DO include the "/logout" part.  For example, it should be like http://localhost:8080/cas/logout for the default installation of CAS server.

Additionally, if your network does not allow outbound HTTP request from inside Movable Type application, you will be required to add MT_CAS_ValidationURL configuration directive.

; MT_CAS_ValidationURL
: The URL of the server which offers validation service (usually the same server you specify to AuthLoginURL).  Do NOT include "/serviceValidate" part.  For example it should read like http://localhost:8080 (no trailing slash).  Default value is undefined.  If not specified, AuthLoginURL will be used to validate session ticket.

== Example ==
 CGIPath http://sixapart.jp/mt/
  
 ObjectDriver DBI::mysql
 Database mt
 DBUser user
 DBPassword password
  
 AuthenticationModule CAS
 AuthLoginURL http://localhost:8080/cas
 AuthLogoutURL http://localhost:8080/cas/logout
 MT_CAS_ValidationURL http://server_name_inside_firewall:8080
 
 # Or if you use SSL
 #AuthLoginURL https://localhost:8443/cas
 #AuthLogoutURL https://localhost:8443/cas/logout
 #MT_CAS_ValidationURL https://server_name_inside_firewall:8443

= Editing JavaScript Template =
The consumer side of the login process works as below.  In order for the browser to navigate to the correct address, users may need to edit JavaScript (or GlobalJavaScript, depending on what template sets they use) template to specify the login URL of MT used in the step 2.

# User clicks "Sign In" link on the blog entry to comment.
# MT accepts the request first, and redirect to CAS login URL.
# User logs in to CAS.
# CAS redirects back to the original blog entry.

If you use the plugin with Community Blog or Community Forum template set, or to be more precise, if you use the plugin with GlobalJavascript global template, You have to modify the template in a line.

Find mtSignIn function, and modify the line below

 var url = '<$mt:CGIPath$><$mt:CommunityScript>?__mode=login&blog_id=<$mt:BlogID$>';

... to below

 var url = '<$mt:CGIPath$><$mt:CommunityScript>?__mode=cas_login&blog_id=<$mt:BlogID$>';

... so it will request "__mode=cas_login" instead of "__mode=login".

If you use the plugin with either Classic Blog or Professional Website template set, you don't have to modify JavaScript template.
