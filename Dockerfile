FROM python:3-alpine as base

ENV LANG en_US.UTF-8
ENV PIP_NO_CACHE_DIR true
ENV PYTHONUNBUFFERED 1

RUN apk update --no-cache && apk upgrade --no-cache &&\
    pip install --upgrade pip setuptools wheel

### Python Dependencies ###
FROM base as python-deps

COPY requirements.txt requirements.txt
RUN pip install --prefix=/build -r requirements.txt

# Cleanup *.key files
RUN for i in $(find /build -type f -name "*.key*"); do rm "$i"; done

### Kubernetes Tools ###
FROM base as kubernetes
RUN apk add --no-cache curl bash openssl && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256" && \
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum -c && \
    mkdir -p /build/bin && \
    install -o root -g root -m 0755 kubectl /build/bin/kubectl && \
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
    cp /usr/local/bin/helm /build/bin/

### AWS CLI ###
FROM python:3.10-alpine as aws

ARG AWS_CLI_VERSION=2.9.10

RUN apk add --no-cache git unzip groff build-base libffi-dev cmake
RUN git clone --single-branch --depth 1 -b ${AWS_CLI_VERSION} https://github.com/aws/aws-cli.git

WORKDIR aws-cli
RUN python -m venv venv
RUN . venv/bin/activate
RUN scripts/installers/make-exe
RUN unzip -q dist/awscli-exe.zip
RUN aws/install
RUN aws --version

# reduce image size: remove autocomplete and examples
RUN rm -rf \
    /usr/local/aws-cli/v2/current/dist/aws_completer \
    /usr/local/aws-cli/v2/current/dist/awscli/data/ac.index \
    /usr/local/aws-cli/v2/current/dist/awscli/examples
RUN find /usr/local/aws-cli/v2/current/dist/awscli/data -name completions-1*.json -delete
RUN find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data -name examples-1.json -delete
RUN mkdir -p /build/bin && \
    cp -Rfp /usr/local/aws-cli /build/ && \
    ln -s /usr/local/aws-cli/v2/current/bin/aws /build/bin

### Final ###
FROM base as final

# Tools that can be added simply with apk
RUN apk add --no-cache mysql-client postgresql-client bash curl git jq wget

COPY --from=python-deps /build /usr/local
COPY --from=kubernetes /build /usr/local
COPY --from=aws /build /usr/local
COPY --chmod=+x scripts/* /usr/local/bin

ENTRYPOINT ["/bin/bash"]
