{%- from tpldir + "/map.jinja" import confmap with context -%}

include:
  - .websocket_chat

docker:
  pkg.installed:
    - name: {{ confmap.pkg }}
  service:
    - running
    - enable: True
    - require:
      - pkg: docker
    - watch:
      - pkg: docker
{% if grains['os_family'] == 'RedHat' %}
/etc/sysconfig/docker-storage-setup:
  file.managed:
    - source: salt://{{ tpldir }}/files/docker-storage-setup.sysconfig
    - user: root
    - group: root
    - template: jinja
    - require:
      - pkg: docker
    - require_in:
      - service: docker

cloud-utils-growpart:
  pkg.installed

/usr/bin/docker-storage-setup:
  cmd.wait:
    - watch:
      - file: /etc/sysconfig/docker-storage-setup
    - require:
      - pkg: cloud-utils-growpart
      - file: /etc/sysconfig/docker-storage-setup
    - require_in:
      - service: docker

docker-storage-setup:
  service.enabled:
    - require:
      - pkg: cloud-utils-growpart
      - file: /etc/sysconfig/docker-storage-setup

user.max_user_namespaces:
   sysctl.present:
      - value: 30000
      - config: /etc/sysctl.d/69-unix-custom.conf
      - require_in:
        - service: docker

fs.may_detach_mounts:
  sysctl.present:
      - value: 1
      - config: /etc/sysctl.d/69-unix-custom.conf
      - require_in:
        - service: docker

/etc/sysconfig/docker:
  augeas.change:
    - require:
      - pkg: docker
    - require_in:
      - service: docker
    - context: /files/etc/sysconfig/docker
    - lens: shellvars.lns
    - changes:
      - set OPTIONS "'--selinux-enabled --log-driver=journald --signature-verification=false --userns-remap=default'"

 {%- if salt['cmd.retcode']("grubby --info=DEFAULT|grep args=|grep -q 'namespace.unpriv_enable=1'", python_shell=True) != 0 %}
grubby:
  cmd.run:
    - name: grubby --update-kernel=ALL --args=namespace.unpriv_enable=1
    - require_in:
      - service: docker
 {%- endif %}

docker-cleanup:
  service:
    - enabled
    - require:
      - file: /etc/sysconfig/docker-storage-setup
{%- endif %}

dockremap:
  group.present:
    - system: True
  user.present:
    - fullname: Docker usernamespace mapping user
    - shell: /sbin/nologin
    - home: /
    - system: True
    - require:
      - group: dockremap
    - groups:
      - dockremap

{%- if salt['cmd.retcode']("grep '^dockremap:' /etc/subuid") != 0 %}
echo "dockremap:808080:65536" >> /etc/subuid:
  cmd.run:
    - require:
      - user: dockremap
    - require_in:
      - service: docker
{%- endif %}

{%- if salt['cmd.retcode']("grep '^dockremap:' /etc/subgid") != 0 %}
echo "dockremap:808080:65536" >> /etc/subgid:
  cmd.run:
    - require:
      - user: dockremap
    - require_in:
      - service: docker
{%- endif %}
