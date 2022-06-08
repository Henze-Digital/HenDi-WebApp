FROM stadlerpeter/existdb:6

ARG CI_JOB_TOKEN

RUN curl --output WeGA-WebApp-lib-1.8.0.xar --location "https://github.com/Edirom/WeGA-WebApp-lib/releases/download/v1.8.0/WeGA-WebApp-lib-1.8.0.xar" && mv WeGA-WebApp-lib-1.8.0.xar ${EXIST_HOME}/autodeploy
RUN curl --location --output hendiData.zip "https://git.uni-paderborn.de/api/v4/projects/2328/jobs/artifacts/develop/download?job=build-data-package&job_token=$CI_JOB_TOKEN"
RUN curl --location --output hendiWebapp.zip "https://git.uni-paderborn.de/api/v4/projects/5005/jobs/artifacts/develop/download?job=build-webapp&job_token=$CI_JOB_TOKEN"

RUN unzip hendi-webapp.zip && rm hendi-webapp.zip && mv webapp/*.xar ${EXIST_HOME}/autodeploy
RUN unzip hendi-data.zip && rm hendi-data.zip && mv data/*.xar ${EXIST_HOME}/autodeploy
