FROM ccr.ccs.tencentyun.com/dev-runtime/raspberry-pi-cross-compiler:gcc4.9.4

#need cmake 3.10+
RUN install-debian --update libtool pkg-config wget lbzip2
RUN cd /tmp && wget https://github.com/Kitware/CMake/releases/download/v3.14.0/cmake-3.14.0.tar.gz && tar xf cmake-3.14.0.tar.gz \
  && cd cmake-3.14.0 && ./bootstrap && apt remove -y cmake && make && make install && rm -rf /tmp/cmake* && ln -s /usr/bin/cmake /usr/local/bin/cmake

#for China poor INTERNATIONAL-network
#RUN rpdo sed -i 's/archive.raspbian.org/mirrors.tuna.tsinghua.edu.cn\\/raspbian/' /etc/apt/sources.list
#RUN sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/' /etc/apt/sources.list


RUN install-raspbian --update libssl-dev libgstreamer-plugins-base1.0-dev libatlas-base-dev \
    libgstreamer1.0-dev libsqlite3-dev libasound2-dev libgstreamer-plugins-base1.0-dev libopus-dev 

ENV PATH=${PATH}:/rpxc/bin/
ENV PKG_CONFIG_PATH=${SYSROOT}/usr/lib/arm-linux-gnueabihf/pkgconfig:/rpxc/sysroot/lib/pkgconfig:/rpxc/sysroot/usr/lib/pkgconfig

#replace prefix definition from '/usr' to $SYSROOT/usr
RUN for pc in `ls /rpxc/sysroot/usr/lib/arm-linux-gnueabihf/pkgconfig/*.pc`; \
    do sed -i 's/prefix=\/usr/prefix=\/rpxc\/sysroot\/usr/' $pc; done
    

#ENV LDFLAGS="--sysroot=${SYSROOT}"
#ENV CFLAGS="--sysroot=${SYSROOT}"
#RUN ln -s /rpxc/sysroot/lib/arm-linux-gnueabihf /lib/arm-linux-gnueabihf
#RUN ln -s /rpxc/arm-linux-gnueabihf/libc/usr/lib/arm-linux-gnueabihf /usr/lib/arm-linux-gnueabihf

#replace libstdc++6.0.19 to libstdc++6.0.20
#RUN rm /rpxc/arm-linux-gnueabihf/lib/libstdc++.so
#RUN ln -s /rpxc/sysroot/usr/lib/arm-linux-gnueabihf/libstdc++.so.6.0.20 /rpxc/arm-linux-gnueabihf/lib/libstdc++.so
#RUN rm /rpxc/arm-linux-gnueabihf/lib/libstdc++.so.6
#RUN ln -s /rpxc/sysroot/usr/lib/arm-linux-gnueabihf/libstdc++.so.6 /rpxc/arm-linux-gnueabihf/lib/libstdc++.so.6

#install nghttp2 from source
RUN cd /tmp && git clone --depth 1 https://github.com/tatsuhiro-t/nghttp2.git && cd nghttp2 \
    && autoreconf -i && automake && autoconf && ./configure --prefix=$SYSROOT --host=${HOST} && make && make install \
    && cd /tmp && rm -rf *

#or curl ./configure fail
RUN ln -s /rpxc/sysroot/lib/arm-linux-gnueabihf /lib/arm-linux-gnueabihf
RUN ln -s /rpxc/arm-linux-gnueabihf/sysroot/usr/lib /usr/lib/arm-linux-gnueabihf
RUN cp /rpxc/sysroot/usr/lib/arm-linux-gnueabihf/*.o /rpxc/sysroot/lib/
RUN cp /rpxc/sysroot/usr/lib/arm-linux-gnueabihf/libc* /rpxc/sysroot/lib/
RUN cp -r /rpxc/sysroot/usr/include/arm-linux-gnueabihf/sys/ /rpxc/sysroot/usr/include/
RUN cp -r /rpxc/sysroot/usr/include/arm-linux-gnueabihf/bits/ /rpxc/sysroot/usr/include/
RUN cp -r /rpxc/sysroot/usr/include/arm-linux-gnueabihf/gnu/ /rpxc/sysroot/usr/include/
RUN cp -r /rpxc/sysroot/usr/include/arm-linux-gnueabihf/asm/ /rpxc/sysroot/usr/include/
RUN cp -r /rpxc/sysroot/usr/include/arm-linux-gnueabihf/openssl/ /rpxc/sysroot/usr/include/
RUN cp /rpxc/sysroot/usr/lib/arm-linux-gnueabihf/libssl* /rpxc/sysroot/usr/lib/
RUN cp /rpxc/sysroot/usr/lib/arm-linux-gnueabihf/libcrypto* /rpxc/sysroot/usr/lib/
RUN ln -s /rpxc/sysroot/lib/arm-linux-gnueabihf/libdl.so.2 /rpxc/sysroot/lib/libdl.so
RUN ln -s /rpxc/sysroot/lib/arm-linux-gnueabihf/libdl.so.2 /rpxc/sysroot/lib/libdl.so.2

#install curl with http2 support
RUN cd /tmp && wget https://curl.haxx.se/download/curl-7.64.0.tar.bz2 \
    && tar xf curl-7.64.0.tar.bz2 &&  cd curl-7.64.0 \
    && ./configure CFLAGS=--sysroot=$SYSROOT LDFLAGS="-L/rpxc/sysroot/usr/lib/arm-linux-gnueabihf"  --prefix=$SYSROOT --host=$HOST --with-nghttp2 --with-ssl && make && make install \
    && cd /tmp && rm -rf *

RUN cp /rpxc/sysroot/lib/arm-linux-gnueabihf/libpthread.* /rpxc/sysroot/lib/
RUN cp /rpxc/sysroot/lib/arm-linux-gnueabihf/librt* /rpxc/sysroot/lib/
RUN cp /rpxc/sysroot/lib/arm-linux-gnueabihf/libm* /rpxc/sysroot/lib/
RUN cp /rpxc/sysroot/lib/arm-linux-gnueabihf/librt* /rpxc/sysroot/lib/
RUN cp /rpxc/sysroot/usr/lib/arm-linux-gnueabihf/libasound* /rpxc/sysroot/usr/lib/

#install portaudio dev
RUN wget -c http://www.portaudio.com/archives/pa_stable_v190600_20161030.tgz && tar xf pa_stable_v190600_20161030.tgz \
    && cd portaudio && ./configure CFLAGS=--sysroot=$SYSROOT LDFLAGS="-L/rpxc/sysroot/usr/lib/arm-linux-gnueabihf" --prefix=$SYSROOT --without-oss --with-alsa --without-jack --host=$HOST \
    && sed -i 's/CFLAGS =/CFLAGS = -L\/rpxc\/sysroot\/usr\/lib\/arm-linux-gnueabihf/' Makefile \
    && make && make install && cd /tmp && rm -rf *

RUN for pc in `ls /rpxc/sysroot/usr/lib/pkgconfig/*.pc`; \
    do sed -i 's/prefix=\/usr/prefix=\/rpxc\/sysroot\/usr/' $pc; done

RUN ln -s /rpxc/sysroot/usr/lib/arm-linux-gnueabihf/libgfortran.so.3 /rpxc/sysroot/usr/lib/libgfortran.so

RUN ln -s /rpxc/sysroot/usr/lib/arm-linux-gnueabihf/libffi.so.6 /rpxc/sysroot/usr/lib/arm-linux-gnueabihf/libffi.so
