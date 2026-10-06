# App components

The registry of shared UI components: reusable, feature-agnostic widgets in `lib/core/components/`. Screens are built from these. Nobody writes the same button, field or dialog twice.

`dart run tool/check_architecture.dart` compares this file with the code. CI fails when a public type in `lib/core/components/` has no row in the Registry, and when a Registry row names a type that does not exist.

## 1. How to use this file

Before you write any widget:

1. **Search the Registry (§3).** If a component exists, use it as it is. Do not rebuild it, copy it, or wrap it in a near-duplicate.
2. **Almost fits?** Add an optional parameter whose default keeps today's behavior, and update the row. A change that breaks existing callers needs a maintainer.
3. **Nothing fits, and the piece is generic** (it would make sense on another screen or in another feature)? Create the component **first**, in `lib/core/components/<category>/app_<name>.dart`. Then use it, and add its row to the Registry in the same change. If §4 reserves a name for it, use exactly that name and path.
4. **Only meaningful inside one role folder** (it shows that folder's entity, e.g. `ClientProjectTile`)? It is not a component. Put it in that folder's `presentation/widgets/` and do not register it.

## 2. Rules for components

- **Name:** `App<Name>` in `app_<name>.dart`, one component per file. Its small helper types (e.g. an `AppButtonVariant` enum) may live in the same file and go in the same Registry row.
- **Categories (folders):**
  - `buttons/`;
  - `inputs/`;
  - `feedback/`: loading, error, empty, dialogs, snackbars;
  - `layout/`: scaffold, sections;
  - `display/`: cards, avatars, badges, amounts, images.
- **Data in, events out.** Prefer `StatelessWidget`. Take data through constructor parameters and report actions through callbacks (`VoidCallback`, `ValueChanged<T>`).
- **No logic and no feature knowledge.** A component never reads a bloc, calls a use case, uses `getIt` or touches Supabase. It may use `lib/core/theme/`, `lib/core/enums/`, `lib/core/utils/` and `lib/core/localization/`.
- **Text arrives translated** as a parameter. The only keys a component translates itself are in the `common` group (e.g. `common.retry`).
- **Look comes from the theme** (`Theme.of(context)`, `lib/core/theme/`): no hard-coded colors, text styles or sizes.
- **RTL-safe:** `EdgeInsetsDirectional`, `AlignmentDirectional`, `TextAlign.start` / `end` (`APP_ARCHITECTURE.md` §14).
- **Accessible:** tap targets of at least 48×48, and a `tooltip` or `semanticLabel` on icon-only buttons.
- **Third-party UI packages** (e.g. `pinput`) are used only inside a component.
- **Tested:** each component gets a widget test in `test/core/components/<category>/app_<name>_test.dart`.

A Registry row looks like this. Put the type names in backticks in the first column; the checker reads them from there.

```
| `AppButton`, `AppButtonVariant` | `buttons/app_button.dart` | Every button: primary, secondary, text; spinner while loading | `label`, `onPressed`, `variant`, `isLoading` | 2026-10-06 |
```

## 3. Registry

| Component | File | Use it for | Key parameters | Added |
|-----------|------|------------|----------------|-------|
| _None yet. The first components arrive with the foundation._ | | | | |

When you add the first component, replace the "None yet" row.

## 4. Reserved names

Almost every screen needs these components. None of them exists yet. When you need one, build it **with exactly this name and path**, then add its row to the Registry. Because everyone uses the same names, two people never build two different buttons. If they work in parallel, Git reports a conflict instead of letting a duplicate slip in.

| Need | Component | File (in `lib/core/components/`) |
|------|-----------|-----------------------------------|
| Any button: primary, secondary, text, with loading state | `AppButton` | `buttons/app_button.dart` |
| Icon-only button | `AppIconButton` | `buttons/app_icon_button.dart` |
| Text input with label, hint, error and validation | `AppTextField` | `inputs/app_text_field.dart` |
| Phone number input (Saudi format) | `AppPhoneField` | `inputs/app_phone_field.dart` |
| OTP / PIN input (wraps `pinput`) | `AppOtpInput` | `inputs/app_otp_input.dart` |
| Dropdown or picker | `AppDropdown` | `inputs/app_dropdown.dart` |
| Page frame with an app bar | `AppScaffold` | `layout/app_scaffold.dart` |
| Section title with an optional action | `AppSectionHeader` | `layout/app_section_header.dart` |
| Loading indicator | `AppLoadingIndicator` | `feedback/app_loading_indicator.dart` |
| Error message with retry | `AppErrorView` | `feedback/app_error_view.dart` |
| Empty-list message | `AppEmptyView` | `feedback/app_empty_view.dart` |
| Snackbar / toast | `AppSnackBar` | `feedback/app_snack_bar.dart` |
| Confirmation dialog | `AppConfirmDialog` | `feedback/app_confirm_dialog.dart` |
| Card container | `AppCard` | `display/app_card.dart` |
| User or business avatar (takes an image URL) | `AppAvatar` | `display/app_avatar.dart` |
| Status chip for project, offer, task, payment and order statuses | `AppStatusBadge` | `display/app_status_badge.dart` |
| An amount in SAR (formats `Money`) | `AppMoneyText` | `display/app_money_text.dart` |
| Network image with placeholder and error state | `AppNetworkImage` | `display/app_network_image.dart` |
| Star rating, to show or to pick | `AppRatingStars` | `display/app_rating_stars.dart` |
