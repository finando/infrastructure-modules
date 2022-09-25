import type {
  EmailForwardMapping,
  EmailForwardingInformation
} from '@app/types';
import { Service } from '@app/utils/service';

class RecipientTransformerService extends Service {
  public extractEmailForwardingInformation(
    recipients: string[],
    emailForwardMapping: EmailForwardMapping
  ): EmailForwardingInformation {
    this.logger.info('Attempting to extract email forwarding information');

    try {
      const emailForwardingInformation =
        recipients
          .map(recipient => recipient.toLowerCase())
          .map(recipient => recipient.replace(/\+.*?@/, '@'))
          .map(this.findMatchingEmailForwardingInformation(emailForwardMapping))
          .filter(Boolean)
          .shift() ?? null;

      if (!emailForwardingInformation) {
        throw Error('Failed to extract email forwarding information');
      }

      if (!emailForwardingInformation.source) {
        throw Error(
          'No email forwarding source found for a given email forward mapping'
        );
      }

      if (!emailForwardingInformation.destinations.length) {
        throw Error(
          'No email forwarding destinations found for a given email forward mapping'
        );
      }

      this.logger.info('Successfully extracted email forwarding information');

      return emailForwardingInformation;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  private findMatchingEmailForwardingInformation(
    emailForwardMapping: EmailForwardMapping
  ): (recipient: string) => EmailForwardingInformation | null {
    return recipient => {
      if (recipient in emailForwardMapping) {
        return {
          source: recipient,
          destinations: emailForwardMapping[recipient] ?? []
        };
      }

      const atSymbolIndex = recipient.lastIndexOf('@');

      const emailUser =
        atSymbolIndex === -1 ? recipient : recipient.slice(0, atSymbolIndex);
      const emailDomain =
        atSymbolIndex === -1 ? null : recipient.slice(atSymbolIndex);

      if (
        (emailDomain && emailDomain in emailForwardMapping) ||
        (emailUser && emailUser in emailForwardMapping) ||
        '@' in emailForwardMapping
      ) {
        return {
          source: recipient,
          destinations:
            (emailDomain ? emailForwardMapping[emailDomain] : null) ??
            emailForwardMapping[emailUser] ??
            emailForwardMapping['@'] ??
            []
        };
      }

      return null;
    };
  }
}

export default RecipientTransformerService;
