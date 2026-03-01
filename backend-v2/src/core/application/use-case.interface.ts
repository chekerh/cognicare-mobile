/**
 * Base Use Case interface.
 * All use cases implement this interface with specific input/output types.
 * Use cases represent application business operations.
 */
export interface IUseCase<TInput, TOutput> {
  execute(input: TInput): Promise<TOutput>;
}

/**
 * Base abstract class for use cases with common functionality.
 */
export abstract class UseCase<TInput, TOutput> implements IUseCase<TInput, TOutput> {
  abstract execute(input: TInput): Promise<TOutput>;
}

/**
 * Use case with no input.
 */
export interface IUseCaseNoInput<TOutput> {
  execute(): Promise<TOutput>;
}
