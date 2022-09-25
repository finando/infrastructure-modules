import { env } from 'process';

import type { EnvironmentVariables } from '@app/types';
import { validateEnvironment } from '@app/utils/common';

export const environement = () => {
  const { FROM_EMAIL_ADDRESS, BUCKET_NAME, EMAIL_MAPPING } = env;

  return validateEnvironment<Partial<EnvironmentVariables>>({
    FROM_EMAIL_ADDRESS,
    BUCKET_NAME,
    EMAIL_MAPPING
  });
};
