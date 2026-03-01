import { Entity } from '../../../../core/domain/entity.base';

export interface ProductProps {
  sellerId?: string;
  title: string;
  price: string;
  imageUrl: string;
  description: string;
  badge?: string;
  category: string;
  order: number;
  externalUrl?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export class ProductEntity extends Entity<string> {
  private props: ProductProps;

  private constructor(id: string, props: ProductProps) {
    super(id);
    this.props = props;
  }

  static create(props: ProductProps, id?: string): ProductEntity {
    return new ProductEntity(id ?? Entity.generateId(), {
      ...props,
      description: props.description ?? '',
      category: props.category ?? 'all',
      order: props.order ?? 0,
      createdAt: props.createdAt ?? new Date(),
      updatedAt: props.updatedAt ?? new Date(),
    });
  }

  static reconstitute(id: string, props: ProductProps): ProductEntity {
    return new ProductEntity(id, props);
  }

  get sellerId(): string | undefined { return this.props.sellerId; }
  get title(): string { return this.props.title; }
  get price(): string { return this.props.price; }
  get imageUrl(): string { return this.props.imageUrl; }
  get description(): string { return this.props.description; }
  get badge(): string | undefined { return this.props.badge; }
  get category(): string { return this.props.category; }
  get order(): number { return this.props.order; }
  get externalUrl(): string | undefined { return this.props.externalUrl; }
  get createdAt(): Date | undefined { return this.props.createdAt; }
  get updatedAt(): Date | undefined { return this.props.updatedAt; }

  toObject(): ProductProps & { id: string } {
    return { id: this.id, ...this.props };
  }
}

export interface ReviewProps {
  productId: string;
  userId: string;
  userName: string;
  rating: number;
  comment: string;
  userProfileImageUrl?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export class ReviewEntity extends Entity<string> {
  private props: ReviewProps;

  private constructor(id: string, props: ReviewProps) {
    super(id);
    this.props = props;
  }

  static create(props: ReviewProps, id?: string): ReviewEntity {
    if (props.rating < 1 || props.rating > 5) throw new Error('Rating must be 1-5');
    return new ReviewEntity(id ?? Entity.generateId(), {
      ...props,
      comment: props.comment ?? '',
      createdAt: props.createdAt ?? new Date(),
      updatedAt: props.updatedAt ?? new Date(),
    });
  }

  static reconstitute(id: string, props: ReviewProps): ReviewEntity {
    return new ReviewEntity(id, props);
  }

  get productId(): string { return this.props.productId; }
  get userId(): string { return this.props.userId; }
  get userName(): string { return this.props.userName; }
  get rating(): number { return this.props.rating; }
  get comment(): string { return this.props.comment; }
  get userProfileImageUrl(): string | undefined { return this.props.userProfileImageUrl; }
  get createdAt(): Date | undefined { return this.props.createdAt; }
  get updatedAt(): Date | undefined { return this.props.updatedAt; }

  updateRating(rating: number, comment?: string): void {
    if (rating < 1 || rating > 5) throw new Error('Rating must be 1-5');
    this.props.rating = rating;
    if (comment !== undefined) this.props.comment = comment;
    this.props.updatedAt = new Date();
  }

  toObject(): ReviewProps & { id: string } {
    return { id: this.id, ...this.props };
  }
}
