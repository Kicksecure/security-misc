//#### Copyright (C) 2019 - 2025 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
//#### See the file COPYING for copying conditions.

//#### meta start
//#### project Whonix and Kicksecure
//#### category security and apps
//#### description https://forums.whonix.org/t/enable-network-idn-show-punycode-by-default-in-thunderbird-to-fix-url-not-showing-real-domain-name-homograph-attack-punycode/8415
//#### meta end

// https://forums.whonix.org/t/enable-network-idn-show-punycode-by-default-in-thunderbird-to-fix-url-not-showing-real-domain-name-homograph-attack-punycode/8415
pref("network.IDN_show_punycode", true);

// Disable all and any kind of telemetry by default
pref("toolkit.telemetry.enabled", false);
pref("toolkit.telemetry.unified", false);
pref("toolkit.telemetry.shutdownPingSender.enabled", false);
pref("toolkit.telemetry.updatePing.enabled", false);
pref("toolkit.telemetry.archive.enabled", false);
pref("toolkit.telemetry.bhrPing.enabled", false);
pref("toolkit.telemetry.firstShutdownPing.enabled", false);
pref("toolkit.telemetry.newProfilePing.enabled", false);
pref("toolkit.telemetry.server", ""); // Defense in depth
pref("toolkit.telemetry.server_owner", ""); // Defense in depth
pref("datareporting.healthreport.uploadEnabled", false);
pref("datareporting.policy.dataSubmissionEnabled", false);
pref("toolkit.telemetry.coverage.opt-out", true); // from Firefox
pref("toolkit.coverage.opt-out", true); // from Firefox

// Disable implicit outbound traffic
pref("network.connectivity-service.enabled", false);
pref("network.prefetch-next", false);
pref("network.dns.disablePrefetch", true);
pref("network.predictor.enabled", false);

// No need to explain the problems with javascript
// If you want javascript, use your browser
// Thunderbird needs no javascript
// pref("javascript.enabled", false); // Will break setting up services that require redirecting to their javascripted webpage for login, like gmail etc. So commented out for now.

// Disable scripting when viewing pdf files
user_pref("pdfjs.enableScripting", false);

// If you want cookies, use your browser
pref("network.cookie.cookieBehavior", 2);

// Do not send user agent information
// For email clients, this is more like a relic of the past
// Completely not necessary and just exposes a lot of information about the client
// Since v115.0 Thunderbird already minimizes the user agent
// But we want it gone for good for no information leak at all
// https://hg.mozilla.org/comm-central/rev/cbbbc8d93cd7
pref("mailnews.headers.sendUserAgent", false);

// Normally we send emails after marking them with a time stamp
// That includes our local time zone
// This option makes our local time zone appear as UTC
// And rounds the time stamp to the closes minute
// https://hg.mozilla.org/comm-central/rev/98aa0bf2e719
pref("mail.sanitize_date_header", true);
