FROM phusion/baseimage:0.10.1
MAINTAINER The crowdwiz decentralized organisation

ENV LANG=en_US.UTF-8
RUN \
    apt-get update -y && \
    apt-get install -y \
      g++ \
      autoconf \
      cmake \
      git \
      libbz2-dev \
      libcurl4-openssl-dev \
      libssl-dev \
      libncurses-dev \
      libboost-thread-dev \
      libboost-iostreams-dev \
      libboost-date-time-dev \
      libboost-system-dev \
      libboost-filesystem-dev \
      libboost-program-options-dev \
      libboost-chrono-dev \
      libboost-test-dev \
      libboost-context-dev \
      libboost-regex-dev \
      libboost-coroutine-dev \
      libtool \
      doxygen \
      ca-certificates \
      fish \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD . /crowdwiz-core
WORKDIR /crowdwiz-core

# Compile
RUN \
    ( git submodule sync --recursive || \
      find `pwd`  -type f -name .git | \
	while read f; do \
	  rel="$(echo "${f#$PWD/}" | sed 's=[^/]*/=../=g')"; \
	  sed -i "s=: .*/.git/=: $rel/=" "$f"; \
	done && \
      git submodule sync --recursive ) && \
    git submodule update --init --recursive && \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
	-DGRAPHENE_DISABLE_UNITY_BUILD=ON \
        . && \
    make witness_node cli_wallet get_dev_key && \
    install -s programs/witness_node/witness_node programs/genesis_util/get_dev_key programs/cli_wallet/cli_wallet /usr/local/bin && \
    #
    # Obtain version
    mkdir /etc/crowdwiz && \
    git rev-parse --short HEAD > /etc/crowdwiz/version && \
    cd / && \
    rm -rf /crowdwiz-core

# Home directory $HOME
WORKDIR /
RUN useradd -s /bin/bash -m -d /var/lib/crowdwiz crowdwiz
ENV HOME /var/lib/crowdwiz
RUN chown crowdwiz:crowdwiz -R /var/lib/crowdwiz

# Volume
VOLUME ["/var/lib/crowdwiz", "/etc/crowdwiz"]

# rpc service:
EXPOSE 11011
# p2p service:
EXPOSE 1776

# default exec/config files
ADD docker/default_config.ini /etc/crowdwiz/config.ini
ADD docker/crowdwizentry.sh /usr/local/bin/crowdwizentry.sh
RUN chmod a+x /usr/local/bin/crowdwizentry.sh

# Make Docker send SIGINT instead of SIGTERM to the daemon
STOPSIGNAL SIGINT

# default execute entry
CMD ["/usr/local/bin/crowdwizentry.sh"]
