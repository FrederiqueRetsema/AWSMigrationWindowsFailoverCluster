# CreateImage.py
# ==============

import json
import boto3
import requests
import time

# Constants
# ---------
WAIT_TIME_SECONDS = 5 
IMAGE_NAME        = "ASGNodeImage"
IMAGE_DESCRIPTION = "ASGNode Image"

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

# get_instance_state
# ------------------

def get_instance_state(instance_id):

  ec2 = boto3.client("ec2")
  response = ec2.describe_instances(
    Filters = [
        {
          'Name'  : 'instance-id',
          'Values': [instance_id]
        }
    ]
  )
  print("TRACE Response describe_instances: " + str(response))
  state = response["Reservations"][0]["Instances"][0]["State"]["Name"]

  return state

# wait_for_stopped_instance
# -------------------------
def wait_for_stopped_instance(instance_id):

  state = get_instance_state(instance_id) 
  while(state != 'stopped'):

    print("TRACE Instance state = " + state + ", wait " + str(WAIT_TIME_SECONDS) + " seconds")
    time.sleep(WAIT_TIME_SECONDS)
    state = get_instance_state(instance_id) 

  print("TRACE Instance state = " + state + ", ok")

  return

# create_image
# ------------
def create_image(instance_id):

  ec2 = boto3.client("ec2")

  response = ec2.create_image(
    Name        = IMAGE_NAME,
    Description = IMAGE_DESCRIPTION,
    InstanceId  = instance_id
  )
  print("TRACE Response create_image: " + json.dumps(response))
  image_id = response["ImageId"]

  return image_id

# get_image_state
# -----------
def get_image_state(image_id):

  ec2 = boto3.client("ec2")
  
  response = ec2.describe_images(
    Filters = [
        {
          'Name'  : 'image-id',
          'Values': [image_id]
        }
    ]
  )
  print("TRACE Response describe_images: " + json.dumps(response))
  state = response["Images"][0]["State"]
  return state

# wait_for_available_image
# ------------------------
def wait_for_available_image(image_id):

  state = get_image_state(image_id) 
  while (state in ('pending', 'transient')):

    print("TRACE Image state = " + state + ", wait " + str(WAIT_TIME_SECONDS) + " seconds")
    time.sleep(WAIT_TIME_SECONDS)
    state = get_image_state(image_id) 

  if (state != 'available'):
    raise Exception("Error in creating image: state = " + state)

  print("TRACE Image state = " + state + ", ok")

  return

# terminate_instance
# ------------------
def terminate_instance(instance_id):

  ec2 = boto3.client("ec2")
  
  response = ec2.terminate_instances(
    InstanceIds = [instance_id]
  )
  print("TRACE Response terminate_instances: " + json.dumps(response))

  return

# find_image
# ----------
def find_image(image_name):

  ec2 = boto3.client("ec2")  
  response = ec2.describe_images(
    Filters = [
        {
          'Name'  : 'name',
          'Values': [image_name]
        }
    ]
  )

  print("TRACE Response describe_instances: " + json.dumps(response))
  image_id = response["Images"][0]["ImageId"]

  print("TRACE image_id = " + image_id)

  return image_id

# deregister_image
# ----------------
def deregister_image(image_id):

  ec2 = boto3.client("ec2")  
  response = ec2.deregister_image(
    ImageId=image_id
  )

  print("TRACE Response deregister_image: " + json.dumps(response))

  return

# parse_event
# -----------
def parse_event(event):

  request_type = event["RequestType"]
  instance_id  = event["ResourceProperties"]["InstanceId"]

  return_value = { 'request_type': request_type,
                   'instance_id' : instance_id }

  return return_value

# Main Program
# ============

def handler(event, context):

  image_id = "unknown"

  print("TRACE event = "+json.dumps(event))
  response     = parse_event(event)
  request_type = response["request_type"]
  instance_id  = response["instance_id"]

  print("TRACE request_type = " + request_type + ", instance_id = " + instance_id)

  from botocore.exceptions import ClientError
  try:  

    if (request_type == "Create"):

      wait_for_stopped_instance(instance_id)
      image_id = create_image(instance_id)
      wait_for_available_image(image_id)
      terminate_instance(instance_id)

      send_response(event, context, SUCCESS, {'ImageId': image_id}, "")

    elif (request_type == "Delete"):

      image_id = find_image(IMAGE_NAME)
      deregister_image(image_id)

      send_response(event, context, SUCCESS, {}, "")

    else:
      # Don't do anything for updates
      send_response(event, context, SUCCESS, {}, "")

  except ClientError as e:
    print("ERROR " + str(e))
    send_response(event, context, FAILED, {}, "")   

  return 
