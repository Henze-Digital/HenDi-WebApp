# HWH-WebApp (Chaining of WeGA-WebApp)

This repo contains WeGA-WebApp specifics for the Henze Digital Project. The build process updates the source code of the [WeGA-WebApp](https://github.com/Henze-Digital/WeGA-WebApp) and builds the HenDi-WebApp afterwards.

## Licence
[![](https://img.shields.io/badge/license-BSD2-green.svg)](https://github.com/Edirom/WeGA-WebApp/blob/develop/LICENSE)
[![](https://img.shields.io/badge/license-CC--BY--4.0-green.svg)](https://github.com/Edirom/WeGA-WebApp/blob/develop/LICENSE)

## On Gitlab (UPB internal)
[![Latest Release](https://git.uni-paderborn.de/vife/henze-digital/hwh-webapp/-/badges/release.svg)](https://git.uni-paderborn.de/vife/henze-digital/hwh-webapp/-/releases)

[![pipeline status](https://git.uni-paderborn.de/vife/henze-digital/hwh-webapp/badges/develop/pipeline.svg)](https://git.uni-paderborn.de/vife/henze-digital/hwh-webapp/-/commits/develop) on `develop`

[![pipeline status](https://git.uni-paderborn.de/vife/henze-digital/hwh-webapp/badges/stable/pipeline.svg)](https://git.uni-paderborn.de/vife/henze-digital/hwh-webapp/-/commits/stable)
on `stable`

## On Github (public)
[![GitHub release](https://img.shields.io/github/release/Henze-Digital/HenDi-WebApp.svg)](https://github.com/Henze-Digital/HenDi-WebApp/releases)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.13137427.svg)](https://doi.org/10.5281/zenodo.13137427)

## Release workfow

1. Do the release actions for HenDi-ODD first!
1. Continue here.

### release workflow on gitlab (UPB internal)
- check issues and milestone
- close milestone
- update submodules
- create a release branch
- update file build.properties
- update README.md (badge, links)
- check out and build the app
- test the app
- if everything works as expected: set tag `v\d\.\d\.\d`
- merge into main
- merge main into develop
- create release based on the tag
- bump version number

### release workflow on github (public)
- go to the mirrored repo on [Github](https://github.com/Henze-Digital/HenDi-WebApp)
-  [create release](https://github.com/Henze-Digital/HenDi-WebApp/releases/new) based on the latest tag