<?php
if(!session_id()){
	session_start();
}
$file = '/KeyPortal/'; // location of the ip-allow file
$subdomain = "bo"; // the subdomain of the published site, as in bo.domain.com
$FQDN = "newskoolmedia.nl"; // the FQDN without www or bo
$url = $subdomain . '.' . $FQDN;


//Include Google client library
include_once 'src/Google_Client.php';
include_once 'src/contrib/Google_Oauth2Service.php';

/*
 * Configuration and setup Google API
 */
$clientId = '798538457749-7qdd03nbvlo0jqenmmmrri5109o4ptui.apps.googleusercontent.com'; //Google client ID
$clientSecret = 'UWFDrhArO26rHVw4gQLW-miO'; //Google client secret
$redirectURL = 'http://dev.systemsvalley.com/wordpress/google-auth/g-call-back.php'; //Callback URL
$siteURL  = 'http://dev.systemsvalley.com/wordpress/google-auth/';
$vdomain = "bdu.nl";
//Call Google API
$gClient = new Google_Client();
$gClient->setApplicationName('Odoo Key Portal');
$gClient->setClientId($clientId);
$gClient->setClientSecret($clientSecret);
$gClient->setRedirectUri($redirectURL);

$google_oauthV2 = new Google_Oauth2Service($gClient);
?>
