FROM stadlerpeter/existdb:6
ARG COMMIT_HASH = a880703d
ARG GITLAB_TOKEN = glpat-J2ZNVTufxBb971yygKqj
ADD https://oauth2:${GITLAB_TOKEN}@git.uni-paderborn.de/vife/henze-digital/hwh-webapp/-/jobs/artifacts/develop/file/build/HWH-WebApp-0.1.0.xar?job=build-webapp ${EXIST_HOME}/autodeploy

ADD https://oauth2:${GITLAB_TOKEN}@git.uni-paderborn.de/vife/henze-digital/henze-digital/-/jobs/artifacts/develop/file/build/hwh-data-${COMMIT_HASH}.xar?job=build-data-package ${EXIST_HOME}/autodeploy