import type { EmailForwardMapping, ForwardEvent } from '@app/types';
import { Service } from '@app/utils/service';

import type RecipientTransformerService from '../recipient-transformer';
import type { SESEvent, SESEventRecord } from 'aws-lambda';
import type { Logger } from 'winston';

class EventParserService extends Service {
  constructor(
    private readonly recipientTransformer: RecipientTransformerService,
    protected readonly logger: Logger
  ) {
    super(logger);
  }

  public parseEvent(
    { Records: [record] = [] }: SESEvent,
    emailForwardMapping: EmailForwardMapping
  ): ForwardEvent {
    this.logger.info('Attempting to parse received SES event');

    try {
      this.validateSESEventRecord(record);

      const {
        ses: {
          mail: email,
          receipt: { recipients }
        }
      } = record;

      const { source, destinations } =
        this.recipientTransformer.extractEmailForwardingInformation(
          recipients,
          emailForwardMapping
        );

      this.logger.info('Successfully parsed SES event');

      return {
        email,
        source,
        destinations
      };
    } catch (error) {
      throw this.handleError(error);
    }
  }

  private validateSESEventRecord(
    record?: SESEventRecord
  ): asserts record is NonNullable<SESEventRecord> {
    if (!record) {
      throw Error('Received invalid SES message');
    }

    if (record.eventSource !== 'aws:ses') {
      throw Error(`Invalid SES event source (received: ${record.eventSource})`);
    }

    if (record.eventVersion !== '1.0') {
      throw Error(
        `Invalid SES event version (received: ${record.eventVersion})`
      );
    }
  }
}

export default EventParserService;
