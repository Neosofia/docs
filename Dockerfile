FROM debian:bookworm-slim@sha256:f9c6a2fd2ddbc23e336b6257a5245e31f996953ef06cd13a59fa0a1df2d5c252

ENV DEBIAN_FRONTEND=noninteractive

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
  && groupadd -r docs \
  && useradd -r -g docs -d /home/docs -m docs \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /github/workspace
COPY . /action
RUN chmod +x /action/entrypoint.sh /action/generate.bash \
  && chown -R docs:docs /action

USER docs

ENTRYPOINT ["/action/entrypoint.sh"]
