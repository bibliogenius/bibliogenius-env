# Releasing BiblioGenius

Procédure de release de bout en bout pour l'app (iOS / macOS / Android).
Le site web et le hub ont des cadences de déploiement indépendantes (voir bas de page).

## Prérequis (configuration unique)

fastlane doit être configuré — voir `bibliogenius-app/fastlane/README.md` :
Gemfile, `fastlane/.env`, entrées Keychain (`bg-*`), certificats Apple, profiles.

Important : lancer fastlane **sans** `bundle exec` (ça pollue l'environnement et
casse CocoaPods — détail dans l'en-tête du Fastfile). Les cibles `make ship*`
s'en chargent déjà correctement.

## 1. Bumper la version

```
make release V=x.y.z
```

- Met à jour la version dans `bibliogenius/Cargo.toml`, `bibliogenius-app/pubspec.yaml`
  (build number auto-incrémenté) et `README.md`.
- Met à jour `Cargo.lock`.
- Commit + push sur `bibliogenius` et `bibliogenius-app`.
- Pose le tag `vx.y.z` sur `bibliogenius` et `bibliogenius-app`.

Le hub et le site web ne sont pas touchés (cadences indépendantes).

## 2. Builder et uploader les apps

```
make ship
```

Build + signe + upload les 3 plateformes, puis affiche un résumé :

- iOS → TestFlight
- macOS → TestFlight
- Android → Play Console, track `internal`, statut `draft`

Une seule plateforme : `make ship-ios`, `make ship-mac`, `make ship-android`.

`make ship` continue même si une plateforme échoue (résumé final), et sort en
erreur si au moins une a échoué. Compter ~30 min pour les 3 en série.

Note macOS : `make ship-mac` rebuild le backend Rust (~3-5 min). Pour réutiliser
un build Rust existant : `cd bibliogenius-app && fastlane mac upload skip_rust:true`.

## 3. Publier (étapes manuelles dans les consoles)

Les lanes déposent les builds dans les pipelines de staging. Le passage en
production se décide à la main, quand tu es prêt :

- **App Store Connect** (iOS + macOS) : créer la version, sélectionner le build
  uploadé, remplir les notes, *Submit for Review*.
- **Play Console** (Android) : promouvoir le build du track `internal` vers
  `closed` / `open` / `production`.

## Site web (cadence indépendante)

```
cd bibliogenius-website && make deploy
```

Build + rsync vers le VPS. La version affichée sur le site provient de
`bibliogenius-website/_build/version.txt` — à mettre à jour quand tu veux que le
site reflète une nouvelle version (séparé de `make release`).

## Hub (cadence indépendante)

`bibliogenius-hub` se déploie selon son propre cycle. Le couplage avec l'app est
au niveau du **protocole**, pas du numéro de version — non concerné par `make release`.

## Resynchroniser tous les fichiers de version

Cas rare : `make version V=x.y.z` applique le bump de version aux 5 emplacements
(Rust, Flutter, hub `composer.json`, site `version.txt`, README) sans rien
committer. Utile pour un réalignement ponctuel.
