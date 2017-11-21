#------------------------------------------------------------------
# docker-in-house-swagger
#------------------------------------------------------------------
#* build image
# docker build -t in-house-swagger:latest .
#------------------------------------------------------------------
#* running
# docker run -p 9700:9700 -p 9701:9701 in-house-swagger:latest
#------------------------------------------------------------------

FROM openjdk:8-jre

RUN apt-get update -y           && \
    apt-get install -y             \
    curl                           \
    gpg                            \
    procps                         \
    unzip                          \
    git                         && \
    apt-get clean               && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p ~/in-house-swagger

COPY . /root/in-house-swagger/

RUN cd ~/in-house-swagger/build && \
    ./build-product.sh          && \
    cd ~/                       && \
    tar xzf ~/in-house-swagger/dist/in-house-swagger-with*.tar.gz && \
    cd ~/in-house-swagger-with*/bin && \
    ./install                       && \
    git config --global user.name spec-mgr && \
    git config --global user.email spec-mgr@example.com && \
    cd ~/in-house-swagger-with*/module/swagger-spec-mgr/bin/git && \
    ./clone.sh

CMD cd ~/in-house-swagger-with*/bin && \
    ./server start && \
    while [ 1 = $(ps -fe | grep start.jar | grep -v grep | wc -l) ]; do sleep 30; done

