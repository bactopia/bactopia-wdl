FROM bactopia/bactopia:2.1.1

LABEL base.image="FROM bactopia/bactopia:2.1.1"
LABEL software="Bactopia"
LABEL software.version="2.1.1"
LABEL description="A flexible pipeline for complete analysis of bacterial genomes"
LABEL website="https://bactopia.github.io/"
LABEL license="https://github.com/bactopia/bactopia/blob/master/LICENSE"
LABEL maintainer="Robert A. Petit III"
LABEL maintainer.email="robbie.petit@gmail.com"

ENV CLOUDSDK_INSTALL_DIR /usr/local/gcloud/
RUN curl -sSL https://sdk.cloud.google.com | bash
ENV PATH $PATH:/usr/local/gcloud/google-cloud-sdk/bin
COPY bin/bactopia-stats.py /opt/conda/envs/bactopia/bin
COPY bin/bactopia-config.py /opt/conda/envs/bactopia/bin
