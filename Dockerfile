FROM stadlerpeter/existdb:6
ARG GITLAB_TOKEN=glpat-J2ZNVTufxBb971yygKqj

RUN curl --output hendi-webapp.zip --header "PRIVATE-TOKEN:${GITLAB_TOKEN}"  --location "https://git.uni-paderborn.de/api/v4/projects/5005/jobs/artifacts/develop/download?job=build-webapp"

RUN curl --output hendi-data.zip --header "PRIVATE-TOKEN:${GITLAB_TOKEN}"  --location "https://git.uni-paderborn.de/api/v4/projects/2328/jobs/artifacts/develop/download?job=build-data-package"

RUN curl --output WeGA-WebApp-lib-1.8.0.xar --location "https://github.com/Edirom/WeGA-WebApp-lib/releases/download/v1.8.0/WeGA-WebApp-lib-1.8.0.xar"

RUN unzip hendi-webapp.zip && rm hendi-webapp.zip && mv dist/*.xar ${EXIST_HOME}/autodeploy &&\
    unzip hendi-data.zip && rm hendi-data.zip && mv data/*.xar ${EXIST_HOME}/autodeploy &&\
    mv WeGA-WebApp-lib-1.8.0.xar ${EXIST_HOME}/autodeploy
    mv WeGA-WebApp-lib-1.8.0.xar ${EXIST_HOME}/autodeploy
