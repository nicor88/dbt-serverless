[
  {
    "name": "${container_name}",
    "image": "${image}:${image_version}",
    "essential": ${essential},
    "environment": [
      {
        "name": "DB_HOST",
        "value": "${db_host}"
      },
      {
        "name": "DB_PORT",
        "value": "${db_port}"
      },
      {
        "name": "DB_USER",
        "value": "${db_user}"
      },
      {
        "name": "DB_PASSWORD",
        "value": "${db_password}"
      },
      {
        "name": "DB_NAME",
        "value": "${db_name}"
      },
      {
        "name": "DB_SCHEMA",
        "value": "${db_schema}"
      }
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "${log_group}",
            "awslogs-region": "${log_region}",
            "awslogs-stream-prefix": "${log_stream_prefix}"
        }
    }
  }
]