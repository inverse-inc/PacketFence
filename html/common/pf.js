/**
 * PacketFence Javascript Library
 *
 * @author      Inverse inc. <info@inverse.ca>
 * @copyright   2005-2015 Inverse inc.
 * @license     http://opensource.org/licenses/gpl-2.0.php      GPL
 */

/**
   networkAccessCallback

   Called when access to the network outside registration or quarantine works
 */
var network_redirected = false;
function networkAccessCallback(destination_url) {

  network_redirected = true;

  //show a web notification
  if (txt_web_notification) showWebNotification(txt_web_notification, '/content/images/unlock.png');

  // Try to redirect browser in 3 seconds
  setTimeout(function() {
    performRedirect(destination_url);
  }, 3000);
}

/**
   performRedirect

   Simple wrapper to redirect the browser. The wrapper enables us to call the redirect with .delay().
 */
function performRedirect(destination_url) {
  top.location.replace(destination_url);
}

/**
   detectNetworkAccess

   Adding an image to a provided div in order to detect if network access outside registration or quarantine works.
   Will trigger networkAccessCallback() if image loads successfully.

   Browser support:
   Known to work with Internet Explorer 8 / 9, Firefox 3.6 / 4, Chrome 9 / 10, Safari 5.

   Firefox 3.5+: We are sending a special HTTP Header (X-DNS-Prefetch-Control off) to prevent the caching of DNS entries
   for more details see:
   - https://developer.mozilla.org/En/Controlling_DNS_prefetching
   - http://dev.chromium.org/developers/design-documents/dns-prefetching

   Opera 11 is broken (doesn't fire img's onload) we put in a special text to notice users
   http://my.cn.opera.com/community/forums/topic.dml?id=880632&t=1298063094
 */

Date.now = Date.now || function() { return +new Date; };

function detectNetworkAccess(retry_delay, destination_url, external_ip, image_path) {
  "use strict";
  var errorDetected, loaded, netdetect, checker, initNetDetect;

  netdetect = $('#netdetect');
  netdetect.error(function() {
    errorDetected = true;
    loaded = false;
  });
  netdetect.load(function() {
    errorDetected = false;
    loaded = true;
  });
  initNetDetect = function() {
    errorDetected = loaded = undefined;
    var netdetect = $('#netdetect');
    netdetect.attr('src',"http://" + external_ip + image_path + "?r=" + Date.now());
    setTimeout(checker, retry_delay * 1000);
  };
  checker = function() {
    var netdetect = $('#netdetect');
    if (errorDetected === true) {
      initNetDetect();
    }
    else if (loaded === true) {
      networkAccessCallback(destination_url);
    }
    else {
      // Check the width or height of the image since we do not know if it is loaded
      if (netdetect.width() || netdetect.height()) {
        networkAccessCallback(destination_url);
      } else {
        initNetDetect();
      }
    }
  }
  initNetDetect();
}

/**
   initWebNotifications

   Requests the necessary permissions to display Web Notifications if it's supported by the browser
 */
function initWebNotifications(){
  if (window.Notification){
    Notification.requestPermission(function(status) {
      // This allows to use Notification.permission with Chrome/Safari
      if (Notification.permission !== status) {
        Notification.permission = status;
        console.log(Notification.status);
      }
    });
  }
}

/**
   canWebNotifications

   Checks if the browser supports Web notifications and that the user has granted the permissions to show Web notifications
 */
function canWebNotifications(){
  if (window.Notification && Notification.permission === "granted") {
    return true;
  }
  return false;
}

/**
   showWebNotifications

   Displays a web notification if the user accepted it and if the browser supports it.
*/
function showWebNotification(message, icon){
  if (canWebNotifications()){
    var notification = new Notification(message, {icon:icon});
  }  
}
