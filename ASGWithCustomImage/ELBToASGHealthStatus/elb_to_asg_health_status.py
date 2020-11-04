import json
import boto3
import time
import os

SLEEP_IN_SECONDS = os.environ["SLEEP_IN_SECONDS"]

# get_target_groups_arns
# ----------------------
def get_target_group_arns():

  return_value = []

  elbv2 = boto3.client("elbv2")
  response = elbv2.describe_target_groups()
  #  print("TRACE response from describe_target_groups: "+str(response))
 
  target_groups = response["TargetGroups"]
  for target_group in target_groups:
    return_value.append(target_group["TargetGroupArn"])

  return return_value

# get_instance_ids
# ----------------
def get_instance_ids_of_unhealthy_nodes(target_group_arn):

  return_value = []

  elbv2 = boto3.client("elbv2")
  response = elbv2.describe_target_health(
    TargetGroupArn = target_group_arn
  )
  #  print("TRACE response from describe_target_health: "+str(response))
  target_health_descriptions = response["TargetHealthDescriptions"]
  return_value = []
  for target in target_health_descriptions:
      if (target["TargetHealth"]["State"] not in ("healthy", 'initial')):
          target_id = target["Target"]["Id"]
          target_state = target["TargetHealth"]["State"]
          target_reason = target["TargetHealth"]["Reason"]
          target_description = target["TargetHealth"]["Description"]
          
          return_value.append(target_id)
          print(f"TRACE {target_id}: state = {target_state}, reason = {target_reason}, description = {target_description}")

  return return_value

# get_asg_name_from_instance_tags
# -------------------------------
def get_asg_name_from_instance_tags(instance_id):

  ec2 = boto3.client("ec2")
  response = ec2.describe_instances(
    InstanceIds = [instance_id]
  )
  #  print("TRACE response from describe_instances: "+str(response))
  tags = response["Reservations"][0]["Instances"][0]["Tags"]
  tags_mappings = { tag["Key"] : tag["Value"] for tag in tags }
  
  return tags_mappings["aws:autoscaling:groupName"]

# get_asg_health_check_type
# -------------------------
def get_asg_health_check_type(asg_name):

  autoscaling = boto3.client("autoscaling")
  response = autoscaling.describe_auto_scaling_groups(
    AutoScalingGroupNames = [asg_name]
  )
  # print("TRACE response from describe_auto_scaling_groups: "+str(response))

  return response["AutoScalingGroups"][0]["HealthCheckType"]

# change_instance_health
def change_instance_health(instance_id):

  autoscaling = boto3.client("autoscaling")
  autoscaling.set_instance_health(
    InstanceId = instance_id,
    HealthStatus = "Unhealthy",
    ShouldRespectGracePeriod = False
  )
  print("TRACE End of set_instance_health")

  return

# Main program
# ============
print("START faster_healthchecks.py")

boto3.setup_default_session(profile_name="la")

while (True):
    target_group_arns = get_target_group_arns()
    print("TRACE Target group arns: "+str(target_group_arns))

    for target_group_arn in target_group_arns:
        instance_ids = get_instance_ids_of_unhealthy_nodes(target_group_arn)
        print("TRACE instance_ids of target_group_arn "+target_group_arn+" = "+str(instance_ids))
        for instance_id in instance_ids:
            asg_name = get_asg_name_from_instance_tags(instance_id)
            print("TRACE asg_name from instance "+instance_id+" = "+asg_name)
            asg_health_check_type = get_asg_health_check_type(asg_name) 
            if (asg_health_check_type == "ELB"):
                print("TRACE asg_health_check_type = "+asg_health_check_type+", change instance health now at "+time.asctime())
                change_instance_health(instance_id)
    time.sleep(SLEEP_IN_SECONDS)
  
print("END faster_healthchecks.py")
