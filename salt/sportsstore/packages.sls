upload-script:
    file.managed:
    - name: /src/scripts/sportsstore.clone.sh
    - source: /src/scripts/sportsstore.clone.sh

run-script:
    cmd.run:
    - name: /src/scripts/sportsstore.clone.sh