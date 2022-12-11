# @see https://github.com/SwagDevOps/image-aldine
FROM aldine:0.0.1

ARG workdir=/workdir

ENV WORKDIR=${workdir} \
    TEXINPUTS=${workdir}/lib//: \
    BUNDLE_ONLY=default

RUN mkdir -p "${WORKDIR}"

WORKDIR ${WORKDIR}
