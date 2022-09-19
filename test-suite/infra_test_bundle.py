import unittest

import boto3
from botocore.exceptions import ClientError


class TestIAMPermissions(unittest.TestCase):

    def setUp(self) -> None:
        self.s3 = boto3.client(
            "s3",
            region_name="eu-west-1",
            aws_access_key_id="fake_access_key",
            aws_secret_access_key="fake_secret_key",
        )

    def test_something(self):
        self.assertEqual(True, False)  # add assertion here


if __name__ == '__main__':
    unittest.main()
