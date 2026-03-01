/**
 * Base Aggregate Root class.
 * Aggregate roots are entities that serve as the entry point
 * for a cluster of domain objects (aggregate).
 * All changes to the aggregate must go through the root.
 */
import { Entity, UniqueEntityId } from './entity.base';

export interface DomainEvent {
  readonly occurredOn: Date;
  readonly aggregateId: string;
  readonly eventType: string;
}

export abstract class AggregateRoot<T> extends Entity<T> {
  private _domainEvents: DomainEvent[] = [];

  get domainEvents(): DomainEvent[] {
    return [...this._domainEvents];
  }

  protected addDomainEvent(event: DomainEvent): void {
    this._domainEvents.push(event);
  }

  public clearEvents(): void {
    this._domainEvents = [];
  }
}
