import os

import boto3
import pytest

from moto import mock_s3


@pytest.fixture
def aws_credentials():
    os.environ.setdefault("AWS_ACCESS_KEY_ID", "fake_access_key")
    os.environ.setdefault("AWS_SECRET_KEY", "fake_secret_key")


@pytest.fixture
def s3_client(aws_credentials):
    with mock_s3():
        con = boto3.client("s3", region_name="eu-west-1")
        yield con


@pytest.fixture
def bucket_name():
    return "my-test-bucket"
