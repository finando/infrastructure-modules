import { Service } from '@app/utils/service';

import type { S3 } from 'aws-sdk';
import type { Logger } from 'winston';

class S3Service extends Service {
  constructor(private readonly s3: S3, protected readonly logger: Logger) {
    super(logger);
  }

  public async getObject(
    bucket: string,
    key: string
  ): Promise<S3.GetObjectOutput> {
    this.logger.info(
      `Attempting to fetched object with key: ${key} from bucket: ${bucket}`
    );

    try {
      const object = await this.s3
        .getObject({ Bucket: bucket, Key: key })
        .promise();

      this.logger.info(
        `Successfully fetched object with key: ${key} from bucket: ${bucket}`
      );

      return object;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  public async getObjectAsString(bucket: string, key: string): Promise<string> {
    try {
      const { Body: body } = await this.getObject(bucket, key);

      if (!body) {
        throw Error(
          `Fetched S3 object from bucket: ${bucket} and key: ${key} does not have a body`
        );
      }

      return body.toString();
    } catch (error) {
      throw this.handleError(error);
    }
  }
}

export default S3Service;
