FROM google/dart:2.8 AS dart-runtime

RUN apt-get update

RUN pub global activate webdev

WORKDIR /app/
COPY pubspec.* /app/
RUN pub get

COPY . /app/
RUN pub get --offline

WORKDIR /app/website/
RUN pub get

RUN chmod 777 /app/bin/server.dart

RUN webdev build --no-release --output web:build

RUN dart2native /app/bin/server.dart -o /app/server

FROM frolvlad/alpine-glibc:alpine-3.11_glibc-2.31

COPY --from=dart-runtime /app/server /server
COPY --from=dart-runtime /app/website/build /website/build
# COPY databases/  databases/

CMD []
ENTRYPOINT ["/server"]

ENV PORT=8081
