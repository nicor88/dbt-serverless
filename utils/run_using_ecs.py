import uuid

import boto3

ecs = boto3.client('ecs')


def run_dbt(command, subnets=None, security_groups=None ):
    ecs_command = command.split(' ')
    ecs_subnets = subnets or ['subnet-02b703119b15085ed']
    ecs_security_groups = security_groups or ['sg-0bb3d067d0b7a1b9a']
    network_config = {
        'awsvpcConfiguration': {
            'subnets': ecs_subnets,
            'assignPublicIp': 'ENABLED',
            # to prevent https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_cannot_pull_image.html
            'securityGroups': ecs_security_groups
        }
    }

    overrides = {
        'containerOverrides': [
            {
                'name': 'dbt',
                'command': ecs_command
            },
        ]
    }
    execution_id = f'{uuid.uuid4()}'

    response = ecs.run_task(cluster='dbt-serverless',
                            taskDefinition='dbt-serverless-task',
                            launchType='FARGATE',
                            startedBy=execution_id,
                            networkConfiguration=network_config,
                            overrides=overrides)
    return response, execution_id


# examples
run_dbt('dbt run')
