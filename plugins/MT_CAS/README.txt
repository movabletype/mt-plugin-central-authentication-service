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
 
 # Or if you use SSL
 #AuthLoginURL https://localhost:8443/cas
 #AuthLogoutURL https://localhost:8443/cas/logout

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
