# CreateOrDeletePowershellEvent.py
# ================================

import json
import boto3
import base64
import time
import gzip

# Constants
# ---------
TARGET_LAMBDA_ARN_PARAMETER = "/check/startpowershelleventfunctionarn" 
TEST_PASSED                 = True
TEST_FAILED                 = False

# get_ssm_parameter
# -----------------
def get_ssm_parameter(parameter):  

  print("TRACE get_ssm_parameter " + parameter)
  ssm = boto3.client("ssm")
  response = ssm.get_parameter(
    Name = parameter
  )

  print("TRACE response of get_parameter: " + str(response))
  value = response["Parameter"]["Value"]

  return value

# get_node_name_from_data
# -----------------------
def get_node_name_from_data(data):

  node_name = data["logStream"]

  return node_name

# get_cron_time_for_event
# -----------------------
# Normal result for cron_time: cron(25 20 25 12 ? 2020)   
#                              which is 25 December 2020, 20:25 on whatever working day (Monday - Sunday)
def get_cron_time_for_event(number_of_minutes):

  time_after_x_minutes = time.time() + (number_of_minutes * 60) 
  start_time_event     = time.gmtime(time_after_x_minutes)
  cron_time = "cron(" + str(start_time_event.tm_min) + " " + str(start_time_event.tm_hour) + " " + str(start_time_event.tm_mday) + " " +  str(start_time_event.tm_mon) + " ? " + str(start_time_event.tm_year)+")"

  return cron_time

# create_event_rule
# -----------------
def create_event_rule(event_rule_name, cron_time):

  events = boto3.client('events')
  response = events.put_rule(
    Name               = event_rule_name,  
    ScheduleExpression = cron_time,
    State              = 'ENABLED'
  )
  print("TRACE response of put_rule: " + str(response))

  return

# create_event_target
# -------------------
def create_event_target(event_rule_name, arn):

  events = boto3.client('events')
  response = events.put_targets(
    Rule    = event_rule_name,
    Targets = [{
            'Arn': arn,
            'Id' : event_rule_name,
          }]
  )
  print("TRACE response of put_targets: " + str(response))

  return

# remove_event_target
# -------------------
def remove_event_target(event_rule_name):

  events = boto3.client('events')
  response = events.remove_targets(
     Rule=event_rule_name,
     Ids=[event_rule_name]
  )
  print("TRACE response of remove_targets: " + str(response))

  return

# remove_event_rule
# -----------------
def remove_event_rule(event_rule_name):

  events = boto3.client('events')
  response = events.delete_rule(
     Name = event_rule_name
  )
  print("TRACE response of delete_rule: " + str(response))

  return

# test_check_line
# ---------------
# Normal CHECK line contains text like: CLUSTERNODE1 21:12:13 - CHECK start part3.ps1 in 2 minutes
def test_check_line(check_line):

  test_result = TEST_PASSED

  check_line_words = check_line.split()
  if (len(check_line_words) != 9):
    print("WARNING CHECK line doesn't have the right format, line is ignored. Should have 9 parts (line = " + check_line + " - " + str(len(check_line_words))+" parts)")
    test_result = TEST_FAILED

  if (check_line_words[8] not in('minutes', 'minute')):
    print("WARNING CHECK line only works in minutes, line ignored (line = " + check_line + ")")
    test_result = TEST_FAILED
  
  return test_result

# parse_check_line
# ----------------
# Normal CHECK line contains text like: CLUSTERNODE1 21:12:13 - CHECK start part3.ps1 in 2 minutes
def parse_check_line(check_line):

    line_words             = check_line.split()
    powershell_script_name = line_words[5]
    number_of_minutes      = int(line_words[7])

    return_value = { 'powershell_script_name': powershell_script_name, 
                     'number_of_minutes'     : number_of_minutes}

    return return_value

