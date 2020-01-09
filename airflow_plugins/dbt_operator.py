import pprint
import sys

from airflow.exceptions import AirflowException
from airflow.models import BaseOperator
from airflow.plugins_manager import AirflowPlugin
from airflow.utils import apply_defaults
from airflow.contrib.hooks.aws_hook import AwsHook


class DbtOperator(BaseOperator):
    ui_color = '#D6EAF8'
    client = None
    arn = None

    @apply_defaults
    def __init__(self,
                 command,
                 target='dev',
                 dbt_models=None,
                 dbt_exclude=None,
                 subnets=[],
                 security_groups=[],
                 aws_connection_id='aws_default',
                 region_name='eu-west-1',
                 cluster='dbt-serverless',
                 task_definition='dbt-serverless-task',
                 log_group_name='/aws/ecs/dbt-serverless',
                 log_stream_name='dbt/dbt-serverless-task',  # TODO to check
                 ** kwargs):
        super(DbtOperator, self).__init__(**kwargs)

        self.command = command
        self.dbt_models = dbt_models
        self.target = target
        self.dbt_exclude = dbt_exclude

        self.aws_conn_id = aws_connection_id
        self.region_name = region_name
        self.cluster = cluster
        self.task_definition = task_definition
        self.log_group_name = log_group_name
        self.log_stream_name = log_stream_name
        self.subnets = subnets
        self.security_groups = security_groups

        self.hook = self.get_hook()

    def execute(self, context):
        container_command = ['dbt', f'{self.command}', '--target', f'{self.target}']

        if self.dbt_models is not None:
            container_command.extend(['--models', f'{self.dbt_models}'])
        if self.dbt_exclude is not None:
            container_command.extend(['--exclude', f'{self.dbt_exclude}'])

        overrides = {
            'containerOverrides': [
                {
                    'name': 'dbt',
                    'command': container_command
                }
            ]
        }

        self.log.info(f'Running ECS Task - Task definition: {self.task_definition} - on cluster {self.cluster}')
        self.log.debug('ECSOperator overrides: %s', overrides)

        self.client = self.hook.get_client_type(
            'ecs',
            region_name=self.region_name
        )

        response = self.client.run_task(
            cluster=self.cluster,
            taskDefinition=self.task_definition,
            launchType='FARGATE',
            overrides=overrides,
            startedBy=f'{self.target}_{self.command}',
            networkConfiguration={'awsvpcConfiguration': {
                'subnets': self.subnets,
                'assignPublicIp': 'ENABLED',  # keep it enabled otherwise will fail to pull the image
                'securityGroups': self.security_groups
            }}
        )

        failures = response['failures']
        if len(failures) > 0:
            raise AirflowException(response)

        self.log.info(f'ECS Task {self.task_definition} started')
        self.log.debug('ECS Task started: %s', pprint.pformat(response))

        self.arn = response['tasks'][0]['taskArn']
        self.task_id = response['tasks'][0]['taskArn'].split('/')[1]
        self._wait_for_task_ended()

        self._check_success_task()

        self.log.debug('ECS Task has been successfully executed: %s', pprint.pformat(response))

        self.log.info('Retrieving logs from Cloudwatch')

        self._get_cloudwatch_logs()

        self.log.info(f'{self.task_id} task has been successfully executed in ECS cluster {self.cluster}')

    def _wait_for_task_ended(self):
        waiter = self.client.get_waiter('tasks_stopped')
        waiter.config.max_attempts = sys.maxsize  # timeout is managed by airflow
        waiter.wait(
            cluster=self.cluster,
            tasks=[self.arn]
        )

    def _check_success_task(self):
        response = self.client.describe_tasks(
            cluster=self.cluster,
            tasks=[self.arn]
        )
        self.log.info(f'ECS Task {self.task_id} stopped')
        self.log.debug('ECS Task stopped, check status: %s', pprint.pformat(response))

        if len(response.get('failures', [])) > 0:
            raise AirflowException(response)

        for task in response['tasks']:
            containers = task['containers']
            for container in containers:
                if container.get('lastStatus') == 'STOPPED' and container['exitCode'] != 0:
                    self._get_cloudwatch_logs()
                    raise AirflowException('This task is not in success state {}'.format(task))
                elif container.get('lastStatus') == 'PENDING':
                    self._get_cloudwatch_logs()
                    raise AirflowException('This task is still pending {}'.format(task))
                elif 'error' in container.get('reason', '').lower():
                    self._get_cloudwatch_logs()
                    raise AirflowException('This containers encounter an error during launching : {}'.
                                           format(container.get('reason', '').lower()))

    def _get_cloudwatch_logs(self):
        try:
            cloudwatch_client = self.hook.get_client_type(
                'logs',
                region_name=self.region_name
            )
            raw_logs = cloudwatch_client.get_log_events(
                logGroupName=self.log_group_name,
                logStreamName=f'{self.log_stream_name}/{self.task_id}',
                startFromHead=True
            )
            for event in raw_logs.get('events'):
                self.log.info(f'{event.get("message")}')
        except Exception as error:
            self.log.error(f'There was en error fetching Cloudwatch logs for task {self.task_id}')
            self.log.error(error)

    def get_hook(self):
        return AwsHook(
            aws_conn_id=self.aws_conn_id
        )

    def on_kill(self):
        response = self.client.stop_task(
            cluster=self.cluster,
            task=self.arn,
            reason='Task killed by the user')
        self.log.info('Task killed by the user')
        self.log.debug(pprint.pformat(response))


class DbtPlugin(AirflowPlugin):
    name = 'dbt_plugin'
    operators = [DbtOperator]
