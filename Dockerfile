FROM stadlerpeter/existdb:6

ARG ACCESS_HENDI_DATA

RUN curl --output hendi-webapp.zip --header "JOB-TOKEN: ${CI_JOB_TOKEN}" --location "https://git.uni-paderborn.de/api/v4/projects/5005/jobs/artifacts/develop/download?job=build-webapp" #&&\
RUN unzip hendi-webapp.zip #&&\
 #rm hendi-webapp.zip &&\
 #mv webapp/*.xar ${EXIST_HOME}/autodeploy

RUN curl --output hendi-data.zip --header "PRIVATE-TOKEN:${ACCESS_HENDI_DATA}" --location "https://git.uni-paderborn.de/api/v4/projects/2328/jobs/artifacts/develop/download?job=build-data-package" #&&\
RUN unzip hendi-data.zip #&&\
 #rm hendi-data.zip &&\
 #mv data/*.xar ${EXIST_HOME}/autodeploy

#ADD /projects/2328/jobs/artifacts/develop/download?job=build-data-package && unzip data/*.zip && rm data/*.zip && mv *.xar ${EXIST_HOME}/autodeploy

RUN curl --output WeGA-WebApp-lib-1.8.0.xar --location "https://github.com/Edirom/WeGA-WebApp-lib/releases/download/v1.8.0/WeGA-WebApp-lib-1.8.0.xar" &&\
 mv WeGA-WebApp-lib-1.8.0.xar ${EXIST_HOME}/autodeploy
