"""
################################################################################
  save_backup_to_s3.py
################################################################################

Saves a backup file to an s3 bucket. This is backup file specific in how it
names the s3 object key prefix with product, deployment and category.

TODO: Get config values from a yaml config file.
TODO: I'm still thinking about if having a backup-ts tag with a value like
      "20191227164810" is useful. I've removed the option for it for now. -mjl

Syntax:
save_backup_to_s3.py file_to_copy s3_obj_name
e.g. save_backup_to_s3.py backups/mongodb_riff-test.pfm.demo.backup-20191227164810.gz mongodb_riff-test.gz

=============== ================================================================
Created on      December 29, 2019
--------------- ----------------------------------------------------------------
author(s)       Michael Jay Lippert
--------------- ----------------------------------------------------------------
Copyright       (c) 2019 Michael Jay Lippert,
                MIT License (see https://opensource.org/licenses/MIT)
=============== ================================================================
"""

# Standard library imports
import logging

# Third party imports
import boto3
import click
from botocore.exceptions import ClientError

# Local application imports


# We should get these values from a configuration file backup_config.yml
cfg = {
    's3_bucket': 'backups-us-east-2-593547106275',
    'product': 'pfm',
    'deployment': 'demo',
    'category': 'riffdata',
}

@click.command()
@click.option('--bucket', type=str, default=cfg['s3_bucket'], required=False, help='Name of the existing s3 bucket that will contain the new object')
@click.option('--product', type=str, default=cfg['product'], required=False, help='Name of the Riff product that is part of the key prefix, e.g. pfm or edu')
@click.option('--deployment', type=str, default=cfg['deployment'], required=False, help='Name of the Riff deployment that is part of the key prefix, e.g. staging, emeritus')
@click.option('--category', type=str, default=cfg['category'], required=False, help='Name of the category of the backup that is part of the key prefix, e.g. riffdata, mattermost')
@click.argument('filepath', required=True)
@click.argument('s3_obj_name', required=True)
def save_backup(filepath, s3_obj_name, bucket, product, deployment, category):
    """
    Save the FILEPATH file (assumed to be a backup file) to the s3 backup bucket with the
    appropriate object key "<product>/<deployment>/<category>/<s3_obj_name>"

    If the s3 bucket has versioning on then this will create a new version, otherwise it will
    replace any existing object with that key.

    Default values for the bucket, product, deployment and category are read from the
    configuration file.

    \b
    :param filepath: Path to the file to be uploaded
    :param s3_obj_name: Final part of the s3 object key name,
                        e.g. pfm/staging/riffdata/<s3_obj_name>
    """
    s3 = boto3.resource('s3')
    obj_key = f'{product}/{deployment}/{category}/{s3_obj_name}'
    obj = s3.Object(bucket_name=bucket, key=obj_key)

    try:
        obj.upload_file(filepath)
    except FileNotFoundError as e:
        logging.error(e)


def upload_file(file_name, bucket, object_name=None):
    """Upload a file to an S3 bucket

    (from https://boto3.amazonaws.com/v1/documentation/api/latest/guide/s3-uploading-files.html)

    :param file_name: File to upload
    :param bucket: Bucket to upload to
    :param object_name: S3 object name. If not specified then file_name is used
    :return: True if file was uploaded, else False
    """

    # If S3 object_name was not specified, use file_name
    if object_name is None:
        object_name = file_name

    # Upload the file
    s3_client = boto3.client('s3')
    try:
        response = s3_client.upload_file(file_name, bucket, object_name)
    except ClientError as e:
        logging.error(e)
        return False
    return True


if __name__ == "__main__":
    save_backup()
