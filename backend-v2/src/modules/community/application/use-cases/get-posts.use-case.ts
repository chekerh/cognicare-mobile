import { Inject, Injectable } from '@nestjs/common';
import { IUseCase } from '../../../../core/application/use-case.interface';
import { Result, ok } from '../../../../core/application/result';
import { POST_REPOSITORY_TOKEN, IPostRepository } from '../../domain/repositories/post.repository.interface';
import { PostOutputDto } from '../dto/community.dto';

@Injectable()
export class GetPostsUseCase implements IUseCase<void, Result<PostOutputDto[], string>> {
  constructor(
    @Inject(POST_REPOSITORY_TOKEN) private readonly postRepo: IPostRepository,
  ) {}

  async execute(): Promise<Result<PostOutputDto[], string>> {
    const posts = await this.postRepo.findAll();
    const output: PostOutputDto[] = posts.map((p) => {
      const obj = p.toObject();
      return {
        id: obj.id,
        authorId: obj.authorId,
        authorName: obj.authorName,
        text: obj.text,
        createdAt: obj.createdAt?.toISOString() ?? '',
        hasImage: !!obj.imageUrl,
        imagePath: obj.imageUrl ?? null,
        imageUrl: obj.imageUrl,
        tags: obj.tags ?? [],
        likeCount: obj.likedBy.length,
      };
    });
    return ok(output);
  }
}
