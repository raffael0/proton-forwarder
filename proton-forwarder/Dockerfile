################################################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
######
######
######	Dockerfile for Proton-forwarder
######
######
################################################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


################################################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
###### Build Hydroxide	
################################################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# builder OS
FROM golang:1-alpine as hydroxide-builder

# update / dependencies  
RUN apk --update upgrade \
&& apk --no-cache --no-progress add git make gcc musl-dev \
&& rm -rf /var/cache/apk/*

# docker container settings
ENV GOPATH /go

# build hydroxide
RUN git -C ./src/ clone https://github.com/emersion/hydroxide/
RUN cd /go/src/hydroxide/cmd/hydroxide && go build . && go install . && cd


################################################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
###### Copy Hydroxide to container
################################################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# container OS
FROM alpine:3.18

USER root

# update / dependencies
RUN apk --update upgrade \
    && apk --no-cache add ca-certificates bash openrc \
    && rm -rf /var/cache/apk/*

# email variables; either pass these from your docker-compose file OR uncomment and insert below
#ENV HYDROXIDEUSER you@youremail.here
#ENV HYDROXIDEPASS yourPasswordHere 
# copy hydroxide
COPY --from=hydroxide-builder /go/bin/hydroxide /usr/bin/hydroxide

################################################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
###### Install Fetchmail
################################################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


RUN apk --no-cache --no-progress add fetchmail \
&& rm -rf /var/cache/apk/*

################################################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
###### Install Postfix
################################################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RUN apk --no-cache --no-progress add postfix\
&& rm -rf /var/cache/apk/*


################################################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
###### start the app
################################################%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
COPY ./start.sh start.sh

WORKDIR /

ENTRYPOINT ["/start.sh"] 

