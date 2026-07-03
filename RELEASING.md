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

Chaque cible `ship*` exécute d'abord `make check-migration` : rejeu de la chaîne
complète de migrations DB sur une **copie** d'une vraie bibliothèque à l'ancien
schéma (`bibliogenius.db` à la racine par défaut, surchargeable via
`REAL_DB=/chemin/vers/base.db`). Une migration qui passe sur une base de dev
propre peut briquer un vrai device (incident 1.1.0-beta : `foreign_key_check`
avortait sur les lignes sentinelles `peer_id = 0` du cache annuaire) — ce
garde-fou bloque l'upload avant. Le fichier source n'est jamais modifié.

Note macOS : `make ship-mac` rebuild le backend Rust (~3-5 min). Pour réutiliser
un build Rust existant : `cd bibliogenius-app && fastlane mac upload skip_rust:true`.

## 3. Publier (étapes manuelles dans les consoles)

Les lanes déposent les builds dans les pipelines de staging. Le passage en
production se décide à la main, quand tu es prêt :

- **App Store Connect** (iOS + macOS) : créer la version, sélectionner le build
  uploadé, remplir les notes, *Submit for Review*.
- **Play Console** (Android) : promouvoir le build du track `internal` vers
  `closed` / `open` / `production`.

## Linux desktop (cadence indépendante, auto-hébergé)

Linux n'a pas de store : pas de fastlane, pas de CI. Le build se fait depuis le
Mac via Docker (émulation `linux/amd64` qemu, lent mais reproductible) et la
distribution est auto-hébergée sur le VPS, derrière une URL stable.

```
make build-linux    # produit dist/BiblioGenius-Linux-x64.AppImage (+ .sha256)
make ship-linux      # rsync (SANS --delete) vers hub-vps:/var/www/bibliogenius.org/downloads/
```

- `make build-linux` construit l'image toolchain `docker/Dockerfile.linux-build`
  (Ubuntu 22.04 LTS, choisie pour la compat glibc), monte les deux repos
  (`bibliogenius` Rust + `bibliogenius-app` Flutter) en siblings, compile le
  backend Rust (`x86_64-unknown-linux-gnu`), lance `flutter build linux
  --release`, injecte le binaire dans `bundle/backend/`, puis emballe le bundle
  dans une **AppImage** via `appimagetool` (un AppDir + AppRun + .desktop +
  icône) et écrit le `.sha256` à côté. Le premier run est long (qemu +
  `flutter precache`) ; l'image est ensuite en cache.
- `make ship-linux` dépose l'AppImage et son `.sha256` via rsync **sans**
  `--delete` (réutilise ton accès SSH `hub-vps`, aucun secret en CI). Crée
  `downloads/` côté serveur au besoin.

Modèle de dépendances : l'AppImage **ne bundle pas** GTK/X11 ; elle s'appuie sur
les libs système de l'hôte (d'où le build sur Ubuntu 22.04 pour la compat glibc).
On utilise donc `appimagetool` sur un AppDir fait main, pas `linuxdeploy` (qui
embarquerait les libs système et changerait l'empreinte).

Politique de conservation : un seul fichier `BiblioGenius-Linux-x64.AppImage`,
écrasé à chaque release. URL stable, pas de rotation ni d'historique côté serveur.
`downloads/` est dans le `.deployignore` du site, donc le `make deploy` du site
(qui utilise `--delete`) n'efface jamais le binaire.

URLs publiques :
- https://bibliogenius.org/downloads/BiblioGenius-Linux-x64.AppImage
- https://bibliogenius.org/downloads/BiblioGenius-Linux-x64.AppImage.sha256

Liée depuis l'accueil et la page Contribuer du site (`bibliogenius-website/`,
liens FR/EN/ES/DE + templates).

Pour valider l'AppImage sans machine Linux, voir `docker/README.md`
(service `linux-appimage` + `verify_linux.sh`).

Windows reste non couvert (cross-compilation impossible depuis le Mac) — voir la
note dans le Makefile et la mémoire projet dédiée.

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
