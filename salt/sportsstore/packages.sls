Sports Store Clone Script:
    file.managed:
    - name: /tmp/sportsstore.clone.sh
    - source: salt://scripts/sportsstore.clone.sh

Clonning Sports Store:
    cmd.run:
    - name: sh /tmp/sportsstore.clone.sh