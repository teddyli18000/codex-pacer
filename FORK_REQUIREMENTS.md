# Fork requirements

This is the personal build of Codex Pacer maintained in `teddyli18000/codex-pacer`.

1. **Never update automatically.** No background checks, downloads, installs, relaunches, or upgrades from the upstream channel. Both macOS and Windows must keep their production updaters disabled, regardless of previously saved update preferences. An update is initiated only by the repository owner requesting that it be prepared.
2. **Keep the display time zone selector.** General settings show one option to follow the system time zone (the default) or choose an IANA time zone. It changes only the displayed dates and times, not the OS time zone, actual quota reset instants, quota calculations, or countdowns.
3. **Upstream sync is manual.** When asked to update, integrate the latest upstream code while preserving items 1 and 2, run affected cross-platform tests, build the fork's own artifacts, and publish the binaries to this fork's GitHub Releases. Never silently replace this fork with the upstream app or overwrite the owner's settings.
4. **Manual installation only.** Fork releases do not ship Sparkle appcast feeds or enable in-app updates. Mac builds without the upstream owner's Apple signing credentials must be marked ad-hoc signed / not notarized; Windows installers must be labeled as unsigned when they lack Authenticode signatures.

These requirements take precedence over upstream documentation and release procedures for this fork.
