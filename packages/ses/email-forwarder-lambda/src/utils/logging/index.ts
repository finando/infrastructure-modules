import { createLogger, format, transports } from 'winston';

import type { LoggerFactory } from './types';

const { combine, errors, timestamp, json } = format;
const { Console } = transports;

const loggerFactory: LoggerFactory = ({ requestId }) =>
  createLogger({
    format: combine(
      timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
      errors({ stack: true }),
      json()
    ),
    defaultMeta: {
      requestId
    },
    transports: [new Console({ level: 'info' })]
  });

export { loggerFactory };
