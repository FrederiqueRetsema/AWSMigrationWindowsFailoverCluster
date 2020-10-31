# UpdateASGConfiguration.py
# =========================

import json
import boto3
import requests

# Constants
# ---------
AUTOSCALINGGROUPNAME = "ASG"

# send function from: https://docs.amazonaws.cn/en_us/AWSCloudFormation/latest/UserGuide/cfn-lambda-function-code-cfnresponsemodule.html
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0
 
SUCCESS = "SUCCESS"
FAILED  = "FAILED"
 
def send_response(event, context, responseStatus, responseData, physicalResourceId=None, noEcho=False):
    responseUrl = event['ResponseURL']
 
    print("TRACE responseUrl: "+responseUrl)
 
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
# ---

# update_asg_configuration
# ------------------------
def update_asg_configuration():

  autoscaling = boto3.client("autoscaling")
  response = autoscaling.update_auto_scaling_group(
    AutoScalingGroupName = AUTOSCALINGGROUPNAME,
    HealthCheckType = "ELB",
    HealthCheckGracePeriod = 0
  )
  print("TRACE Response update_auto_scaling_group: " + json.dumps(response))

  return

# parse_event
# -----------
def parse_event(event):

  request_type = event["RequestType"]
  return_value = { 'request_type': request_type }

  return return_value

# Main Program
# ============

def handler(event, context):
  print("START UpdateASGConfiguration.py")
  print("TRACE event: " + str(event))

  results      = parse_event(event)
  request_type = results["request_type"]

  print("TRACE request_type: " + request_type)

  from botocore.exceptions import ClientError
  try:

    if (request_type in ("Create", "Update")):
      update_asg_configuration()    
      send_response(event, context, SUCCESS, {}, "")

    else:
      # Delete: no need to do anything, just return success
      send_response(event, context, SUCCESS, {}, "")

  except ClientError as e:
    print("ERROR " + str(e))
    send_response(event, context, FAILED, {}, "")   

  print("END UpdateASGConfiguration.py")
  return
