# Docker image for Elastic Curator - [![Build Status](https://jenkins.toulouse.appstud.com/buildStatus/icon?job=elastic-curator/master)](https://jenkins.toulouse.appstud.com/job/elastic-curator/job/master/)

[Elastic Curator](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/about.html) is a ElasticSearch routine runner. [Documentation@elastic.co](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/index.html)

Unfortunately, Elastic does not provide any official image for Curator so here it is !

## Configuration

You can configure this image with environment variables and files.

### Environment variables

* `VERSION` let you run another version than the one shipped in the image (see `VERSION` for default value)
* `CRON` - Define the cron you want (default `0  2  *  *  *`)

### Files

* `/curator/curator.yml` - Configure the connection to ElasticSearch & logging for curator - [Reference@elastic.co](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/configfile.html)

* `/curator/actions.yml` - Configure the actions to execute - [Documentation@elastic.co](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/actions.html)

## Examples

### docker-composer.yml (small)
```yaml
version: "3.5"

services:
  curator:
    build: ./curator
    logging:
      options:
        max-size: 50m
    volumes:
      - ./curator.yml:/curator/curator.yml
      - ./actions.yml:/curator/actions.yml
    networks:
      - elk_default
    environment:
      - CRON=0  10  *  *  *
      - VERSION=5.5.1

networks:
  elk_default:
    name: elk_default
    driver: bridge
```

### docker-composer.yml (classic)
```yaml
version: "3.5"

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:6.2.3
    logging:
      options:
        max-size: 50m
    ports:
      - 9200:9200
      - 9300:9300
    networks:
      - elk_default
    environment:
      - discovery.type=single-node
      - "path.repo=/backups"
    volumes:
      - ./elasticsearch/elasticsearch.yml:/config/elasticsearch.yml
      - ./es-data:/usr/share/elasticsearch/data
      - ./es-backups:/backups
    ulimits:
      memlock:
        soft: -1
        hard: -1

  kibana:
    image: docker.elastic.co/kibana/kibana:6.2.3
    logging:
      options:
        max-size: 50m
    ports:
      - 5601:5601
    networks:
      - elk_default
  
  metricbeat:
    image: docker.elastic.co/beats/metricbeat:6.2.3
    logging:
      options:
        max-size: 50m
    user: root
    networks:
      - elk_default
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./metricbeat/metricbeat.yml:/usr/share/metricbeat/metricbeat.yml

  filebeat:
    image: docker.elastic.co/beats/filebeat:6.2.3
    logging:
      options:
        max-size: 50m
    user: root
    networks:
      - elk_default
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - ./filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml
      - ./filebeat/prospectors:/usr/share/filebeat/prospectors.d

  curator:
    build: ./curator
    logging:
      options:
        max-size: 50m
    networks:
      - elk_default
    environment:
      - CRON=0  10  *  *  *
      # Define a custom curator version - default to the latest built
      #- VERSION=5.5.1

networks:
  elk_default:
    name: elk_default
    driver: bridge
```

### curator.yml
```yaml
client:
  hosts:
    - elasticsearch
  port: 9200
  url_prefix:
  use_ssl: False
  certificate:
  client_cert:
  client_key:
  ssl_no_validate: False
  http_auth:
  timeout: 30
  master_only: False

logging:
  loglevel: INFO
  logfile:
  logformat: default
  blacklist: ['elasticsearch', 'urllib3']
```

### actions.yml
```yaml
client:
  actions:
  1:
    action: snapshot
    description: >-
      Snapshot yesterday
    options:
      # Name of the snapshot created - Nothing to do with the folder
      repository: backups
      # Leaving name blank will result in the default 'curator-%Y%m%d%H%M%S'
      name: metriclogs-%Y%m%d
      wait_for_completion: True
      max_wait: 3600
      wait_interval: 10
      ignore_empty_list: True
    filters:
      # Get all metricbeat & filebeat indexes
      - filtertype: pattern
        kind: regex
        value: '^.*(metricbeat-|filebeat-).*$'
      - filtertype: period
        period_type: relative
        source: creation_date
        range_from: -1
        range_to: -1
        unit: days
  2:
    action: delete_indices
    description: >-
      Delete indices > 30 days
    options:
      ignore_empty_list: True
    filters:
      # Get all metricbeat & filebeat indexes
      - filtertype: pattern
        kind: regex  
        value: '^.*(metricbeat-|filebeat-).*$'
      # Remove everything
      - filtertype: age
        source: creation_date
        direction: older
        unit: days
        unit_count: 30
  3:
    action: delete_snapshots
    description: >-
      Delete 'metriclogs' snapshots > 60 days
    options:
      # Name of the snapshot created - Nothing to do with the folder
      repository: backups
      # Leaving name blank will result in the default 'curator-%Y%m%d%H%M%S'
      retry_interval: 120
      retry_count: 3
      ignore_empty_list: True
    filters:
      # Get all metriclogs snapshots
      - filtertype: pattern
        kind: regex
        value: '^(metriclogs-|).*$'
      # Remove metriclogs > 60 days
      - filtertype: age
        source: creation_date
        direction: older
        unit: days
        unit_count: 60
```
