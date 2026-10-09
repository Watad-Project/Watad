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
| `AppButton`, `AppButtonVariant` | `buttons/app_button.dart` | Every button: primary (orange), secondary (outlined), dark (ink), link; full width except link; spinner while loading | `label`, `onPressed`, `variant`, `isLoading`, `icon`, `trailingIcon` | 2026-10-09 |
| `AppIconButton`, `AppIconButtonVariant` | `buttons/app_icon_button.dart` | Icon-only button: plain (back arrow, toolbar) or filled orange square (add to cart); 48×48 tap target | `icon`, `tooltip`, `onPressed`, `variant` | 2026-10-09 |
| `AppFieldLabel` | `inputs/app_field_label.dart` | The label above a field; required fields get a red "Required" | `label`, `isRequired` | 2026-10-09 |
| `AppTextField` | `inputs/app_text_field.dart` | Text input with label, hint, helper, error and `Form` validation; mono left-to-right mode for CR numbers and IBANs | `label`, `isRequired`, `controller`, `hint`, `helperText`, `errorText`, `validator`, `isMonospace`, `maxLines` | 2026-10-09 |
| `AppPhoneField` | `inputs/app_phone_field.dart` | Saudi mobile number: fixed +966, digits grouped as 5x xxx xxxx, Arabic-Indic digits accepted; `AppPhoneField.fullNumber()` gives +9665xxxxxxxx | `label`, `controller`, `hint`, `errorText`, `validator` | 2026-10-09 |
| `AppOtpInput` | `inputs/app_otp_input.dart` | OTP / PIN input with auto-advance and paste support; wraps `pinput` | `length`, `controller`, `onCompleted`, `onChanged`, `errorText` | 2026-10-10 |
| `AppDropdown`, `AppDropdownOption` | `inputs/app_dropdown.dart` | Select field whose list opens under it; options with a toned subtitle, and a tag badge shown next to the chosen value | `options`, `value`, `onChanged`, `label`, `hint`, `errorText` | 2026-10-09 |
| `AppQuantityStepper` | `inputs/app_quantity_stepper.dart` | A number with − and + buttons (market, cart) | `value`, `onChanged`, `min`, `max`, `step`, `valueLabel`; tooltips default to "Decrease" / "Increase" | 2026-10-09 |
| `AppSwitch` | `inputs/app_switch.dart` | On/off switch, alone or as a full-width settings row with a label | `value`, `onChanged`, `label`, `semanticLabel` | 2026-10-09 |
| `AppCheckbox` | `inputs/app_checkbox.dart` | Checkbox with a tappable label (accepting the terms) | `value`, `onChanged`, `label` | 2026-10-09 |
| `AppRadioRow`, `AppRadioRowAccent` | `inputs/app_radio_row.dart` | One bordered choice in a list (payment method, address, task, rejection reason); orange or ink when selected | `title`, `subtitle`, `subtitleTone`, `selected`, `onTap`, `accent` | 2026-10-09 |
| `AppFilterChips` | `inputs/app_filter_chips.dart` | Scrollable row of round filter chips, one selected (market, work, projects) | `labels`, `selectedIndex`, `onSelected` | 2026-10-09 |
| `AppSegmentedTabs` | `inputs/app_segmented_tabs.dart` | Two or three equal boxes switching a list between views; the selected one is ink | `labels`, `selectedIndex`, `onChanged` | 2026-10-09 |
| `AppUploadZone` | `inputs/app_upload_zone.dart` | Dashed box to pick a document (license, title deed, receipt); reports the tap only | `onTap`, `label` (default "Image or PDF"), `icon` | 2026-10-09 |
| `AppCameraTile` | `inputs/app_camera_tile.dart` | Dark square that opens the camera, before the photo thumbnails; reports the tap only | `onTap`, `label` (default "Camera"), `size` | 2026-10-09 |
| `AppRejectReasonForm` | `inputs/app_reject_reason_form.dart` | Reject something: pick a reason, write the required details, send (task update, receipt, refund, document) | `reasons`, `onSubmit`, `isSubmitting`; `title`, `detailsHint`, `submitLabel` default to "Reason for rejecting", "Write the reason...", "Send rejection" | 2026-10-09 |
| `AppLogo` | `display/app_logo.dart` | The Watad logo, for light or dark surfaces | `height`, `onDark`, `semanticLabel` | 2026-10-09 |
| `AppCard` | `display/app_card.dart` | White outlined card, tappable, clips a photo at the top | `child`, `onTap`, `padding`, `color` | 2026-10-09 |
| `AppImagePlaceholder` | `display/app_image_placeholder.dart` | The striped box where a photo is missing or loading | `label` | 2026-10-09 |
| `AppNetworkImage` | `display/app_network_image.dart` | Network image with the striped placeholder while loading, on error and without a URL | `url`, `width`, `height`, `fit`, `borderRadius`, `semanticLabel` | 2026-10-09 |
| `AppPhotoTile` | `display/app_photo_tile.dart` | Square photo thumbnail, numbered placeholder until there is a photo (task evidence, receipts) | `image`, `placeholderLabel`, `onTap`, `size` | 2026-10-09 |
| `AppStatusBadge` | `display/app_status_badge.dart` | Round status label in a tone (orange waiting, green done, red rejected, gray neutral); white on photos | `label`, `tone`, `onImage` | 2026-10-09 |
| `AppIconTag` | `display/app_icon_tag.dart` | Tinted tag with a square mark (✓ ! ?); trust marks with the ledger hash; timeline notes | `label`, `icon`, `tone`, `detail` | 2026-10-09 |
| `AppVerifiedName` | `display/app_verified_name.dart` | A business name with the green verified check | `name`, `style`, `semanticLabel` | 2026-10-09 |
| `AppProjectCard` | `display/app_project_card.dart` | A project in a list: photo and status, title, contractor, task progress, dates, amount (client and contractor) | `title`, `subtitle`, `statusLabel`, `statusTone`, `progress`, `progressLabel`, `percentLabel`, `dateLabel`, `amountLabel`, `imageUrl`, `onTap` | 2026-10-09 |
| `AppTimeline`, `AppTimelineItem`, `AppTimelineState` | `display/app_timeline.dart` | Vertical list of steps joined by a line (project tasks): done, current, upcoming | `items` (`title`, `state`, `subtitle`, `trailing`, `tag`) | 2026-10-09 |
| `AppMarketTile` | `display/app_market_tile.dart` | A product in the market grid: photo and condition, name, seller, price per unit, add button | `title`, `seller`, `priceLabel`, `unitLabel`, `conditionLabel`, `conditionTone`, `imageUrl`, `onTap`, `onAdd` | 2026-10-09 |
| `AppCartGroup` | `display/app_cart_group.dart` | One seller's cart lines in an outlined box with a header and a note | `title`, `note`, `children` | 2026-10-09 |
| `AppCartLine` | `display/app_cart_line.dart` | A product line of a cart, order or refund: thumbnail, name, quantity, price | `title`, `subtitle`, `priceLabel`, `imageUrl`, `trailing`, `onTap` | 2026-10-09 |
| `AppSummaryRows`, `AppSummaryRow` | `display/app_summary_rows.dart` | Bill lines (subtotal, VAT) and the bold total (cart, checkout, refunds, stage payments) | `rows`, `total` | 2026-10-09 |
| `AppAddressCard` | `display/app_address_card.dart` | A saved address with a "default" badge and edit/delete actions | `title`, `address`, `isDefault`, `onEdit`, `onDelete`; labels default to "Edit on map" / "Delete" | 2026-10-09 |
| `AppBusinessMiniCard` | `display/app_business_mini_card.dart` | Small business card for horizontal lists: photo, verified name, rating, projects | `name`, `ratingLabel`, `projectsLabel`, `isVerified`, `imageUrl`, `onTap` | 2026-10-09 |
| `AppKeyValueList`, `AppKeyValueRow` | `display/app_key_value_list.dart` | Label-value lines in a quiet panel, with an optional copy action (bank transfer, receipt, order details) | `rows` (`label`, `value`, `isMonospace`, `isCopyable`, `copyValue`), `onCopied` | 2026-10-09 |
| `AppStateStepper` | `display/app_state_stepper.dart` | The states something goes through, in a row, reached ones in orange (task: proposed → paid) | `labels`, `currentIndex` | 2026-10-09 |
| `AppStatusCard` | `feedback/app_status_card.dart` | Where a submission stands: pending, rejected with reason and retry, accepted (receipts, task updates, refunds, verification) | `tone`, `title`, `subtitle`, `reasonTitle`, `reasonText`, `action` | 2026-10-09 |
| `AppSnackBar`, `AppSnackBarContext` | `feedback/app_snack_bar.dart` | Short messages at the bottom: `context.showSnackBar()`, `showSuccessSnackBar()`, `showErrorSnackBar()` (6 s; `onRetry` adds "Try again"), `hideSnackBar()`. A new one replaces the one on screen. The doc comment says how to write the message | `message`, `tone`, `actionLabel`, `onAction`, `duration`, `onRetry` | 2026-10-09 |
| `AppNotFoundView` | `feedback/app_not_found_view.dart` | The router's page for an address that doesn't exist: "We couldn't find this page" and a button back to the start | `onBackToStart` | 2026-10-09 |
| `AppActionBar` | `layout/app_action_bar.dart` | The bottom bar of actions; with two, the primary takes 2/3 of the width | `primary`, `secondary` | 2026-10-09 |
| `AppTopBar` | `layout/app_top_bar.dart` | The top bar of sub-screens: back arrow (flips in RTL) and a quiet title | `title`, `onBack`, `actions` | 2026-10-09 |
| `AppStepProgress` | `layout/app_step_progress.dart` | "Step 2 of 4" with one bar per step (multi-step flows) | `current`, `total`, `label` (default "Step 2 of 4") | 2026-10-09 |
| `AppTabBar` | `layout/app_tab_bar.dart` | Underlined tabs of equal width (business profile) | `labels`, `controller`, `onTap` | 2026-10-09 |
| `AppBottomNav`, `AppBottomNavItem` | `layout/app_bottom_nav.dart` | The main tabs at the bottom; the shell passes the tabs of the signed-in role | `items`, `currentIndex`, `onTap` | 2026-10-09 |

Components translate their own generic words (Required, Copy, Try again, Camera, Delete…) from the `common` group (`assets/translations/common.ar.json` and `common.en.json`), with `context.tr()`. Screens pass only the text that is specific to them. Where a label has a default, passing your own text replaces it.

Statuses are shown in four tones, `AppTone` in `lib/core/theme/app_tone.dart` (attention, success, danger, neutral). Components that show a status take a tone instead of colors.

## 4. Reserved names

Almost every screen needs these components. Some exist already (see the Registry); when you need one that does not, build it **with exactly this name and path**, then add its row to the Registry. Because everyone uses the same names, two people never build two different buttons. If they work in parallel, Git reports a conflict instead of letting a duplicate slip in.

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
