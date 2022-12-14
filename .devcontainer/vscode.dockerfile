###################################################################################################################
# Adapted from https://github.com/rpodcast/r_dev_projects/blob/main/.devcontainer/Dockerfile
# Adapted from https://github.com/microsoft/vscode-dev-containers/blob/master/containers/r/.devcontainer/Dockerfile
# licence: MIT
###################################################################################################################

FROM rocker/r-ver:4.2.1

# Options for setup script
ARG QUARTO_VERSION
ARG RPACKAGES

ENV QUARTO_VERSION=$QUARTO_VERSION


# key dependencies for certain R packages
RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends software-properties-common curl wget libssl-dev libxml2-dev libsodium-dev imagemagick libmagick++-dev libgit2-dev libssh2-1-dev zlib1g-dev librsvg2-dev libudunits2-dev libcurl4-openssl-dev python3-pip pandoc libzip-dev libfreetype6-dev libfontconfig1-dev tk libpq5 libxt6 openssh-client openssh-server git \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# install R packages needed for VSCode interaction, package management and Rstudio interaction
RUN install2.r --error --skipinstalled --ncpus -4 languageserver renv remotes httpgd

# install additional R packages
RUN install2.r --error --skipinstalled --ncpus -4 $RPACKAGES

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

RUN /rocker_scripts/install_quarto.sh
