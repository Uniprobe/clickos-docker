FROM ghcr.io/uniprobe/clickos:environment

## Allow for Partial Caching
ARG CACHE_TWEAK="Add the date to this arg to break the cache here"

## Pull ClickOS
ARG CLICKOS_BR=latest
ARG CLICKOS_REPO=https://github.com/willfantom/clickos
RUN git clone -b ${CLICKOS_BR} ${CLICKOS_REPO} ${CLICKOS_ROOT}

## Build ClickOS
ARG EXTRA_FLAGS=""
ARG STATS_LEVEL=0
WORKDIR ${CLICKOS_ROOT}
RUN ./configure --with-xen=${XEN_ROOT} \
                --with-minios=${MINIOS_ROOT} \
                --with-newlib=${NEWLIB_ROOT} \
                --with-lwip=${LWIP_ROOT} \
                --enable-minios \
                --enable-stats=${STATS_LEVEL} \
                ${EXTRA_FLAGS}
RUN make -j elemlist
RUN make -j $(getconf _NPROCESSORS_ONLN) minios
RUN mkdir -p /out \
 && mv ${CLICKOS_ROOT}/minios/build/* /out

## Multi-Stage Niceness
FROM busybox

COPY --from=builder /out/clickos_x86_64 /clickos/
COPY --from=builder /out/clickos_x86_64.gz /clickos/
COPY --from=builder /out/clickos_x86_64_nostrip /clickos/

WORKDIR /clickos
ENTRYPOINT [ "cp", "-va", ".", "/output" ]
