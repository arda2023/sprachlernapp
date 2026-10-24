# Device translation (internal Flutter plugin)

Local-only sentence display translation, no AI HTTP client and no learner storage.
Channel `device_translation`: `status({lang})`, `prepare({lang})`,
`translate({lang,text})`, `cancel()`; languages `en`, `pt-BR`, target always `de`.

- iOS 18+: Apple Translation, runtime language-pair availability. SwiftUI host owns
  the session. Preparing models is explicit; translate refuses missing models.
- Android API 24+ in this plugin: ML Kit 17.0.3, Wi-Fi model download, Portuguese
  without guaranteed regional specialization. `de` and optionally `pt` models.
- Cancel ends this request and rejects late results. System model downloads may
  continue; neither platform promises transactional download rollback.
- Platform errors contain codes only, never input text or full native exceptions.
- Results are ephemeral display strings, not Anthropic responses or learning data.

Google Translate powers Android device translations. Official usage/branding:
https://developers.google.com/ml-kit/language/translation/translation-terms
https://cloud.google.com/translate
The host displays the supplied official Google attribution badge beside results.
Full implementation report: ../../docs/offline-translation-package-2b.md.
