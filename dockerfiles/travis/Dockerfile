FROM travisci/ci-garnet:packer-1512502276-986baf0

USER travis

RUN bash -lc "rvm install 2.3.0"
RUN bash -lc "rvm use 2.3.0 --default"

WORKDIR /home/travis/builds
RUN git clone https://github.com/travis-ci/travis-build.git

WORKDIR /home/travis/builds/travis-build
RUN bash -lc "bundle install"
RUN bash -lc "bundler add travis"
RUN bash -lc "bundler binstubs travis"

RUN mkdir -p /home/travis/.travis
RUN ln -s $(pwd) /home/travis/.travis/travis-build

ENTRYPOINT ["bash", "-l", "-c", "bash /home/travis/entrypoint.sh"]

