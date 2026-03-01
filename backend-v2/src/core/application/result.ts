/**
 * Result class for handling success/failure outcomes without exceptions.
 * Use this pattern to make error handling explicit and type-safe.
 */
export class Result<T, E = Error> {
  private readonly _isSuccess: boolean;
  private readonly _value?: T;
  private readonly _error?: E;

  private constructor(isSuccess: boolean, value?: T, error?: E) {
    this._isSuccess = isSuccess;
    this._value = value;
    this._error = error;
  }

  get isSuccess(): boolean {
    return this._isSuccess;
  }

  get isFailure(): boolean {
    return !this._isSuccess;
  }

  get value(): T {
    if (!this._isSuccess) {
      throw new Error('Cannot get value of a failed result');
    }
    return this._value as T;
  }

  get error(): E {
    if (this._isSuccess) {
      throw new Error('Cannot get error of a successful result');
    }
    return this._error as E;
  }

  /**
   * Create a successful result.
   */
  static ok<T, E = Error>(value: T): Result<T, E> {
    return new Result<T, E>(true, value, undefined);
  }

  /**
   * Create a failed result.
   */
  static fail<T, E = Error>(error: E): Result<T, E> {
    return new Result<T, E>(false, undefined, error);
  }

  /**
   * Map the value if successful.
   */
  map<U>(fn: (value: T) => U): Result<U, E> {
    if (this._isSuccess) {
      return Result.ok(fn(this._value as T));
    }
    return Result.fail(this._error as E);
  }

  /**
   * FlatMap for chaining Results.
   */
  flatMap<U>(fn: (value: T) => Result<U, E>): Result<U, E> {
    if (this._isSuccess) {
      return fn(this._value as T);
    }
    return Result.fail(this._error as E);
  }

  /**
   * Get value or default.
   */
  getOrElse(defaultValue: T): T {
    if (this._isSuccess) {
      return this._value as T;
    }
    return defaultValue;
  }

  /**
   * Check if result is successful.
   */
  isOk(): this is Result<T, never> {
    return this._isSuccess;
  }

  /**
   * Check if result is failure.
   */
  isErr(): this is Result<never, E> {
    return !this._isSuccess;
  }
}

/**
 * Helper function to create successful result.
 */
export function ok<T, E = string>(value: T): Result<T, E> {
  return Result.ok(value);
}

/**
 * Helper function to create failed result.
 */
export function err<T, E = string>(error: E): Result<T, E> {
  return Result.fail(error);
}

/**
 * Combine multiple results into one.
 * Returns failure if any result fails, success with all values otherwise.
 */
export function combineResults<T>(results: Result<T>[]): Result<T[]> {
  const values: T[] = [];
  for (const result of results) {
    if (result.isFailure) {
      return Result.fail(result.error);
    }
    values.push(result.value);
  }
  return Result.ok(values);
}
