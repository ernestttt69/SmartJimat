# Seller and account integration

Source: `https://github.com/ernestttt69/SmartJimat/tree/seller`, commit `b422811`.
The seller/account modules were imported into the existing `search-shop` working tree.
This is a source integration, not a Git history merge: the seller branch deletes the
customer module, while this workspace contains uncommitted customer/AI changes that
must be retained. Existing platform configuration and package name are retained.

## Account flow

`MyApp -> AuthGate -> Welcome / Customer MainNavigationScreen / SellerHomeScreen`.
Supabase restores the session on startup. The gate loads the user's persisted cart
and reads the role from the existing `public.user` profile before opening Home.
Missing profiles, unknown roles and failed cart loads show a retry/logout screen.
Auth changes discard the previous account's entire navigation stack. Token refresh
and password reauthentication for the same user leave navigation and cart intact.
Customer profiles reuse account editing, photo upload and password changes without
requiring a seller premise. Customer and seller registration save profile fields
in Auth signup metadata. On authenticated session startup, SessionService reads
the `user` row and inserts it from that metadata if missing. This also repairs
previously registered accounts after email confirmation and login. Existing rows
are never overwritten. No signup trigger is assumed to exist.

With email confirmation enabled and no database trigger, the `user` row is created
on the first authenticated app session, not before the email is verified. The
authenticated user needs SELECT/INSERT access to their own profile under RLS;
seller accounts also need read access to their registered `lookup_premise` row.
No database policies are changed by this code. Missing metadata or denied writes
show an actionable error rather than admitting the account into Home.

Android handles the seller module's existing `com.example.assignment://login-callback/`
URL for signup confirmation and password recovery. That URL must be allowed in
Supabase Auth redirect settings. Existing seller tables, RLS policies and storage
buckets remain prerequisites; no remote schema or policy was changed.

## Cart durability

Android SQLite database: `smartjimat_carts.db`, table `cart_items`, primary key
`(user_id, item_code)`. Each saved item contains product details and quantity.
Changes are serialized and committed transactionally before the UI reports success.
Failed saves retain the old cart; failed restores block editing until retry succeeds.
Logout clears visible memory only. Cart data remains for the next login to the same
account. Late AI responses are rejected if the initiating account has changed.

Persistence is on this installation/device. It is not cross-device cloud sync;
uninstalling the app or clearing app data removes the local database.

## Verification

- `flutter test`: 12 tests covering account roles, invalid credentials, missing
  profiles, restored sessions, cart persistence/isolation, rapid edits, failed reads
  and writes, deletion, and late AI responses.
- `flutter test integration_test/account_cart_test.dart -d emulator-5554`: 2 passing
  Android tests using actual SQLite and mocked HTTP account responses. Covers login,
  Home, add-to-cart UI, rebuilding the session gate, logout/login, seller isolation,
  and closing/reopening the database.
- `flutter analyze --no-fatal-infos --no-pub`: passes with informational lints;
  no errors or warnings.
- Build: `flutter build apk --debug`.

Integration tests use fake accounts and do not send requests to the live backend.
Real account credentials are never stored in test files or source code.

## Live Android acceptance (2026-09-10)

Using the user-provided customer account on emulator-5554 and the real Supabase
backend, verified login into customer Home, live product search, and adding
`BERAS TQR SABAH CAP TKC 5%` (10 kg), then increasing its quantity to 2.
After `adb shell am force-stop com.example.mobile_assignment` and relaunch, the
session automatically restored Home and the cart still showed that product at 2.
Profile logout returned to Welcome. Logging into the same account again restored
the same item and quantity. The emulator is left on the verified shopping list.
Screenshot: `build/cart-after-relogin.png`.
Final APK: `build/app/outputs/flutter-apk/app-debug.apk`.
