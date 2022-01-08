FROM bactopia/bactopia:2.0.1

LABEL base.image="FROM bactopia/bactopia:2.0.1"
LABEL software="Bactopia"
LABEL software.version="2.0.1"
LABEL description="A flexible pipeline for complete analysis of bacterial genomes"
LABEL website="https://bactopia.github.io/"
LABEL license="https://github.com/bactopia/bactopia/blob/master/LICENSE"
LABEL maintainer="Robert A. Petit III"
LABEL maintainer.email="robbie.petit@gmail.com"

RUN bactopia build --default && mamba clean -ay
