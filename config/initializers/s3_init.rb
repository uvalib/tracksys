require 'aws-sdk-s3'

Aws.config.update({
  region: "us-east-1",
  credentials: Aws::Credentials.new( Settings.aws_key, Settings.aws_secret)
})
