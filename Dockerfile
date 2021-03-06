# we'll use Amazon Linux 2 + Corretto 11 as our base
FROM public.ecr.aws/w1m2m2a3/amazoncorretto:11 as base

# configure the build environment
FROM base as build
RUN yum install -y maven
WORKDIR /src

# cache and copy dependencies
COPY lambda/pom.xml .
RUN mvn dependency:go-offline dependency:copy-dependencies

# compile the function
COPY ./lambda .
RUN mvn package

# copy the function artifact and dependencies onto a clean base
FROM base

RUN yum install -y git bash

WORKDIR /function

COPY --from=build /src/target/dependency/*.jar ./
COPY --from=build /src/target/*.jar ./

# configure the runtime startup as main
ENTRYPOINT [ "/usr/bin/java", "-cp", "./*", "com.amazonaws.services.lambda.runtime.api.client.AWSLambda" ]
# pass the name of the function handler as an argument to the runtime
CMD [ "io.jenkins.agent.aws.lambda.AgentHandler" ]
