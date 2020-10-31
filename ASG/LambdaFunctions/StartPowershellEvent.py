# StartPowershellEvent.py
# =======================

import json
import boto3
import base64
import time
import gzip

TIMEOUT_IN_SECONDS = 600  # 10 minutes
DIRECTORY          = "C:\\Install\\"

# remove_event_target
# -------------------
def remove_event_target(event_rule_name):

  events = boto3.client('events')
  response = events.remove_targets(
     Rule = event_rule_name,
     Ids  = [event_rule_name]
  )
  print("TRACE response on remove_targets: " + str(response))

  return

# remove_event_rule
# -----------------
def remove_event_rule(event_rule_name):

  events = boto3.client('events')
  response = events.delete_rule(
     Name = event_rule_name
  )
  print("TRACE response on delete_rule: " + str(response))

  return

# get_instance_id
# ---------------
def get_instance_id(computer_name):

  ec2 = boto3.client("ec2")
  response = ec2.describe_instances(
    Filters = [ { 'Name': 'tag:Name', 'Values': [computer_name] }]
  ) 

  print("TRACE response on describe_instances: " + str(response))

  # Find the first instance_id with this computer_name that is running
  instance_id = ""
  for reservation in response["Reservations"]:
    for instance in reservation["Instances"]:
      if (instance["State"]["Name"] == "running"):
        instance_id = instance["InstanceId"]
        break

  return instance_id

# send_command
# ------------
def send_command(instance_id, commands, comment):

  ssm = boto3.client("ssm")
  print("TRACE InstanceId: " + instance_id) 

  response_send_command = ssm.send_command(
      InstanceIds     = [instance_id],
      DocumentName    = "AWS-RunPowerShellScript",
      DocumentVersion = "$LATEST",
      TimeoutSeconds  = TIMEOUT_IN_SECONDS,
      Comment         = comment,
      Parameters      = {
          "commands" : [
            commands
          ]
      }
  )
  print("TRACE response of send_command:" + str(response_send_command))

  command_id = response_send_command["Command"]["CommandId"]

  return { 'command_id' : command_id}

# remove_event
# ------------
def remove_event(event_rule_name):

  from botocore.exceptions import ClientError
  try:

    remove_event_target(event_rule_name)
    remove_event_rule(event_rule_name)
    
  except ClientError as e:
    print("TRACE Remove of target or rule unsuccesful (error: " + str(e)+ "), eventrule " + event_rule_name + " might not exist?")

  return

# parse_event
# -----------
def parse_event(event):

  # event_rule_arn is something like arn:aws:events:us-east-1:123456789012:rule/DC-part2.ps1
  event_rule_arn   = event["resources"][0]
  event_rule_parts = event_rule_arn.split('/')
  event_rule_name  = event_rule_parts[1]

  # event_rule_name from this example is DC-part2.ps1
  event_rule_name_parts  = event_rule_name.split('-')
  computer_name          = event_rule_name_parts[0]
  powershell_script_name = event_rule_name_parts[1]  

  return_value = { 'event_rule_name'        : event_rule_name,
                   'computer_name'          : computer_name,
                   'powershell_script_name' : powershell_script_name }

  return return_value

# Main program
# ============
def handler(event, context):
  print("START StartPowershellEvent.py")
  print("TRACE event: " + json.dumps(event))

  result                 = parse_event(event)
  event_rule_name        = result["event_rule_name"]
  computer_name          = result["computer_name"]
  powershell_script_name = result["powershell_script_name"]

  print("TRACE event_rule_name: " + event_rule_name + ", computer_name: " + computer_name + ", powershell_script_name: " + powershell_script_name)

  remove_event(event_rule_name)

  instance_id = get_instance_id(computer_name) 
  commands    = "cd " + DIRECTORY + ";. " + DIRECTORY + powershell_script_name
  comment     = "RETRY " + powershell_script_name + " on "  + computer_name

  send_command(instance_id, commands, comment)

  print("END StartPowershellEvent.py")
  return
