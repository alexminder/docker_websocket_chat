websocket_chat:
  docker_image.present:
   - build: /root
   - tag: v1
   - require:
     - service: docker

websocket_chat-container:
  docker_container.running:
    - image: 'websocket_chat:v1'
    - require:
      - docker_image: websocket_chat
