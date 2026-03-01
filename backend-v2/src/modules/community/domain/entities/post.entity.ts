import { Entity } from '../../../../core/domain/entity.base';

export interface PostProps {
  authorId: string;
  authorName: string;
  text: string;
  imageUrl?: string;
  tags: string[];
  likedBy: string[];
  createdAt?: Date;
  updatedAt?: Date;
}

export class PostEntity extends Entity<string> {
  private props: PostProps;

  private constructor(id: string, props: PostProps) {
    super(id);
    this.props = props;
  }

  static create(props: PostProps, id?: string): PostEntity {
    if (!props.text || props.text.trim().length === 0) {
      throw new Error('Post text is required');
    }
    return new PostEntity(id ?? Entity.generateId(), {
      ...props,
      tags: props.tags ?? [],
      likedBy: props.likedBy ?? [],
      createdAt: props.createdAt ?? new Date(),
      updatedAt: props.updatedAt ?? new Date(),
    });
  }

  static reconstitute(id: string, props: PostProps): PostEntity {
    return new PostEntity(id, props);
  }

  get authorId(): string { return this.props.authorId; }
  get authorName(): string { return this.props.authorName; }
  get text(): string { return this.props.text; }
  get imageUrl(): string | undefined { return this.props.imageUrl; }
  get tags(): string[] { return this.props.tags; }
  get likedBy(): string[] { return this.props.likedBy; }
  get likeCount(): number { return this.props.likedBy.length; }
  get createdAt(): Date | undefined { return this.props.createdAt; }
  get updatedAt(): Date | undefined { return this.props.updatedAt; }

  update(data: { text?: string; imageUrl?: string; tags?: string[] }): void {
    if (data.text !== undefined) this.props.text = data.text;
    if (data.imageUrl !== undefined) this.props.imageUrl = data.imageUrl;
    if (data.tags !== undefined) this.props.tags = data.tags;
    this.props.updatedAt = new Date();
  }

  toggleLike(userId: string): { liked: boolean; likeCount: number } {
    const index = this.props.likedBy.indexOf(userId);
    if (index >= 0) {
      this.props.likedBy.splice(index, 1);
    } else {
      this.props.likedBy.push(userId);
    }
    return {
      liked: this.props.likedBy.includes(userId),
      likeCount: this.props.likedBy.length,
    };
  }

  isLikedBy(userId: string): boolean {
    return this.props.likedBy.includes(userId);
  }

  isAuthor(userId: string): boolean {
    return this.props.authorId === userId;
  }

  toObject(): PostProps & { id: string } {
    return { id: this.id, ...this.props };
  }
}
