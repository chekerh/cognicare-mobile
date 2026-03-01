import { Entity } from "../../../../core/domain/entity.base";

export interface CommentProps {
  postId: string;
  authorId: string;
  authorName: string;
  text: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export class CommentEntity extends Entity<string> {
  private props: CommentProps;

  private constructor(id: string, props: CommentProps) {
    super(id);
    this.props = props;
  }

  static create(props: CommentProps, id?: string): CommentEntity {
    if (!props.text || props.text.trim().length === 0) {
      throw new Error("Comment text is required");
    }
    return new CommentEntity(id ?? Entity.generateId(), {
      ...props,
      text: props.text.trim(),
      createdAt: props.createdAt ?? new Date(),
      updatedAt: props.updatedAt ?? new Date(),
    });
  }

  static reconstitute(id: string, props: CommentProps): CommentEntity {
    return new CommentEntity(id, props);
  }

  get postId(): string {
    return this.props.postId;
  }
  get authorId(): string {
    return this.props.authorId;
  }
  get authorName(): string {
    return this.props.authorName;
  }
  get text(): string {
    return this.props.text;
  }
  get createdAt(): Date | undefined {
    return this.props.createdAt;
  }
  get updatedAt(): Date | undefined {
    return this.props.updatedAt;
  }

  toObject(): CommentProps & { id: string } {
    return { id: this.id, ...this.props };
  }
}
