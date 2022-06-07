FROM stadlerpeter/existdb:6

#--header "PRIVATE-TOKEN:${ACCESS_HENDI_DATA}"
RUN curl --output hendi-webapp.zip --location "https://git.uni-paderborn.de/api/v4/projects/5005/jobs/artifacts/develop/download?job=build-webapp" && unzip webapp/hendi-webapp.zip && rm webapp/hendi-webapp.zip && mv webapp/hendi-webapp.xar ${EXIST_HOME}/autodeploy

RUN curl --output hendi-data.zip --location "https://git.uni-paderborn.de/api/v4/projects/2328/jobs/artifacts/develop/download?job=build-data-package" && unzip data/hendi-data.zip && rm data/hendi-data.zip && mv data/hendi-data.xar ${EXIST_HOME}/autodeploy

#ADD /projects/2328/jobs/artifacts/develop/download?job=build-data-package && unzip data/*.zip && rm data/*.zip && mv data/*.xar ${EXIST_HOME}/autodeploy

RUN curl --output WeGA-WebApp-lib-1.8.0.xar --location "https://github.com/Edirom/WeGA-WebApp-lib/releases/download/v1.8.0/WeGA-WebApp-lib-1.8.0.xar" && mv WeGA-WebApp-lib-1.8.0.xar ${EXIST_HOME}/autodeploy
