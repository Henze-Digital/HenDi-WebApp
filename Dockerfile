FROM stadlerpeter/existdb:6

ARG ACCESS_HENDI_DATA
ARG ACCESS_HENDI_WEBAPP

RUN curl --location --output hendi-webapp-artfct.zip --header "PRIVATE-TOKEN: ${ACCESS_HENDI_WEBAPP}" "https://git.uni-paderborn.de/api/v4/projects/5005/jobs/artifacts/develop/download?job=build-webapp"
RUN ls
RUN unzip hendi-webapp-artfct.zip
RUN ls
RUN rm hendi-webapp-artfct.zip
RUN ls
RUN mv webapp/*.xar ${EXIST_HOME}/autodeploy

RUN curl --output hendi-data-artfct.zip --header "PRIVATE-TOKEN: ${ACCESS_HENDI_DATA}" --location "https://git.uni-paderborn.de/api/v4/projects/2328/jobs/artifacts/develop/download?job=build-data-package"
RUN ls
RUN unzip hendi-data-artfct.zip && rm hendi-data-artfct.zip && mv data/*.xar ${EXIST_HOME}/autodeploy

#ADD /projects/2328/jobs/artifacts/develop/download?job=build-data-package&token=${CI_JOB_TOKEN} && unzip data/*.zip && rm data/*.zip && mv *.xar ${EXIST_HOME}/autodeploy

RUN curl --output WeGA-WebApp-lib-1.8.0.xar --location "https://github.com/Edirom/WeGA-WebApp-lib/releases/download/v1.8.0/WeGA-WebApp-lib-1.8.0.xar" &&\
 mv WeGA-WebApp-lib-1.8.0.xar ${EXIST_HOME}/autodeploy
