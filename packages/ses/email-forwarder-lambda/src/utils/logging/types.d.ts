import type { Logger } from 'winston';

interface LoggerOptions {
  requestId: string;
}

type Factory<Options, Output> = (options: Options) => Output;

export type LoggerFactory = Factory<LoggerOptions, Logger>;
