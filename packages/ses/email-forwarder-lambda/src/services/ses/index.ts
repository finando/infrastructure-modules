import type { EmailMessageParts } from '@app/types';
import { Service } from '@app/utils/service';

import type { SES } from 'aws-sdk';
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
            Data: this.processMessage(from, source, message)
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

  private processMessage(
    from: string,
    source: string,
    message: string
  ): string {
    const { head, body } = this.splitMessageIntoHeadAndBody(message);

    let processedHead = head;

    if (!/^reply-to:[\t ]?/im.test(processedHead)) {
      const from =
        processedHead.match(/^from:[\t ]?(.*(?:\r?\n\s+.*)*\r?\n)/im)?.[1] ??
        '';

      if (from) {
        processedHead = `${processedHead} Reply-To: ${from}`;
      }
    }

    processedHead = processedHead.replace(
      /^from:[\t ]?(.*(?:\r?\n\s+.*)*)/gim,
      (_, header) => {
        if (from) {
          return `From: ${header.replace(/<(.*)>/, '').trim()} <${from}>`;
        }

        return `From: ${header
          .replace('<', 'at ')
          .replace('>', '')} <${source}>`;
      }
    );

    processedHead = processedHead.replace(
      /^return-path:[\t ]?(.*)\r?\n/gim,
      ''
    );
    processedHead = processedHead.replace(/^sender:[\t ]?(.*)\r?\n/gim, '');
    processedHead = processedHead.replace(/^message-id:[\t ]?(.*)\r?\n/gim, '');
    processedHead = processedHead.replace(
      /^dkim-signature:[\t ]?.*\r?\n(\s+.*\r?\n)*/gim,
      ''
    );

    return processedHead + body;
  }

  private splitMessageIntoHeadAndBody(message: string): EmailMessageParts {
    const parts = message.match(/^((?:.+\r?\n)*)(\r?\n(?:.*\s+)*)/m);

    return {
      head: parts?.[1] ?? message,
      body: parts?.[2] ?? ''
    };
  }
}

export default S3Service;
