FROM stadlerpeter/existdb:6

ARG CI_JOB_TOKEN
ENV EXIST_ENV=development

RUN curl --output WeGA-WebApp-lib-1.8.0.xar --location "https://github.com/Edirom/WeGA-WebApp-lib/releases/download/v1.8.0/WeGA-WebApp-lib-1.8.0.xar" &&\
    mv WeGA-WebApp-lib-1.8.0.xar ${EXIST_HOME}/autodeploy
RUN curl --location --output hendiData.zip "https://git.uni-paderborn.de/api/v4/projects/2328/jobs/artifacts/develop/download?job=data-package&job_token=$CI_JOB_TOKEN" &&\
    unzip hendiData.zip &&\
    rm hendiData.zip &&\
    mv hendi-pkg-data/*.xar ${EXIST_HOME}/autodeploy
COPY ./hendi-pkg-webapp/*.xar ${EXIST_HOME}/autodeploy