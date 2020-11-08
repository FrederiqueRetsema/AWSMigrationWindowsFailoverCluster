import json
import boto3
import time
import os
import logging

SLEEP_IN_SECONDS     = int(os.environ["SLEEP_IN_SECONDS"])
LOGGING_LEVEL_STRING = os.environ["LOGGING_LEVEL"]
LOGGING_FORMAT       = "%(asctime)-15s %(levelname)s %(message)s"

# get_logging_level
# -----------------

def get_logging_level(logging_level_string):

  # Default: INFO
  return_value = logging.INFO

  if (logging_level_string == "DEBUG"):
    return_value = logging.DEBUG
  if (logging_level_string == "WARNING"):
    return_value = logging.WARNING

  return return_value

# get_target_groups_arns
# ----------------------
def get_target_group_arns():

  return_value = []

  elbv2 = boto3.client("elbv2")
  response = elbv2.describe_target_groups()
  logging.debug("response from describe_target_groups: "+str(response))
 
  target_groups = response["TargetGroups"]
  for target_group in target_groups:
    return_value.append(target_group["TargetGroupArn"])

  logging.info("Target group arns: "+str(return_value))

  return return_value

# get_instance_ids
# ----------------
def get_instance_ids_of_unhealthy_nodes(target_group_arn):

  return_value = []

  elbv2 = boto3.client("elbv2")
  response = elbv2.describe_target_health(
    TargetGroupArn = target_group_arn
  )
  logging.debug("response from describe_target_health: "+str(response))

  target_health_descriptions = response["TargetHealthDescriptions"]
  for target in target_health_descriptions:

      if (target["TargetHealth"]["State"] not in ("healthy", 'initial')):

          target_id          = target["Target"]["Id"]
          target_state       = target["TargetHealth"]["State"]
          target_reason      = target["TargetHealth"]["Reason"]
          target_description = target["TargetHealth"]["Description"]
          
          return_value.append(target_id)
          logging.warning(f"{target_id}: state = {target_state}, reason = {target_reason}, description = {target_description}")

  logging.info("instance_ids of unhealthy nodes in target_group_arn "+target_group_arn+" = "+str(return_value))

  return return_value

# get_asg_name_from_instance_tags
# -------------------------------
def get_asg_name_from_instance_tags(instance_id):

  ec2 = boto3.client("ec2")
  response = ec2.describe_instances(
    InstanceIds = [instance_id]
  )
  logging.debug("response from describe_instances: "+str(response))

  tags          = response["Reservations"][0]["Instances"][0]["Tags"]
  tags_mappings = { tag["Key"] : tag["Value"] for tag in tags }
  
  asg_name = tags_mappings["aws:autoscaling:groupName"]
  logging.info("asg_name from instance " + instance_id + " = " + asg_name)

  return asg_name

# get_asg_health_check_type
# -------------------------
def get_asg_health_check_type(asg_name):

  autoscaling = boto3.client("autoscaling")
  response = autoscaling.describe_auto_scaling_groups(
    AutoScalingGroupNames = [asg_name]
  )
  logging.debug("response from describe_auto_scaling_groups: "+str(response))

  asg_health_check_type = response["AutoScalingGroups"][0]["HealthCheckType"]
  logging.info("asg_health_check_type of " + asg_name + " = " + asg_health_check_type)

  return asg_health_check_type

# change_instance_health
def change_instance_health(instance_id):

  autoscaling = boto3.client("autoscaling")
  autoscaling.set_instance_health(
    InstanceId = instance_id,
    HealthStatus = "Unhealthy",
    ShouldRespectGracePeriod = False
  )
  logging.warning("Changed health status of instance " + instance_id + " to Unhealthy")

  return

# Main program
# ============

LOGGING_LEVEL = get_logging_level(LOGGING_LEVEL_STRING)
logging.basicConfig(format=LOGGING_FORMAT, level=LOGGING_LEVEL)

logging.info("START elb_to_asg_health_status.py")

while (True):
    target_group_arns = get_target_group_arns()

    for target_group_arn in target_group_arns:
        instance_ids = get_instance_ids_of_unhealthy_nodes(target_group_arn)

        for instance_id in instance_ids:
            asg_name = get_asg_name_from_instance_tags(instance_id)
            asg_health_check_type = get_asg_health_check_type(asg_name) 

            if (asg_health_check_type == "ELB"):
                change_instance_health(instance_id)

    time.sleep(SLEEP_IN_SECONDS)
