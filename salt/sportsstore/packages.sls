Dependency Packages:
  pkg.installed:
    - pkgs:
      - nodejs
      - npm

{% if salt['grains.get']('app-store') != 'yes' %}
Sports Store Clone Script:
    file.managed:
    - name: /tmp/sportsstore.install.sh
    - source: salt://scripts/sportsstore.install.sh
{% endif %}

Sports Store App:
    cmd.run:
    {% if salt['grains.get']('app-store') != 'yes' %}
    - name: sh /tmp/sportsstore.install.sh -i
    grains.present:
      - name: app-store
      - value: 'yes'
    {% else %}
    - name: sh /tmp/sportsstore.install.sh -c
    {% endif %}