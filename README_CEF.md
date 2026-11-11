# LS:RP CEF + ReSA

Implemented: master-account username, registration/login, three character slots,
slot selection and entering the world. Empty slots open the existing native
name dialog and character creator. Character creation, detailed character info,
notifications and other game menus remain in their existing UI. Character
deletion is still unavailable, matching the original gamemode.

## Installed dependency

- Upstream: https://github.com/aurora-mp/omp-cef
- Pinned release: https://github.com/aurora-mp/omp-cef/releases/tag/v1.4.0
- Archive: `cef-omp-v1.4.0-x86.zip`
- SHA-256: `42a165a5ceae06329215afbda2a83a148bb26a61ddaa1d5a3d07bed6744e7da5`
- Server component: `components/Cef.dll`; compiler include: `qawno/include/cef.inc`.
- Restore/reinstall: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/setup_cef.ps1`.
- This is an open.mp component: do not add it to `pawn.legacy_plugins`.

The v1.4.0 archive's component reports internal version 1.3.0 in its startup
log. The downloaded archive hash above was verified against the release.

## Test in game

1. Compile with `COMPILE.bat`, then start/restart the server normally.
2. Allow inbound UDP **7779** when the game port is 7777. This setup has not
   modified Windows Firewall or router rules.
3. Use an up-to-date ReSA client and connect. ReSA advertises built-in support
   for both samp-cef and omp-cef: https://resa-mp.com/features . Actual client
   version compatibility still needs an in-game test.
4. The native username prompt appears immediately. When `OnCefReady` arrives,
   an idle username prompt upgrades to CEF. Authentication already underway
   is not interrupted; CEF can be used at the character selector afterward.
5. Try new account, existing account, incorrect password, occupied slot,
   empty slot, reconnect and entering the world.
6. Try a client without CEF: the existing dialogs/TextDraws should remain.
7. The CEF footer or `/classicui` switches to native UI for this connection.

Resources are registered from `scriptfiles/cef/lsrp/` and automatically packaged
by the component. Restart after frontend changes so the package is refreshed.
No external web host, Node.js service or frontend build is required.

The shipped `index.html` embeds its JavaScript with a matching CSP SHA-256.
After editing `app.js`, run `node tools/build_cef_ui.cjs` before restarting.
This avoids relying on external deferred scripts in resource-backed WebViews.
Logo/theme: the supplied GTASA Vietnamese logo, white and blue; the account
field is labelled “Tên đăng nhập”.

For event troubleshooting, search the server log for `[GTASA UI]`: resources
ready, page ready, submit and account lookup finished. These diagnostics never
log submitted usernames or passwords. The form reports input errors, missing
bridge, and no response instead of silently ignoring the Continue button.

ReSA compatibility: a local ReSA 1.1.6 session delivered the page-ready event
to Pawn, while the UI did not receive the server's screen event. The bridge
therefore mirrors non-secret screen/slot state through `CEF_LoadUrl` using a
URL fragment. The page applies both initial fragments and `hashchange` updates.
Identical snapshots are suppressed to prevent ready/navigation loops; revisions
allow retries and password errors to refresh the same screen. Passwords/hashes
are never included. All authorization and slot ownership checks remain in Pawn.
This is a compatibility fallback, not evidence that ReSA's entire CEF API works.

The UI test includes a case where no server events arrive: navigation alone
must unlock the username form, send submit, show login/errors and render slots.

Live ReSA verification on 11 November 2026, 22:22 (Asia/Bangkok): the real
client sent username submit, account lookup returned zero rows, the server
opened registration, received the password submit, and advanced to character
selection. Navigation snapshots progressed through stages 1 -> 5 -> 2 -> 5 -> 4.
This confirms the originally blocked Continue/registration flow over the real
client/server bridge. Existing-account login and character spawning still need
their own in-game verification.

## Failure handling and validation

CEF waits for the page's `lsrp:ready` before sending screen data. Browser creation
failure or no page-ready signal within 15 seconds switches back to native UI.
The timeout carries a connection generation so it cannot affect a reused slot.
Failed CEF handshake keeps native UI. Authentication requests are serialized;
Pawn validates input, owns password verification and checks login/character
state before slot/play actions. Passwords are not logged or persisted by the UI.

Validation performed:

- Main gamemode compiled with bundled open.mp Pawn compiler: no errors; eight
  existing warnings (YSI compiler option, indentation and unused functions).
- `node tools/test_cef_ui.cjs`: event wiring, duplicate submissions, password
  clearing, safe character text rendering, slot selection, classic fallback,
  and all six Pawn event signatures including the implicit browserid argument.
- Isolated runtime smoke test with the repository's open.mp 1.5.8.3079 binary:
  Cef.dll loaded, CEF UDP listener started, lsrp resource packaged, event
  registration and gamemode initialization succeeded, clean timed shutdown.
  This test did not connect to or modify the gameplay database.

Not yet verified: visual layout/input inside ReSA, client handshake, real login
against MySQL, and resource downloads over a remote network.

The server log at 21:57 on 11 November 2026 confirms a successful database
connection; the earlier MySQL error 1045 entries are historical.
