{% from "fluentd/map.jinja" import fluentd with context %}

{% if fluentd.install_packages %}
fluentd_package:
  pkg.installed:
    - pkgs:
      - {{ fluentd.package | json }}
    - watch_in:
      - service: {{ fluentd.service }}
{% endif %}

{% if fluentd.get('plugins') %}
  pkg.installed:
    - pkgs: {{ ejabberd.extra_packages | json }}
{% endif %}

{{ fluentd.config.base }}/{{ fluentd.config.filename }}:
  file.managed:
    - template: jinja
    - source: salt://fluentd/files/td-agent.conf
    - backup: minion
    - watch_in:
      - service: {{ fluentd.service }}
{% if fluentd.install_packages %}
    - require:
      - pkg: fluentd_package
{% endif %}

fluentd_service:
  service.running:
    - name: {{ fluentd.service }}
    - watch:
      - file: {{ fluentd.config.base }}/{{ fluentd.config.filename }}
{% if fluentd.install_packages %}
      - pkg: fluentd_package
    - require:
      - pkg: fluentd_package
{% endif %}
{% if fluentd.get('service_persistent', True) %}
    - enable: True
{% endif %}
{% if 'enable_service_control' in fluentd and fluentd.enable_service_control == false %}
    # never run this state
    - onlyif:
      - /bin/false
{% endif %}