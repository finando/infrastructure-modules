import { simpleParser } from 'mailparser';

import { Service } from '@app/utils/service';

import type { SES } from 'aws-sdk';
import type { AddressObject } from 'mailparser';
import type { Logger } from 'winston';

class S3Service extends Service {
  constructor(private readonly ses: SES, protected readonly logger: Logger) {
    super(logger);
  }

  public async sendEmail(
    from: string,
    source: string,
    destinations: string[],
    message: string
  ): Promise<SES.SendRawEmailResponse> {
    this.logger.info(
      `Attempting to send email source: ${source} destinations: ${destinations.join(
        ', '
      )}`
    );

    try {
      const response = await this.ses
        .sendRawEmail({
          Source: source,
          Destinations: destinations,
          RawMessage: {
            Data: await this.processMessage(from, message)
          }
        })
        .promise();

      this.logger.info(
        `Successfully sent email source: ${source} destinations: ${destinations.join(
          ', '
        )}`
      );

      return response;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  private async processMessage(from: string, message: string): Promise<string> {
    const { headerLines, headers } = await simpleParser(message);

    const headersToRemove = [
      'from',
      'return-path',
      'sender',
      'message-id',
      'dkim-signature'
    ];

    let processedMessage = headerLines
      .filter(({ key }) => headersToRemove.includes(key))
      .reduce(
        (previous, current) =>
          previous.includes(current.line)
            ? previous
                .split(current.line)
                .map(value => value.trim())
                .join('')
            : previous,
        message
      );

    if (headers.has('from')) {
      const { text } = headers.get('from') as AddressObject;

      console.log(from);

      if (!headers.has('reply-to')) {
        processedMessage = `Reply-To: ${text}\n${processedMessage}`;
      }

      processedMessage = `From: ${text
        .replace(/<(.*)>/, `<${from}>`)
        .trim()}\n${processedMessage}`;
    }

    return processedMessage;
  }
}

export default S3Service;
