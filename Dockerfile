# This file was inspired by the original pandoc Dockerfile
# https://github.com/pandoc/dockerfiles/blob/master/alpine/Dockerfile
# Base ##################################################################
ARG base_image_version=3.17
FROM alpine:$base_image_version AS alpine-builder-base
WORKDIR /app

ARG lua_version=5.4
RUN apk --no-cache add \
        alpine-sdk \
        bash \
        ca-certificates \
        cabal \
        fakeroot \
        ghc \
        git \
        gmp-dev \
        libffi \
        libffi-dev \
        lua$lua_version-dev \
        pkgconfig \
        yaml \
        zlib-dev

COPY common/cabal.root.config /root/.cabal/config
RUN cabal --version \
  && ghc --version \
  && cabal v2-update

# Builder ###############################################################
FROM alpine-builder-base as alpine-builder
ARG pandoc_commit=3.1.1
RUN git clone --branch=$pandoc_commit --depth=1 --quiet \
  https://github.com/jgm/pandoc /usr/src/pandoc

COPY ./common/pandoc.project.freeze \
     /usr/src/pandoc/cabal.project.freeze

# Install Haskell dependencies
WORKDIR /usr/src/pandoc
# Add pandoc-crossref to project
ARG without_crossref=
RUN test -n "$without_crossref" || \
    printf "extra-packages: pandoc-crossref\n" > cabal.project.local;

# Additional projects to compile alongside pandoc
ARG extra_packages="pandoc-cli pandoc-crossref"

# Build pandoc and pandoc-crossref. The `allow-newer` is required for
# when pandoc-crossref has not been updated yet, but we want to build
# anyway.
RUN cabal v2-update \
  && cabal v2-build \
      --allow-newer 'lib:pandoc' \
      --disable-tests \
      --disable-bench \
      --jobs \
      . $extra_packages

# Cabal's exec stripping doesn't seem to work reliably, let's do it here.
RUN find dist-newstyle \
         -name 'pandoc*' -type f -perm -u+x \
         -exec strip '{}' ';' \
         -exec cp '{}' /usr/local/bin/ ';'

# Minimal ###############################################################
FROM alpine:$base_image_version AS alpine-minimal
ARG pandoc_version=3.1.1
ARG lua_version=5.4
LABEL maintainer='Albert Krewinkel <albert+pandoc@zeitkraut.de>'
LABEL org.pandoc.maintainer='Albert Krewinkel <albert+pandoc@zeitkraut.de>'
LABEL org.pandoc.author "John MacFarlane"
LABEL org.pandoc.version "$pandoc_version"

WORKDIR /data
ENTRYPOINT ["/usr/local/bin/pandoc"]

COPY --from=alpine-builder \
  /usr/local/bin/pandoc \
  /usr/local/bin/

# Reinstall any system packages required for runtime.
RUN apk --no-cache update && apk --no-cache upgrade \
    && apk --no-cache add \
        gmp \
        libffi \
        lua$lua_version \
        lua$lua_version-lpeg

# LaTeX #################################################################
FROM alpine-minimal as wbhdoc-latex

# NOTE: to maintainers, please keep this listing alphabetical.
RUN apk --no-cache add \
        freetype \
        fontconfig \
        gnupg \
        gzip \
        perl \
        tar \
        wget \
        xz

# DANGER: this will vary for different distributions, particularly the
# `linuxmusl` suffix. Alpine linux is a musl libc based distribution,
# for other "more common" distributions, you likely want just `-linux`
# suffix rather than `-linuxmusl` -----> vvvvvvvvv
ENV PATH="/opt/texlive/texdir/bin/x86_64-linuxmusl:${PATH}"
WORKDIR /root

# Installer scripts and config
COPY common/latex/texlive.profile /root/texlive.profile
COPY common/latex/install-texlive.sh /root/install-texlive.sh
COPY common/latex/packages.txt /root/packages.txt

# Request musl precompiled binary access
RUN echo "binary_x86_64-linuxmusl 1" >> /root/texlive.profile \
  && /root/install-texlive.sh \
  && sed -e 's/ *#.*$//' -e '/^ *$/d' /root/packages.txt | \
     xargs tlmgr install \
  && rm -f /root/texlive.profile \
           /root/install-texlive.sh \
           /root/packages.txt \
  && TERM=dumb luaotfload-tool --update \
  && chmod -R o+w /opt/texlive/texdir/texmf-var

# Puzzle ITC Template integration #########################################
FROM wbhdoc-latex as wbhdoc
LABEL org.opencontainers.image.authors="Sebastian Preisner <kreativmonkey@calyruim.org>"

COPY pandoc-wbh-template /templates
COPY entrypoint.sh /
RUN mkdir -p /usr/share/fonts/truetype \
    && tar -xf /templates/common/Merriweather.tar.xz -C /usr/share/fonts/truetype/ \
    && tar -xf /templates/common/arimo.tar.xz -C /usr/share/fonts/truetype/ \
    && rm /templates/common/*.tar.xz \
    && mv /templates/example /example \
    && chmod 0755 -R /templates && chmod 0755 -R /example && chmod 0744 /entrypoint.sh \
    && fc-cache -f && rm -rf /var/cache/*

WORKDIR /data
ENV LANG=C.UTF-8

ENTRYPOINT [ "/bin/sh", "/entrypoint.sh" ]
