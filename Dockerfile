FROM debian:bookworm-slim@sha256:f9c6a2fd2ddbc23e336b6257a5245e31f996953ef06cd13a59fa0a1df2d5c252

ENV DEBIAN_FRONTEND=noninteractive

# Container image must write into the mounted workspace.
# We use a generic runtime working directory and reserve GH Actions-specific
# workspace mounting behavior for runtime detection, not image structure.
# This image is ephemeral and only used in CI, so we run as root here to
# allow workspace writes and to avoid non-root permission failures when
# generating PDFs.
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    gnupg \
    lmodern \
    pandoc \
    texlive-xetex \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    fonts-inter \
  && mkdir -p /tmp /tmp/fontconfig \
  && chmod 1777 /tmp \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY . /action
RUN chmod +x /action/entrypoint.sh /action/generate.bash

ENV HOME=/root
ENV XDG_CACHE_HOME=/tmp
ENV FONTCONFIG_PATH=/tmp/fontconfig

ENTRYPOINT ["/action/entrypoint.sh"]
