FROM stadlerpeter/existdb:6

COPY ./webapp && unzip ./webapp/*.zip && rm ./webapp/*.zip && mv webapp/*.xar ${EXIST_HOME}/autodeploy

#RUN curl --output hendi-webapp.zip --header "PRIVATE-TOKEN:${GITLAB_TOKEN}"  --location "https://git.uni-paderborn.de/api/v4/projects/5005/jobs/artifacts/develop/download?job=build-webapp"

GET /projects/2328/jobs/artifacts/develop/download?job=build-data-package && unzip data/*.zip && rm data/*.zip && mv data/*.xar ${EXIST_HOME}/autodeploy

#RUN curl --output hendi-data.zip --header "PRIVATE-TOKEN:${GITLAB_TOKEN}"  --location "https://git.uni-paderborn.de/api/v4/projects/2328/jobs/artifacts/develop/download?job=build-data-package"

RUN curl --output WeGA-WebApp-lib-1.8.0.xar --location "https://github.com/Edirom/WeGA-WebApp-lib/releases/download/v1.8.0/WeGA-WebApp-lib-1.8.0.xar" && mv WeGA-WebApp-lib-1.8.0.xar ${EXIST_HOME}/autodeploy
