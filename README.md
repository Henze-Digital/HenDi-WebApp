# HWH-WebApp (Chaining of WeGA-WebApp)

[![Latest Release](https://git.uni-paderborn.de/vife/henze-digital/hwh-webapp/-/badges/release.svg)](https://git.uni-paderborn.de/vife/henze-digital/hwh-webapp/-/releases)

[![pipeline status](https://git.uni-paderborn.de/vife/henze-digital/hwh-webapp/badges/develop/pipeline.svg)](https://git.uni-paderborn.de/vife/henze-digital/hwh-webapp/-/commits/develop) on `develop`

[![pipeline status](https://git.uni-paderborn.de/vife/henze-digital/hwh-webapp/badges/stable/pipeline.svg)](https://git.uni-paderborn.de/vife/henze-digital/hwh-webapp/-/commits/stable)
on `stable`

This repo contains WeGA-WebApp specifics for the Henze Digital Project. The build process updates the source code of the [WeGA-WebApp](https://github.com/Henze-Digital/WeGA-WebApp) and builds the HenDi-WebApp afterwards.

## How to do a release

1. Do the release actions for HenDi-ODD
1. Continue here.

### release workflow on gitlab
- check issues and milestone
- close milestone
- update submodules
- create a release branch
- update file build.properties
- check out and build the app
- test the app
- set tag `v\d\.\d\.\d` (if everything is as expected)
- merge into main
- merge main into develop
- create release based on the tag
- bump version number

### release workflow on github
- go to the mirrored repo on github.com
- create release based on the latest tag