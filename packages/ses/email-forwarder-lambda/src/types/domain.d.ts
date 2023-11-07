import type { SESMail } from 'aws-lambda';

export interface EmailForwardMapping {
  [key: string]: string[];
}

export interface EmailForwardingInformation {
  source: string;
  destinations: string[];
}

export interface ForwardEvent {
  email: SESMail;
  source: EmailForwardingInformation['source'];
  destinations: EmailForwardingInformation['destinations'];
}
