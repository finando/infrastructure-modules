import type { Logger } from 'winston';

export abstract class Service {
  constructor(protected readonly logger: Logger) {}

  protected handleError(receivedError: Error | unknown): Error {
    const error =
      receivedError instanceof Error
        ? receivedError
        : Error(`An unknown error occurred: ${receivedError}`);

    this.logger.error(error.message, { error });

    return error;
  }
}
