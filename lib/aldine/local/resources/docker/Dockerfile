# @see https://github.com/SwagDevOps/image-aldine
FROM aldine:0.0.1

ARG workdir=/workdir
ARG lib_dir=lib

ENV WORKDIR=${workdir} \
    TEXINPUTS=${workdir}/${lib_dir}//: \
    BUNDLE_ONLY=default

RUN mkdir -p "${WORKDIR}"

WORKDIR ${WORKDIR}