# process_check_line
# ------------------
def process_check_line(event_data, check_line):

  result = test_check_line(check_line)
  if (result == TEST_PASSED):
    print("TRACE Tests successful")

    # The nodename in the log file doesn't use consistant uppercase/lowercase.
    # The nodename in the log group name (in the event data) has a consistant usage of uppercase/lowercase (and looks nicer in the names of the events as well)
    node_name = get_node_name_from_data(event_data)

    result                 = parse_check_line(check_line)
    powershell_script_name = result["powershell_script_name"]
    number_of_minutes      = result["number_of_minutes"]

    event_rule_name = node_name + "-" + powershell_script_name

    print("TRACE node_name: " + node_name + ", powershell_script: " + powershell_script_name + ", number_of_minutes: " + str(number_of_minutes) + ", event_rule_name: " + event_rule_name)

    cron_time = get_cron_time_for_event(number_of_minutes)
    arn       = get_ssm_parameter(TARGET_LAMBDA_ARN_PARAMETER)
    
    print("TRACE cron_time: " + cron_time + " - arn: " + arn)

    try:
      create_event_rule(event_rule_name, cron_time)
      create_event_target(event_rule_name, arn)

      print("TRACE Add of event " + event_rule_name + " succesful")      
    except:
      print("TRACE Add of event rule or target unsuccesful, eventrule = " + event_rule_name)
    
  else:
    print("TRACE Tests not successful")

  return

# test_start_line
# ---------------
# Normal start line looks like: CLUSTERNODE1 21:12:13 - START part2.ps1
def test_start_line(start_line):

  test_result = TEST_PASSED

  start_line_words = start_line.split()
  if (len(start_line_words) != 5):
    print("WARNING START line doesn't have the right format, line is ignored. Should have 5 parts (line = " + check_line + " - " + str(len(start_line_words))+" parts)")
    test_result = TEST_FAILED

  return test_result

# parse_start_line
# ----------------
# Normal start line looks like: CLUSTERNODE1 21:12:13 - START part2.ps1
def parse_start_line(start_line):

  start_line_words       = start_line.split()
  powershell_script_name = start_line_words[4]

  return_value = { 'powershell_script_name': powershell_script_name }

  return return_value

# process_start_line
# ------------------
def process_start_line(event_data, start_line):

  result = test_start_line(start_line)
  if (result == TEST_PASSED):
    print("TRACE Tests successful")

    # The nodename in the log file doesn't use consistant uppercase/lowercase.
    # The nodename in the log group name (in the event data) has a consistant usage of uppercase/lowercase (and looks nicer in the names of the events as well)
    node_name = get_node_name_from_data(event_data)

    result                 = parse_start_line(start_line)
    powershell_script_name = result["powershell_script_name"]

    event_rule_name = node_name + "-" + powershell_script_name 
    print("TRACE node_name: " + node_name + " - powershell_script_name: " + powershell_script_name)

    try:
      remove_event_target(event_rule_name)
      remove_event_rule(event_rule_name)

      print("TRACE Remove of event target " + event_rule_name + " succesful")
      
    except:
      print("TRACE Remove of target or rule unsuccesful, eventrule " + event_rule_name + " might not exist?")
  else:
    print("TRACE Tests unsuccessful")
    
  return 

# Main program
# ============
def handler(event, context):
  print("START CreateOrDeletePowershellEvent.py")
  print("TRACE Received event: " + json.dumps(event))

  event_data_base64 = base64.b64decode(event["awslogs"]["data"])
  event_data        = json.loads(gzip.decompress(event_data_base64))

  print("TRACE Received data: " + json.dumps(event_data))
  for log_event in event_data["logEvents"]:
    line = log_event["message"]
    print("TRACE Received line: " + line)

    if (line.find("CHECK") >= 0):
      process_check_line(event_data, line)

    if (line.find("START") >= 0):
      process_start_line(event_data, line)

  print("END CreateOrDeletePowershellEvent.py")
  
  return
