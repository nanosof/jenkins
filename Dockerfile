# ============================================================
# Custom Jenkins Image — Maven + Git/GitHub + Kubernetes
# Base: jenkins/jenkins:lts-jdk17
#
# Build:
#   docker build -t jenkins-custom:1.0 .
#
# Tag & push to your local registry:
#   docker tag  jenkins-custom:1.0 192.168.1.230:5000/jenkins-custom:1.0
#   docker push 192.168.1.230:5000/jenkins-custom:1.0
#
# Update running K8s deployment:
#   kubectl set image deployment/jenkins \
#     jenkins=192.168.1.230:5000/jenkins-custom:1.0 -n jenkins
# ============================================================

FROM docker.io/jenkins/jenkins:lts-jdk17

USER root

# ── OS packages ───────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    unzip \
    fontconfig \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# ── kubectl ───────────────────────────────────────────────────
RUN curl -fsSL "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

# ── Maven ─────────────────────────────────────────────────────
# archive.apache.org is permanent — won't 404 when mirrors rotate
ARG MAVEN_VERSION=3.9.9
RUN curl -fsSL "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
    | tar -xz -C /opt \
    && ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven \
    && ln -s /opt/maven/bin/mvn /usr/local/bin/mvn

# ── Environment ───────────────────────────────────────────────
ENV JAVA_HOME=/opt/java/openjdk
ENV MAVEN_HOME=/opt/maven
ENV PATH="${JAVA_HOME}/bin:${MAVEN_HOME}/bin:${PATH}"

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false \
               -Dorg.jenkinsci.plugins.durabletask.BourneShellScript.HEARTBEAT_CHECK_INTERVAL=300"

ENV CASC_JENKINS_CONFIG=/var/jenkins_casc/jenkins.yaml

# ── Install plugins as jenkins user ───────────────────────────
USER jenkins

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli \
    --plugin-file /usr/share/jenkins/ref/plugins.txt \
    --latest true

EXPOSE 8080 50000