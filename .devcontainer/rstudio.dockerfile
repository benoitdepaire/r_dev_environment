FROM rocker/r-ver:4.2.1

LABEL org.opencontainers.image.licenses="GPL-2.0-or-later" \
      org.opencontainers.image.source="https://github.com/rocker-org/rocker-versioned2" \
      org.opencontainers.image.vendor="Rocker Project" \
      org.opencontainers.image.authors="Carl Boettiger <cboettig@ropensci.org>"

ARG RSTUDIO_USER
ARG PASSWORD
ARG RSTUDIO_FOCUS_DIR

ENV S6_VERSION=v2.1.0.2
ENV RSTUDIO_VERSION=2022.07.2+576
ENV PANDOC_VERSION=default
ENV QUARTO_VERSION=default
ENV DEFAULT_USER=$RSTUDIO_USER
ENV PASSWORD=$PASSWORD
ENV EDITOR_FOCUS_DIR=$RSTUDIO_FOCUS_DIR

# key dependencies for certain R packages
RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends software-properties-common curl wget libssl-dev libxml2-dev libsodium-dev imagemagick libmagick++-dev libgit2-dev libssh2-1-dev zlib1g-dev librsvg2-dev libudunits2-dev libcurl4-openssl-dev python3-pip pandoc libzip-dev libfreetype6-dev libfontconfig1-dev tk libpq5 libxt6 openssh-client openssh-server git \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# install R packages needed for VSCode interaction and package management
RUN install2.r --error --skipinstalled --ncpus -4 languageserver renv remotes httpgd

# install radian via python and pip3
RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends python3-setuptools

RUN pip3 install radian

# install dot net core runtime for the R Tools plugin
RUN wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb \
    && dpkg -i /tmp/packages-microsoft-prod.deb

RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-transport-https \
    && apt-get -y install --no-install-recommends dotnet-sdk-3.1
    
# ensure that the renv package cache env var is accessible in default R installation
RUN echo "RENV_PATHS_CACHE=/renv/cache" >> /usr/local/lib/R/etc/Renviron

# copy the modified .Rprofile template to the renv cache
# COPY library-scripts/.Rprofile-vscode /renv/.Rprofile-vscode


RUN /rocker_scripts/install_rstudio.sh
RUN /rocker_scripts/install_pandoc.sh
RUN /rocker_scripts/install_quarto.sh

EXPOSE 8787

RUN echo "setwd(\"/home/lucp1554/Rcontainer/workspace/\")" > ~/../home/$RSTUDIO_USER/.Rprofile 
RUN echo "setHook(\"rstudio.sessionInit\", function(newSession) {\n  if (newSession)\n    rstudioapi::filesPaneNavigate(getwd())\n}, action = \"append\")" >> ~/../home/$RSTUDIO_USER/.Rprofile 

# [Optional] Set the default user. Omit if you want to keep the default as root.
# ARG USERNAME
# USER $USERNAME
RUN install2.r --error --skipinstalled --ncpus -4 rstudioapi

CMD ["/init"]