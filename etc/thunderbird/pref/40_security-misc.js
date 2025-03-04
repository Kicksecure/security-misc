//#### Copyright (C) 2019 - 2025 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
//#### See the file COPYING for copying conditions.

//#### meta start
//#### project Whonix and Kicksecure
//#### category security and apps
//#### description https://forums.whonix.org/t/enable-network-idn-show-punycode-by-default-in-thunderbird-to-fix-url-not-showing-real-domain-name-homograph-attack-punycode/8415
//#### meta end

// https://forums.whonix.org/t/enable-network-idn-show-punycode-by-default-in-thunderbird-to-fix-url-not-showing-real-domain-name-homograph-attack-punycode/8415
pref("network.IDN_show_punycode", true);

//### Telemetry
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
pref("toolkit.telemetry.coverage.opt-out", true); // from Firefox
pref("toolkit.coverage.opt-out", true); // from Firefox

// Disable Thunderbird archiving telemetry data locally
// Thunderbird saves data to ~/.thunderbird/profile.default/datareporting/ 
pref("datareporting.healthreport.about.reportUrl", "data:text/plain,");
pref("datareporting.policy.dataSubmissionEnabled", false);
pref("datareporting.healthreport.uploadEnabled", false);
pref("datareporting.healthreport.service.enabled", false);
pref("datareporting.healthreport.service.firstRun", false);
pref("datareporting.healthreport.service.lastDataSubmissionRequested", 0);
pref("datareporting.healthreport.service.lastDataSubmissionSuccessful", 0);
pref("datareporting.healthreport.service.submitEnabled", false);

// Disable implicit outbound traffic
pref("network.connectivity-service.enabled", false);
pref("network.prefetch-next", false);
pref("network.dns.disablePrefetch", true);
pref("network.predictor.enabled", false);

//### Security
// No need to explain the problems with javascript
// If you want javascript, use your browser
// Thunderbird needs no javascript
// pref("javascript.enabled", false); // Will break setting up services that require redirecting to their javascripted webpage for login, like gmail etc. So commented out for now.

// JavaScript hardening. Source https://gitlab.torproject.org/tpo/applications/tor-browser/-/blob/tor-browser-115.10.0esr-13.5-1/browser/components/securitylevel/content/securityLevel.js?ref_type=heads
// (we are applying the "high" profile)
pref("javascript.options.ion", false);
pref("javascript.options.baselinejit", false);
pref("javascript.options.native_regexp", false);
pref("media.webaudio.enabled", false);
pref("mathml.disabled", true);
pref("gfx.font_rendering.opentype_svg.enabled",  false);
pref("svg.disabled",  true);

// Disable WebGL.
pref("webgl.disabled", true);

// Disable WebM, WAV, Ogg, PeerConnection.
pref("media.navigator.enabled", false);
pref("media.peerconnection.enabled", false);
pref("media.cache_size", 0);

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

//### Performance
// Compact folders on exit
// Compact when it will save over 100 KB
pref("mail.folder.compact_on_exit", true);
pref("mail.folder.compact_threshold", 100);
