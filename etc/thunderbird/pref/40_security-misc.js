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
pref("general.useragent.override", "");

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

//### Privacy
// Geolocation
pref("geo.enabled", false);
pref("geo.provider.use_geoclue", false)
pref("geo.provider.network.url", "")

// Disable Google Safe Browsing (#22567).
pref("browser.safebrowsing.enabled", false);
pref("browser.safebrowsing.malware.enabled", false);

// Disable Microsoft Family Safety (From TBB: #21686).
pref("security.family_safety.mode", 0);

// Likely privacy violations
// https://blog.torproject.org/blog/experimental-defense-website-traffic-fingerprinting
// https://bugs.torproject.org/3914
pref("network.http.pipelining", true);
pref("network.http.pipelining.aggressive", true);
pref("network.http.pipelining.maxrequests", 12);
pref("network.http.connection-retry-timeout", 0);
pref("network.http.max-persistent-connections-per-proxy", 256);
pref("network.http.pipelining.reschedule-timeout", 15000);
pref("network.http.pipelining.read-timeout", 60000);

// We do not fully understand the privacy issues of the SPDY protocol
pref("network.http.spdy.enabled", false);

// Don't save email addresses from sent emails
// Do not automatically add outgoing sent emails to address book "Collected Addresses" for privacy
pref("mail.collect_email_address_outgoing", false);

// Clean mailbox server-side
// Delete messages from server regardless if POP3 or IMAP is set as protocol for accounts
// Delete POP3 messages from server when moved for example when moved to trash in Thunderbird
// Delete IMAP messages from server when deleted or marked for deletion in Thunderbird
pref("mail.pop3.deleteFromServerOnMove", true);
pref("mail.imap.expunge_after_delete", true);

// Don't leak the locale "Date & Time" via reply quote header
pref("mailnews.reply_header_type", 1);
pref("mailnews.reply_header_authorwrotesingle", "#1 wrote:");

//### Nuances & Annoyances 
// Disable donation banner
pref("mailnews.donationbanner.enabled", false);
pref("app.donation.eoy.version.viewed", 999999);
