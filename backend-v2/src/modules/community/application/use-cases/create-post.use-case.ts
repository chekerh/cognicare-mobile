import { Inject, Injectable } from "@nestjs/common";
import { IUseCase } from "../../../../core/application/use-case.interface";
import { Result, ok, err } from "../../../../core/application/result";
import {
  POST_REPOSITORY_TOKEN,
  IPostRepository,
} from "../../domain/repositories/post.repository.interface";
import { PostEntity } from "../../domain/entities/post.entity";
import { CreatePostDto, PostOutputDto } from "../dto/community.dto";

interface CreatePostInput {
  userId: string;
  userName: string;
  dto: CreatePostDto;
}

@Injectable()
export class CreatePostUseCase implements IUseCase<
  CreatePostInput,
  Result<PostOutputDto, string>
> {
  constructor(
    @Inject(POST_REPOSITORY_TOKEN) private readonly postRepo: IPostRepository,
  ) {}

  async execute(
    input: CreatePostInput,
  ): Promise<Result<PostOutputDto, string>> {
    try {
      const entity = PostEntity.create({
        authorId: input.userId,
        authorName: input.userName,
        text: input.dto.text,
        imageUrl: input.dto.imageUrl,
        tags: input.dto.tags ?? [],
        likedBy: [],
      });

      const saved = await this.postRepo.save(entity);
      const obj = saved.toObject();

      return ok({
        id: obj.id,
        authorId: obj.authorId,
        authorName: obj.authorName,
        text: obj.text,
        createdAt: obj.createdAt?.toISOString() ?? new Date().toISOString(),
        hasImage: !!obj.imageUrl,
        imagePath: obj.imageUrl ?? null,
        imageUrl: obj.imageUrl,
        tags: obj.tags,
        likeCount: 0,
      });
    } catch (error) {
      return err(
        error instanceof Error ? error.message : "Failed to create post",
      );
    }
  }
}
