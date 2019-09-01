import json
import uuid

import boto3

sm = boto3.client('stepfunctions')

sm_arn = 'arn:aws:states:eu-west-1:191605532619:stateMachine:dbt-serverless-with-deps'

dbt_command_1 = 'dbt run --models example'
dbt_command_2 = 'dbt run --models just_another_example'

input_sm = {
    'commands1': dbt_command_1.split(' '),
    'commands2': dbt_command_2.split(' ')
}

execution_id = f'python_invoke_{uuid.uuid4()}'

response = sm.start_execution(
    stateMachineArn=sm_arn,
    name=execution_id,
    input=json.dumps(input_sm)
)
print(response)
