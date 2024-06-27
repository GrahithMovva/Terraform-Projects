import boto3
import json
import os
import string
import random
import pymysql

def generate_random_password(length=16):
    """Generates a random password with the given length."""
    characters = string.ascii_letters + string.digits + string.punctuation
    random_password = ''.join(random.choice(characters) for i in range(length))
    return random_password

def rotate_secret(secret_name):
    """Retrieves the current secret and updates it with a new password."""
    client = boto3.client('secretsmanager')
    
    # Retrieve the current secret value
    get_secret_value_response = client.get_secret_value(SecretId=secret_name)
    current_secret = json.loads(get_secret_value_response['SecretString'])
    
    # Generate a new password
    new_password = generate_random_password()
    
    # Update the secret with the new password
    current_secret['password'] = new_password
    
    # Store the updated secret value
    client.put_secret_value(
        SecretId=secret_name,
        SecretString=json.dumps(current_secret)
    )
    
    return new_password

def lambda_SM_handler(event, context):
    secret_name = os.getenv('SECRET_NAME')
    
    if not secret_name:
        raise ValueError("SECRET_NAME environment variable is not set")
    
    try:
        new_password = rotate_secret(secret_name)
        return {
            'statusCode': 200,
            'body': json.dumps(f"Password rotated successfully: {new_password}")
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error rotating password: {str(e)}")
        }

def get_db_credentials(secret_name):
    # Create a Secrets Manager client
    client = boto3.client('secretsmanager')

    try:
        # Retrieve the secret value
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
        secret = get_secret_value_response['SecretString']
        return json.loads(secret)
    except Exception as e:
        print(f"Error retrieving secret {secret_name}: {str(e)}")
        raise e

def lambda_RDS_handler(event, context):
    # Secret name and region
    secret_name = os.getenv('SECRET_NAME')
    region_name = os.getenv('REGION_NAME')
    host = os.getenv("DB_HOST")


    credentials = get_db_credentials(secret_name)


    db_host = credentials['host']
    db_username = credentials['username']
    db_password = credentials['password']
    db_name = credentials['dbname']
    db_port = 3306

    connection = pymysql.connect(
        host=db_host,
        user=db_username,
        password=db_password,
        database=db_name,
        port=db_port
    )

    try:
        with connection.cursor() as cursor:
            # Example query to insert data
            sql = "INSERT INTO your_table (column1, column2) VALUES (%s, %s)"
            cursor.execute(sql, ('value1', 'value2'))
        connection.commit()
    finally:
        connection.close()

    return {
        'statusCode': 200,
        'body': json.dumps('Data inserted successfully!')
    }

def lambda_RDS_handler_verneMQ(event, context):
    # Secret name and region
    secret_name = os.getenv('SECRET_NAME')
    region_name = os.getenv('REGION_NAME')
    host = os.getenv("DB_HOST")


    credentials = get_db_credentials(secret_name)


    db_host = credentials['host']
    db_username = credentials['username']
    db_password = credentials['password']
    db_name = credentials['dbname']
    db_port = 3306

    connection = pymysql.connect(
        host=db_host,
        user=db_username,
        password=db_password,
        database=db_name,
        port=db_port
    )

    try:
        with connection.cursor() as cursor:
            # Example query to insert data
            sql = "INSERT INTO your_table (column1, column2) VALUES (%s, %s)"
            cursor.execute(sql, ('value1', 'value2'))
        connection.commit()
    finally:
        connection.close()

    return {
        'statusCode': 200,
        'body': json.dumps('Data inserted successfully!')
    }