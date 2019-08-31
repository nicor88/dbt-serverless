import json

import boto3

sm = boto3.client('stepfunctions')

sm_arn = 'arn:aws:states:eu-west-1:191605532619:stateMachine:dbt-serverless-sm'

dbt_command = 'dbt run'

input_sm = json.dumps({'commands': dbt_command.split(' ')})

response = sm.start_execution(
    stateMachineArn=sm_arn,
    name='test_python_invoke',
    input=input_sm
)
print(response)
