const isDefined = <T>(value: T): value is NonNullable<T> =>
  value !== undefined && value !== null;

const assertIsDefined = <T>(key: string, value: T): NonNullable<T> => {
  if (!isDefined(value)) {
    throw Error(`Expected ${key} to be defined, but received ${value}`);
  }

  return value;
};

export const validateEnvironment = <T extends Record<string, unknown>>(
  env: T
): Required<T> =>
  Object.entries(env).reduce(
    (previous, [key, value]) => ({
      ...previous,
      [key]: assertIsDefined(key, value)
    }),
    {} as Required<T>
  );

export const isObject = (value: any): boolean =>
  value?.constructor?.name === 'Object';

export const isArrayOfStrings = (array: unknown): array is string[] =>
  Array.isArray(array) && array.every(value => typeof value === 'string');
