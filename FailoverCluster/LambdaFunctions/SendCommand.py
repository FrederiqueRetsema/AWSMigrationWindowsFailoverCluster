# SendCommand.py
# ==============

import json
import boto3
import time
import requests

# Constants
# ---------
TIMEOUT_SECONDS    = 600 # Wait max 10 minutes for results from send_command
SLEEP_TIME_SECONDS = 5   # Wait 5 seconds between each status request

# send function from: https://docs.amazonaws.cn/en_us/AWSCloudFormation/latest/UserGuide/cfn-lambda-function-code-cfnresponsemodule.html
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0
 
SUCCESS = "SUCCESS"
FAILED  = "FAILED"

def send_response_to_cloudformation(event, context, responseStatus, responseData, physicalResourceId=None, noEcho=False):
  responseUrl = event['ResponseURL']
 
  print("TRACE responseUrl = " + responseUrl)

  responseBody = {}
  responseBody['Status'] = responseStatus
  responseBody['Reason'] = 'See the details in CloudWatch Log Stream: ' + context.log_stream_name
  responseBody['PhysicalResourceId'] = physicalResourceId or context.log_stream_name
  responseBody['StackId'] = event['StackId']
  responseBody['RequestId'] = event['RequestId']
  responseBody['LogicalResourceId'] = event['LogicalResourceId']
  responseBody['NoEcho'] = noEcho
  responseBody['Data'] = responseData

  json_responseBody = json.dumps(responseBody)

  print("TRACE Response body: " + json_responseBody)

  headers = {
      'content-type' : '',
      'content-length' : str(len(json_responseBody))
  }

  try:
      response = requests.put(responseUrl,
                              data=json_responseBody,
                              headers=headers)
      print("TRACE Status code: " + response.reason)
  except Exception as e:
      print("ERROR send(..) failed executing requests.put(..): " + str(e))

  return
# ---

# send_command
# ------------
def send_command(instance_id, commands, comment):

  ssm = boto3.client("ssm")
  response_send_command = ssm.send_command(
      InstanceIds = [instance_id],
      DocumentName = "AWS-RunPowerShellScript",
      DocumentVersion = "$LATEST",
      TimeoutSeconds = TIMEOUT_SECONDS,
      Comment = comment,
      Parameters = {
        "commands" : [
          commands
        ]
      }
  )
  print("TRACE response send_command:" + str(response_send_command))
  command_id = response_send_command["Command"]["CommandId"]

  return command_id

# get_status_of_sent_command
# --------------------------
def get_status_of_sent_command(command_id, instance_id):

  ssm = boto3.client("ssm")  
  response_get_command_invocation = ssm.get_command_invocation(
      CommandId = command_id,
      InstanceId =instance_id
      )
  print("TRACE response get_command_invocation:" + str(response_get_command_invocation))
  status = response_get_command_invocation["Status"]

  return status

# parse_event
# -----------
def parse_event(event):

  request_type = event["RequestType"]
  instance_id  = event["ResourceProperties"]["InstanceId"]
  commands     = event["ResourceProperties"]["Commands"]
  comment      = event["ResourceProperties"]["Comment"]

  return_value = { 'request_type': request_type,
                   'instance_id' : instance_id,
                   'commands'    : commands,
                   'comment'     : comment}

  return return_value  

# Main Program
# ============
def handler(event, context):

  print("START SendCommand.py")
  print("TRACE event: "+json.dumps(event))

  results = parse_event(event)
  request_type = results["request_type"]
  instance_id  = results["instance_id"]
  commands     = results["commands"]
  comment      = results["comment"]

  from botocore.exceptions import ClientError
  try:

    if (request_type == "Create"):

      print("TRACE InstanceId: " + instance_id + ", commands: " + commands + ", comment: " + comment) 
      command_id = send_command(instance_id, commands, comment)
    
      time.sleep(SLEEP_TIME_SECONDS)  
      status = get_status_of_sent_command(command_id, instance_id)

      while (status in ('Pending', 'InProgress', 'Delayed')):
        print("TRACE Status: " + status)
    
        time.sleep(SLEEP_TIME_SECONDS)  
        status = get_status_of_sent_command(command_id, instance_id)

      print("TRACE Status: " + status)

      if (status == 'Success'):
        send_response_to_cloudformation(event, context, SUCCESS, {}, "")
      else:
        send_response_to_cloudformation(event, context, FAILED, {}, "")

    else:
      # Update or delete, not relevant for this function, just return SUCCESS
      send_response_to_cloudformation(event, context, SUCCESS, {}, "")

  except ClientError as e:
    print("ERROR: "+str(e))
    send_response_to_cloudformation(event, context, FAILED, {}, "")
  
  print("END SendCommand.py")
  return 
