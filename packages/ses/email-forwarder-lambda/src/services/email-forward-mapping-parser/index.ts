import type { EmailForwardMapping } from '@app/types';
import { isObject, isArrayOfStrings } from '@app/utils/common';
import { Service } from '@app/utils/service';

class EmailForwardMappingParserService extends Service {
  public parseForwardMapping(emailForwardMapping: string): EmailForwardMapping {
    this.logger.info('Attempting to parse received email forward mapping');

    try {
      const parsedEmailForwardMapping = JSON.parse(emailForwardMapping);

      this.validateParsedForwardMapping(parsedEmailForwardMapping);

      this.logger.info('Successfully parsed received email forward mapping');

      return parsedEmailForwardMapping;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  private validateParsedForwardMapping(
    forwardMapping: any
  ): asserts forwardMapping is EmailForwardMapping {
    if (!isObject(forwardMapping)) {
      throw Error('Email forward mapping is not an object');
    }

    if (!isArrayOfStrings(Object.keys(forwardMapping))) {
      throw Error('Keys of email forward mapping must be strings');
    }

    if (!Object.values(forwardMapping).every(isArrayOfStrings)) {
      throw Error(
        'Every value of email forward mapping must be a list of strings'
      );
    }
  }
}

export default EmailForwardMappingParserService;
