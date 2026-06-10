# frozen_string_literal: true

require "aws-sdk-s3"

module AwsHelpers
  LOOKUP_TIMEOUT_SECONDS = 60

  def get_submission_from_s3(submission_reference, form_id)
    bucket = get_submissions_bucket
    started_at = Time.now
    attempts = 0

    loop do
      key = find_submission_key(submission_reference, bucket, form_id)

      if key
        csv = s3_client.get_object(bucket: bucket, key: key)
        delete_from_s3(client, bucket, key)
        return csv.body.read
      end

      elapsed_seconds = Time.now - started_at
      attempts += 1
      if elapsed_seconds >= LOOKUP_TIMEOUT_SECONDS
        raise "Could not find S3 submission file for reference #{submission_reference} after #{attempts} attempts in #{LOOKUP_TIMEOUT_SECONDS}s"
      end

      sleep 1
    end
  end

private

  def s3_client
    @s3_client ||= begin
      credentials = assume_role

      Aws::S3::Client.new(
        region: "eu-west-2",
        credentials: credentials,
      )
    end
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

  def get_submissions_bucket
    # TODO: Update this once we're confident no one is setting $AWS_S3_BUCKET
    # https://trello.com/c/tIYmMZ3e/3457-remove-backwards-compatibility-for-legacy-e2e-test-env-vars
    bucket = Settings.aws.s3_submission_bucket_name || Settings.aws.file_upload_s3_bucket_name || ENV["AWS_S3_BUCKET"]

    raise "Settings.aws.s3_submission_bucket_name is not set" if bucket.nil? || bucket.empty?

    bucket
  end

  def find_submission_key(submission_reference, bucket, form_id)
    objects = s3_client.list_objects({
      bucket: bucket,
      prefix: "form_submissions/#{form_id}/",
    })

    objects.contents.each do |object|
      return object.key if object.key.include? reference_number
    end

    nil
  end

  def delete_from_s3(bucket, key)
    s3_client.delete_object({
      bucket: bucket,
      key: key,
    })
  end
end
