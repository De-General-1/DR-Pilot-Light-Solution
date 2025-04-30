import boto3
import pymysql
import gzip
import io
from datetime import datetime
import json

# Initialize boto3 clients
s3 = boto3.client('s3')
secretsmanager = boto3.client('secretsmanager')

s3_bucket = 'degen-primary-app-bucket'  
secret_name = 'prod/live/degeneral-secret' 

def lambda_handler(event, context):
    try:
        #  Fetch credentials from Secrets Manager
        secret_response = secretsmanager.get_secret_value(SecretId=secret_name)
        secret_data = json.loads(secret_response['SecretString'])

        db_host = secret_data['DB_HOST']
        db_user = secret_data['DB_USER']
        db_password = secret_data['DB_PASS']
        db_name = secret_data['DB_NAME']

        timestamp = datetime.utcnow().strftime('%Y-%m-%d-%H-%M-%S')
        filename = f"{db_name}-backup-{timestamp}.sql"

        # Connect to the database
        conn = pymysql.connect(host=db_host, user=db_user, password=db_password, database=db_name)
        cursor = conn.cursor()

        #  Run backup
        cursor.execute("SHOW TABLES;")
        tables = [row[0] for row in cursor.fetchall()]

        backup_data = ""

        for table in tables:
            cursor.execute(f"SHOW CREATE TABLE `{table}`;")
            create_table_sql = cursor.fetchone()[1]
            backup_data += f"{create_table_sql};\n\n"

            cursor.execute(f"SELECT * FROM `{table}`;")
            rows = cursor.fetchall()
            for row in rows:
                row_values = ', '.join(
                    "'{}'".format(str(value).replace("'", "\\'")) if value is not None else 'NULL'
                    for value in row
                )
                backup_data += f"INSERT INTO `{table}` VALUES ({row_values});\n"
                backup_data += "\n"


        # Compress the backup data
        compressed_buffer = io.BytesIO()
        with gzip.GzipFile(fileobj=compressed_buffer, mode='wb') as gz:
            gz.write(backup_data.encode('utf-8'))

        compressed_buffer.seek(0) 

        
        # Upload to S3
        s3.put_object(
            Bucket=s3_bucket,
            Key=f"backups/{filename}",
            Body=backup_data.encode('utf-8')
        )

        print(f"Backup successful! Uploaded {filename} to S3.")

        return {
            'statusCode': 200,
            'body': f"Backup successful! Uploaded {filename} to S3."
        }

    except Exception as e:
        print(f"Error: {e}")
        return {
            'statusCode': 500,
            'body': str(e)
        }
