import { context } from '@app/context';
import { environement } from '@app/env';

import type { SESHandler } from 'aws-lambda';

export const handler: SESHandler = async (
  event,
  { awsRequestId: requestId }
) => {
  const {
    FROM_EMAIL_ADDRESS: fromEmailAddress,
    BUCKET_NAME: bucketName,
    EMAIL_MAPPING: emailMapping
  } = environement();

  const { eventParser, forwardMappingParser, s3, ses } = context({ requestId });

  const emailForwardMapping =
    forwardMappingParser.parseForwardMapping(emailMapping);

  const {
    source,
    destinations,
    email: { messageId: bucketKey }
  } = eventParser.parseEvent(event, emailForwardMapping);

  const message = await s3.getObjectAsString(bucketName, bucketKey);

  await ses.sendEmail(fromEmailAddress, source, destinations, message);
};
