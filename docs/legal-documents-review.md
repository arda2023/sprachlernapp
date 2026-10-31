# Legal document draft review record

**Status: unapproved draft. Do not publish or enable paid public purchases until the operator has reviewed the texts and confirmed the actual legal and vendor setup.** The app's `LEGAL_DOCUMENTS_APPROVED` build flag defaults to `false`.

The in-app copy is in `lib/screens/legal/legal_document.dart`; the offline-readable screen is `lib/screens/legal/legal_document_screen.dart`. Standalone static HTML copies for future hosting are in `assets/legal/`. No external site was published.

## Repository evidence used

- Product rules: `PRODUCT.md` and `docs/haiku-runtime-translations.md`.
- Auth and account identity: `lib/data/content/content_auth_repository.dart`, `lib/data/auth/native_account_identity.dart`, and `lib/presentation/providers/account_provider.dart`.
- Account deletion and platform follow-up: `lib/widgets/account_tile.dart`, `lib/data/auth/account_deletion_gateway.dart`, `supabase/functions/_shared/account_deletion.ts`, `supabase/functions/delete-account/index.ts`, and `supabase/functions/_shared/account_deletion_test.ts`.
- Local learning storage: `lib/data/user/user_database.dart` and `lib/data/user/drift_user_repository.dart`.
- Local translation cache TTL/deletion: `lib/data/translation_cache.dart`.
- Runtime translation route and client payload: `lib/data/runtime_translation_client.dart`, `lib/data/translation_request.dart`, `supabase/functions/translate-sentence/index.ts`, and `supabase/functions/lookup-word/index.ts`.
- Private learning-card consent, payload and private result cache: `lib/widgets/personal_learning_button.dart`, `lib/data/personal_learning_client.dart`, `supabase/functions/create-learning-card/index.ts`, and `supabase/functions/_shared/personal_learning.ts`.
- Server translation cache TTL and quota: `supabase/migrations/20261031000002_translation_subscription_budget.sql`.
- Billing identity and purchase details: `lib/data/billing/adapty_billing_gateway.dart`, `lib/data/billing/purchase_gateway.dart`, `lib/presentation/providers/purchase_provider.dart`, and `supabase/functions/billing-sync/index.ts`.
- Font and speech integration: `lib/theme/app_theme.dart` and `lib/presentation/audio/device_speech_playback.dart`.

The text therefore says learning state is local and not account-synced; display translation responses have a 30-day local and server cache; private exercise-card responses are generated only after a separate consent and may be cached for 30 days; five translations are available without premium and premium includes 500 per monthly quota period, including annual subscribers; product pricing is currently configured as €9.99/month and €49.99/year with no trial; and subscription cancellation is separate from account deletion. It describes in-app account deletion, recent authentication, retention of local learning data, and manual Sign in with Apple revocation under Apple's TN3194. It does not claim an EU-only AI route or assert that any DPA/SCC has been executed.

## Primary legal and provider sources consulted

- GDPR, especially Articles 6, 13, 15–22, 28 and 44 onward: [EUR-Lex, Regulation (EU) 2016/679](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32016R0679).
- German online-provider notice requirements: [DDG § 5, Gesetze im Internet](https://www.gesetze-im-internet.de/ddg/__5.html).
- Consumer withdrawal rules and digital products: [BGB §§ 312g, 355, 356, Gesetze im Internet](https://www.gesetze-im-internet.de/bgb/BJNR001950896.html); [EGBGB Art. 246a § 1](https://www.gesetze-im-internet.de/bgbeg/art_246a__1.html).
- Digital-product conformity and consumer remedies: [BGB §§ 327–327u, Gesetze im Internet](https://www.gesetze-im-internet.de/bgb/BJNR001950896.html).
- Auto-renewal and account cancellation controls: [Apple, Auto-renewable Subscriptions](https://developer.apple.com/app-store/subscriptions/); [Apple StoreKit, Handling Subscription Billing](https://developer.apple.com/documentation/StoreKit/handling-subscriptions-billing).
- In-app deletion and manual Sign in with Apple token revocation: [Apple TN3194](https://developer.apple.com/documentation/technotes/tn3194-handling-account-deletions-and-revoking-tokens-for-sign-in-with-apple); [Apple, Offering account deletion in your app](https://developer.apple.com/support/offering-account-deletion-in-your-app/).
- Anthropic API retention and commercial-product use: [Anthropic Privacy Center, data retention](https://privacy.anthropic.com/en/articles/7996866-how-long-do-you-store-my-organization-s-data); [Anthropic Privacy Center, model training](https://privacy.anthropic.com/en/articles/7996885-how-do-you-use-personal-data-in-model-training). The app text avoids a retention guarantee based on vendor policy.
- Supabase region and data-residency limitations: [Supabase, Data Residency and Transfers FAQ](https://supabase.com/legal/privacy-resources/data-residency-and-transfers-faq); [Supabase, Regions](https://supabase.com/docs/guides/platform/regions); [Supabase DPA](https://supabase.com/legal/customer-resources/data-processing-addendum). These sources do not establish which region or agreement this app project actually uses.
- Adapty's profile identifiers and user data: [Adapty, How Profiles Work](https://adapty.io/docs/how-profiles-work); [Adapty DPA](https://adapty.io/data-processing-agreement/). The repository disables advertising identifier, IP collection and attribution options, but does not establish executed legal terms.
- Supervisory authority for non-public controllers established in Schleswig-Holstein: [ULD, complaint process and jurisdiction](https://www.datenschutzzentrum.de/meldungen/); [ULD contact](https://www.datenschutzzentrum.de/datenschutzerklaerung/).

## Decisions still required before public release

1. Confirm the actual legal seller/contract party shown for App Store purchases and whether any additional platform or storefront is enabled.
2. Verify the live App Store product prices, tax treatment, renewal periods, cancellation path, and final purchase disclosures. The in-app amounts are review inputs; the Store's localized checkout price controls.
3. Have counsel or a qualified reviewer prepare the final withdrawal notice and assess whether a withdrawal form or online withdrawal function is required for this exact purchase journey.
4. Verify the active Supabase project region, service configuration, log retention, backup retention, subprocessors, DPA status, and any transfer mechanism. Do not infer those from the Flutter code.
5. Verify the executed Anthropic commercial terms, data-processing terms, account configuration, current retention policy and transfer mechanism; confirm whether the 30-day standard retention applies to this account.
6. Verify the executed Adapty agreement/DPA, exact SDK profile fields and retention, and Apple/Google data flows used by the shipped build.
7. Decide whether a data protection officer is legally required and, if applicable, add their contact details.
8. Confirm whether tax or trade-registration identifiers or additional DDG information must appear for the operator's actual activity.
9. Run the deletion flow end-to-end using a controlled test account. Source inspection and the fake-backend Deno tests cover in-app initiation, typed confirmation, authentication age (five-minute window), Adapty-profile/auth-user deletion, and the Apple manual-revocation response. No existing user account was deleted during this work. Verify the live Supabase function secrets and deletion behavior before release.
10. Review the Google Fonts fetch behavior and platform text-to-speech behavior on shipping devices, then confirm the disclosures and legal basis are appropriate.

## Review boundary

This is drafting and technical fact-finding, not a legal opinion, completed GDPR assessment, vendor-contract verification, or approval to publish. The legal notice, terms and imprint remain visibly labeled as drafts. `LEGAL_DOCUMENTS_APPROVED` must remain unset/false until the operator completes the review above. Sandbox purchase support is still limited by the server-side tester allowlist (`ADAPTY_SANDBOX_TESTER_IDS`) as well as the debug-only client flag.
