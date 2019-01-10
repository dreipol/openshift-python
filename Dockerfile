FROM python:3.6.8-jessie
MAINTAINER dreipol GmbH <dev@dreipol.ch>

# setup NPM and node versions
ENV NODE_VERSION=10.14.1 \
    NPM_VERSION=6.1.0 \
    NVM_DIR=/usr/local/nvm \
    NVM_VERSION=0.33.11 \
    NODE_ENV="prod" \
    TEMPLATE_ENV="dist"

ENV NODE_PATH=$NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules \
    PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# define django settings module
ENV DJANGO_SETTINGS_MODULE=$PROJECT_NAME.settings.production

# install node version manager
RUN mkdir $NVM_DIR
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v$NVM_VERSION/install.sh | bash

RUN /bin/bash -c "source $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION && \
    nvm use default"

# set proxy setting
#RUN npm config set proxy $HTTP_PROXY
#RUN npm config set https-proxy $HTTP_PROXY

# create app directory
RUN mkdir -p /app
WORKDIR /app

ONBUILD ARG PROJECT_NAME
ONBUILD ARG HTTP_PROXY

# copy & install backend dependencies
ONBUILD COPY requirements.txt /app
#RUN pip install --proxy=$HTTP_PROXY -r requirements.txt
ONBUILD RUN pip install -r requirements.txt

# copy  & install frontend dependencies
ONBUILD COPY package.json package-lock.json /app/
ONBUILD RUN npm ci

#copy and build frontend
ONBUILD COPY .babelrc* .browserslistrc* .eslintignore* .eslintrc* .modernizrrc* .stylelintrc* gulpfile.js /app/
ONBUILD COPY gulp/ /app/gulp/
ONBUILD COPY $PROJECT_NAME/assets/src/ /app/$PROJECT_NAME/assets/src/
ONBUILD RUN npm run build


#copy the python app
ONBUILD COPY . /app

EXPOSE $PORT
# run gunicorn
CMD ["/bin/sh", "-e", "./rungunicorn.sh"]
