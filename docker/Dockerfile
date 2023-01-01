FROM ubuntu:focal
# Base APT configuration

ENV DEBIAN_FRONTEND=noninteractive

RUN grep 'ubuntu.com/ubuntu' /etc/apt/sources.list \
    | grep '# deb-src' \
    | sed -e 's/^# //g' >> /etc/apt/sources.list
RUN sed -i 's@http://archive.ubuntu.com/ubuntu@http://mirror.asergo.com/ubuntu/@g' /etc/apt/sources.list
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
# APT mirror set
RUN pip3 install --upgrade pip
RUN pip3 install setuptools
RUN pip3 install --user apt-smart

RUN PATH=$PATH:$HOME/.local/bin apt-smart -a

RUN apt-get update \
    && apt-get install -y --no-install-recommends libxml2 m4 curl \
        bison flex libxml2-dev git subversion libboost-dev texinfo cmake make gcc \
        libtemplate-tiny-perl libtemplate-plugin-yaml-perl cpanminus g++ libz-dev sudo \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV Z88DK_PATH="/opt/z88dk"
RUN curl -L https://github.com/z88dk/z88dk/releases/download/v2.2/z88dk-src-2.2.tgz > /z88dk.tar.gz

WORKDIR /opt

RUN tar xvf /z88dk.tar.gz

WORKDIR ${Z88DK_PATH}

RUN cpanm -l $HOME/perl5 --no-wget local::lib Template::Plugin::YAML

RUN eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)" \
    && GNUMAKEFLAGS="-j$(nproc)" bash ./build.sh -k \
    && bash ./build.sh -k

RUN apt-get update \
    && apt-get install -y --no-install-recommends '^tilp.*' xxd pkg-config libglib2.0-dev '^libticables.*' '^libtifiles.*' '^libticalcs.*' libreadline-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN useradd -u 1000 builder

RUN usermod -a -G sudo builder

ADD ./sudoers /etc/sudoers.d/nopasswd

WORKDIR /home/builder

WORKDIR /app

USER 1000

ENV PATH="$Z88DK_PATH/bin:$PATH" \
    ZCCCFG="$Z88DK_PATH/lib/config/"