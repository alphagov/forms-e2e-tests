# frozen_string_literal: true

require "aws-sdk-s3"

module AwsHelpers
  LOOKUP_TIMEOUT_SECONDS = 60

  def get_file_from_s3(submission_reference, form_id)
    bucket = get_submissions_bucket
    started_at = Time.now
    attempts = 0

    loop do
      key = find_key(submission_reference, bucket, form_id)

      if key
        csv = s3_client.get_object(bucket: bucket, key: key)
        delete_from_s3(bucket, key)
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

  def wait_for_copy_of_answers_email(submission_reference)
    prefix = "copy-of-answers-emails/"
    email_match_string = "Your form reference number is #{submission_reference}"
    wait_for_ses_email_delivered_to_s3(prefix, email_match_string, submission_reference)
  end

  def wait_for_ses_email_delivered_to_s3(prefix, email_match_string, submission_reference)
    bucket = Settings.aws.email_receiver_s3_bucket_name
    started_at = Time.now
    attempts = 0

    check_objects_modified_after = Time.now - 30 # 30 seconds ago
    checked_keys = Set.new

    loop do
      # list_objects_v2 returns a maximum of 1000 keys per request, use the enumerator to handle pagination
      s3_client.list_objects_v2(bucket: bucket, prefix: prefix).each do |response|
        response.contents.each do |object_metadata|
          key = object_metadata.key
          next if object_metadata.last_modified < check_objects_modified_after
          next if checked_keys.include?(key)

          object = s3_client.get_object(bucket: bucket, key: key)
          body = object.body.read
          if body.include?(email_match_string)
            delete_from_s3(bucket, key)
            return body
          end

          checked_keys.add(key)
        end
      end

      elapsed_seconds = Time.now - started_at
      attempts += 1
      if elapsed_seconds >= LOOKUP_TIMEOUT_SECONDS
        raise "Could not find email in #{bucket} S3 bucket with key prefix #{prefix} for submission #{submission_reference} after #{attempts} attempts in #{LOOKUP_TIMEOUT_SECONDS}s"
      end

      sleep 1
    end
  end

private

  def s3_client
    return @s3_client if @s3_client

    credentials = assume_role
    @s3_client = Aws::S3::Client.new(
      region: "eu-west-2",
      credentials: credentials,
    )
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
    bucket = Settings.aws.file_upload_s3_bucket_name || ENV["AWS_S3_BUCKET"]

    raise "Settings.aws.file_upload_s3_bucket_name is not set" if bucket.nil? || bucket.empty?

    bucket
  end

  def find_key(submission_reference, bucket, form_id)
    # list_objects_v2 returns a maximum of 1000 keys per request, use the enumerator to handle pagination
    s3_client.list_objects_v2(bucket: bucket, prefix: "form_submissions/#{form_id}/").each do |response|
      response.contents.each do |object|
        return object.key if object.key.include? submission_reference
      end
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
