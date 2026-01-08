# frozen_string_literal: true

require "aws-sdk-s3"

module AwsHelpers
  def get_file_from_s3(reference_number, form_id)
    credentials = assume_role
    client = Aws::S3::Client.new(
      region: "eu-west-2",
      credentials: credentials,
    )

    bucket = get_bucket
    key = find_key(client, reference_number, bucket, form_id)

    csv = client.get_object(bucket: bucket, key: key)
    delete_file_from_s3(client, bucket, key)
    csv.body.read
  end

  def assume_role
    @role_arn = Settings.aws.s3_submission_iam_role_arn

    raise "Settings.aws.s3_submission_iam_role_arn is not set" if @role_arn.nil? || @role_arn.empty?

    role_session_name = "forms-e2e"
    Aws::AssumeRoleCredentials.new(
      client: Aws::STS::Client.new,
      role_arn: @role_arn,
      role_session_name:,
    )
  end

  def get_bucket
    # TODO: Update this once we're confident no one is setting $AWS_S3_BUCKET
    bucket = Settings.aws.file_upload_s3_bucket_name || ENV["AWS_S3_BUCKET"]

    raise "Settings.aws.file_upload_s3_bucket_name is not set" if bucket.nil? || bucket.empty?

    bucket
  end

  def find_key(client, reference_number, bucket, form_id)
    objects = client.list_objects({
      bucket: bucket,
      prefix: "form_submissions/#{form_id}/",
    })

    objects.contents.each do |object|
      return object.key if object.key.include? reference_number
    end
  end

  def delete_file_from_s3(client, bucket, key)
    client.delete_object({
      bucket: bucket,
      key: key,
    })
  end
end
