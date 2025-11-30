# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Time Bucket API',
        version: 'v1',
        description: 'API documentation for Time Bucket application - A life planning tool to manage goals across different time periods',
        contact: {
          name: 'Time Bucket Development Team',
          url: 'https://github.com/yminamiyama/time-bucket'
        }
      },
      paths: {},
      servers: [
        {
          url: 'http://localhost:4000',
          description: 'Development server'
        },
        {
          url: 'https://{defaultHost}',
          description: 'Production server',
          variables: {
            defaultHost: {
              default: 'api.timebucket.example.com'
            }
          }
        }
      ],
      components: {
        schemas: {
          User: {
            type: 'object',
            properties: {
              id: { type: 'string', format: 'uuid' },
              email: { type: 'string', format: 'email' },
              birthdate: { type: 'string', format: 'date' },
              current_age: { type: 'integer' },
              timezone: { type: 'string' },
              provider: { type: 'string', example: 'google_oauth2' }
            }
          },
          TimeBucket: {
            type: 'object',
            properties: {
              id: { type: 'string', format: 'uuid' },
              user_id: { type: 'string', format: 'uuid' },
              start_age: { type: 'integer' },
              end_age: { type: 'integer' },
              granularity: { type: 'string', enum: ['5y', '10y'] },
              position: { type: 'integer' },
              description: { type: 'string', nullable: true },
              created_at: { type: 'string', format: 'date-time' },
              updated_at: { type: 'string', format: 'date-time' }
            }
          },
          BucketItem: {
            type: 'object',
            properties: {
              id: { type: 'string', format: 'uuid' },
              time_bucket_id: { type: 'string', format: 'uuid' },
              title: { type: 'string' },
              category: { type: 'string', enum: ['travel', 'career', 'family', 'finance', 'health', 'learning', 'other'] },
              value_statement: { type: 'string' },
              difficulty: { type: 'string', enum: ['easy', 'medium', 'hard'], nullable: true },
              risk_level: { type: 'string', enum: ['low', 'medium', 'high'], nullable: true },
              estimated_cost: { type: 'number', nullable: true },
              target_year: { type: 'integer', nullable: true },
              status: { type: 'string', enum: ['planned', 'in_progress', 'done'], default: 'planned' },
              completed_at: { type: 'string', format: 'date-time', nullable: true },
              created_at: { type: 'string', format: 'date-time' },
              updated_at: { type: 'string', format: 'date-time' }
            }
          },
          NotificationPreference: {
            type: 'object',
            properties: {
              email_enabled: { type: 'boolean' },
              slack_webhook_url: { type: 'string', format: 'uri', nullable: true },
              digest_time: { type: 'string', pattern: '^([01]\\d|2[0-3]):[0-5]\\d$' },
              events: { type: 'object' }
            }
          },
          Error: {
            type: 'object',
            properties: {
              error: { type: 'string' }
            }
          },
          ValidationError: {
            type: 'object',
            properties: {
              errors: {
                type: 'array',
                items: { type: 'string' }
              }
            }
          }
        }
      },
      security: [
        { cookie_auth: [] }
      ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
