FROM sdthirlwall/raspberry-pi-cross-compiler:jessie

RUN echo 'deb http://deb.debian.org/debian jessie-backports main' >> /etc/apt/sources.list
RUN apt update
RUN apt-get -t jessie-backports install -y cmake
RUN install-debian --update libtool pkg-config wget lbzip2

RUN install-raspbian --update libssl-dev libgstreamer-plugins-base1.0-dev libatlas-base-dev \
    libgstreamer1.0-dev libsqlite3-dev libasound2-dev libgstreamer-plugins-base1.0-dev libopus-dev 

ENV LDFLAGS="--sysroot=${SYSROOT}"
ENV CFLAGS="--sysroot=${SYSROOT}"
ENV PATH=${PATH}:/rpxc/bin/
ENV PKG_CONFIG_PATH=${SYSROOT}/usr/lib/arm-linux-gnueabihf/pkgconfig:/rpxc/sysroot/lib/pkgconfig/

#replace prefix definition from '/usr' to $SYSROOT/usr
RUN for pc in `ls /rpxc/sysroot/usr/lib/arm-linux-gnueabihf/pkgconfig/*.pc`; \
    do sed -i 's/prefix=\/usr/prefix=\/rpxc\/sysroot\/usr/' $pc; done
    
#replace libstdc++6.0.19 to libstdc++6.0.20
RUN rm /rpxc/arm-linux-gnueabihf/lib/libstdc++.so
RUN ln -s /rpxc/sysroot/usr/lib/arm-linux-gnueabihf/libstdc++.so.6.0.20 /rpxc/arm-linux-gnueabihf/lib/libstdc++.so
RUN rm /rpxc/arm-linux-gnueabihf/lib/libstdc++.so.6
RUN ln -s /rpxc/sysroot/usr/lib/arm-linux-gnueabihf/libstdc++.so.6 /rpxc/arm-linux-gnueabihf/lib/libstdc++.so.6

#or curl ./configure fail
RUN ln -s /rpxc/sysroot/lib/arm-linux-gnueabihf /lib/arm-linux-gnueabihf
RUN ln -s /rpxc/arm-linux-gnueabihf/libc/usr/lib/arm-linux-gnueabihf /usr/lib/arm-linux-gnueabihf

#install nghttp2 from source
RUN cd /tmp && git clone https://github.com/tatsuhiro-t/nghttp2.git && cd nghttp2 \
    && autoreconf -i && automake && autoconf && ./configure --prefix=$SYSROOT --host=${HOST} && make && make install \
    && cd /tmp && rm -rf *

#install curl with http2 support
RUN cd /tmp && wget https://curl.haxx.se/download/curl-7.54.0.tar.bz2 \
    && tar xf curl-7.54.0.tar.bz2 &&  cd curl-7.54.0 \
    && ./configure --prefix=$SYSROOT --host=$HOST --with-nghttp2 --with-ssl && make && make install \
    && cd /tmp && rm -rf *

#install portaudio dev
RUN wget -c http://www.portaudio.com/archives/pa_stable_v190600_20161030.tgz && tar xf pa_stable_v190600_20161030.tgz \
    && cd portaudio && ./configure --prefix=$SYSROOT --without-oss --with-alsa --without-jack --host=$HOST \
    && make && make install && cd /tmp && rm -rf *

#==============till now we have a development envirement, following start build IFLYOS===========================

#RUN mkdir /ivs
#RUN mkdir -p /ivs-build/sdk2-agents
#RUN mkdir -p /ivs-build/ivs-sdk
#ADD . /ivs
#ADD ../avs-device-sdk /ivs

#make agents
#RUN cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_TOOLCHAIN_FILE=/ivs/sdk2-agents/toolchain.txt /ivs/sdk2-agents && make

#make sdk
#RUN cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_TOOLCHAIN_FILE=/ivs/sdk2-agents/toolchain.txt -DBUILD_TESTING=OFF -DBLUETOOTH_BLUEZ=OFF -DOPUS=ON /ivs/avs-device-sdk
#RUN make VERBOSE=1 && make DESTDIR=$PWD/out install

#collect artifacts for runtime
#/rpxc/sysroot/lib/libnghttp2.so*
#/rpxc/sysroot/lib/libcurl.so*
#/rpxc/sysroot/lib/libportaudio.so*
#/ivs-build/sdk2-agents/MicAgent/MicAgent
#/ivs-build/sdk2-agents/IFLYOSUmbrella/IFLYOSUmbrella
#/ivs-build/ivs-sdk/out/usr/local/lib/*.so
#/ivs-build/ivs-sdk/out/usr/bin/*

