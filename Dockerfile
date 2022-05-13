FROM scratch
LABEL os="2022-04-04-raspios-bullseye-arm64-lite"
LABEL org.opencontainers.image.authors="irmer@gonicus.de"

ADD sysroot.tar.gz /

ENTRYPOINT [ "/bin/bash" ]
