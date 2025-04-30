import boto3
import time
import json

rds = boto3.client('rds')
secretsmanager = boto3.client('secretsmanager')
autoscaling = boto3.client('autoscaling')

replica_id = "mysql-db-replica"
asg_name = "register-app-pilot-light-asg"
secret_name = "prod/live/degeneral-secret"

def is_already_promoted(db_instance):
    return not db_instance.get('ReadReplicaSourceDBInstanceIdentifier')

def lambda_handler(event, context):
    
    try:
        # Step 1: Describe DB to check status
        print("Checking replica status...")
        db_info = rds.describe_db_instances(DBInstanceIdentifier=replica_id)
        db_instance = db_info["DBInstances"][0]

        if is_already_promoted(db_instance):
            print("Replica is already promoted and available.")
        else:
            print("Promoting replica...")
            try:
                rds.promote_read_replica(DBInstanceIdentifier=replica_id)
            except Exception as e:
                print(f"Promotion might already be in progress or completed: {e}")

            print("Waiting for RDS promotion to complete...")
            waiter = rds.get_waiter('db_instance_available')
            waiter.wait(DBInstanceIdentifier=replica_id, WaiterConfig={'Delay': 120, 'MaxAttempts': 20})
            print("Replica promoted successfully.")

        # Refresh DB info to get updated endpoint
        db_info = rds.describe_db_instances(DBInstanceIdentifier=replica_id)
        endpoint = db_info["DBInstances"][0]["Endpoint"]["Address"]
        print("Endpoint:", endpoint)

        # Step 2: Create/Update Secret
        secret_payload = {
            "DB_USER": "root",
            "DB_PASS": "rootpassword",
            "DB_HOST": endpoint,
            "DB_NAME": "degendb"
        }

        print("Creating or updating secret...")
        secretsmanager.update_secret(
            SecretId=secret_name,
            SecretString=json.dumps(secret_payload)
        )
        print(f"Secret '{secret_name}' updated.")

        # Step 3: Scale ASG
        print("Scaling ASG...")
        autoscaling.update_auto_scaling_group(
            AutoScalingGroupName=asg_name,
            DesiredCapacity=1,
            MinSize=1
        )
        print("ASG scaled up.")

        return {"status": "success", "message": "RDS promoted, secret created, ASG scaled."}

    except Exception as e:
        print("Error:", str(e))
        return {"status": "error", "message": str(e)}
