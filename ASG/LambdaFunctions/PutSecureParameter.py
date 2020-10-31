# PutSecureParameter.py
# =====================

import json
import boto3
import requests

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

# create_parameter
# ----------------
def create_parameter(name, value, description):

  ssm = boto3.client("ssm")

  response = ssm.put_parameter(
    Name        = name,
    Value       = value,
    Description = description,
    Type        = "SecureString",
    Overwrite   = True
  )
  print("TRACE Response put_parameter: " + json.dumps(response))

  return

# delete_parameter
# ----------------
def delete_parameter(name):

  ssm = boto3.client("ssm")
  response = ssm.delete_parameter(
    Name = name
  )
  print("TRACE Response delete_parameter: " + json.dumps(response))

  return

# parse_event
# -----------
def parse_event(event):

  request_type          = event["RequestType"]

  parameter_name        = event["ResourceProperties"]["ParameterName"]
  parameter_value       = event["ResourceProperties"]["ParameterValue"]
  parameter_description = event["ResourceProperties"]["ParameterDescription"]

  return_value = { 'request_type'          : request_type,
                   'parameter_name'        : parameter_name,
                   'parameter_value'       : parameter_value,
                   'parameter_description' : parameter_description }

  return return_value

# Main Program
# ============

def handler(event, context):
  print("START PutSecureParameter.py")

  result                = parse_event(event)
  request_type          = result["request_type"]
  parameter_name        = result["parameter_name"]
  parameter_value       = result["parameter_value"]
  parameter_description = result["parameter_description"]

  # For security reasons: don't put the parameter_value in the trace
  print("TRACE parameter_name: " + parameter_name + ", parameter_description: " + parameter_description)

  from botocore.exceptions import ClientError
  try:

    if (request_type in ("Create", "Update")):

      create_parameter(parameter_name, parameter_value, parameter_description)
      send_response(event, context, SUCCESS, {}, "")

    elif (request_type == "Delete"):

      delete_parameter(parameter_name)
      send_response(event, context, SUCCESS, {}, "")

    else:
      print("ERROR Unknown request_type = " + request_type)
      send_response(event, context, FAILED, {}, "")

  except ClientError as e:
    print("ERROR " + str(e))

  print("END PutSecureParameter.py")
  return
