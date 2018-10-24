FROM alpine:latest

RUN mkdir /buildroot
WORKDIR /buildroot

RUN apk add --no-cache erlang erlang-inets erlang-dev erlang-ssl git && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk add --no-cache rebar3 && \
    git clone https://github.com/antibi0tic/websocket_chat.git && \
    cd websocket_chat && rebar3 compile

WORKDIR /buildroot/websocket_chat

ENTRYPOINT ["erl", "-noshell", "-pa", "_build/default/lib/cowboy/ebin/", "-pa", "_build/default/lib/cowlib/ebin/", "-pa", "_build/default/lib/ranch/ebin/", "-pa", "_build/default/lib/websocket_chat/ebin/", "-pa", "_build/default/lib/jsx/ebin/", "-s", "websocket_chat_app", "fast_start"]
