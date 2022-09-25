import { S3, SES } from 'aws-sdk';

import EmailForwardMappingParserService from '@app/services/email-forward-mapping-parser';
import EventParserService from '@app/services/event-parser';
import RecipientTransformerService from '@app/services/recipient-transformer';
import S3Service from '@app/services/s3';
import SESService from '@app/services/ses';
import type { ContextConfiguration } from '@app/types';
import { loggerFactory } from '@app/utils/logging';

export const context = ({ requestId }: ContextConfiguration) => {
  const logger = loggerFactory({ requestId });
  const forwardMappingParser = new EmailForwardMappingParserService(logger);
  const recipientTransformer = new RecipientTransformerService(logger);
  const eventParser = new EventParserService(recipientTransformer, logger);
  const s3 = new S3Service(new S3({ signatureVersion: 'v4' }), logger);
  const ses = new SESService(new SES(), logger);

  return {
    eventParser,
    forwardMappingParser,
    recipientTransformer,
    s3,
    ses
  };
};
