{% from "fluentd/map.jinja" import fluentd with context %}

{% if fluentd.install_packages %}
fluentd_package:
  pkg.installed:
    - pkgs:
      - {{ fluentd.package }}
    - watch_in:
      - service: {{ fluentd.service }}
{% endif %}

{% if fluentd.plugins is defined %}
{% for plugin in fluentd.plugins%}
{{ plugin }}:
  gem.installed:
{% if fluentd.type != 'gem' %}
    - gem_bin: {{ fluentd.prefix }}/bin/gem
{% endif %}
{% if fluentd.gem_proxy is defined %}
    - proxy: {{ fluentd.gem_proxy }}
{% endif %}
{% if plugin.version is defined %}
    - source: {{ plugin.version }}
{% endif %}
{% if plugin.source is defined %}
    - source: {{ plugin.source }}
{% endif %}
{% endfor %}
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