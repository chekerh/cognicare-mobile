import { Inject, Injectable } from "@nestjs/common";
import { IUseCase } from "../../../../core/application/use-case.interface";
import { Result, ok, err } from "../../../../core/application/result";
import {
  POST_REPOSITORY_TOKEN,
  IPostRepository,
} from "../../domain/repositories/post.repository.interface";
import { UpdatePostDto } from "../dto/community.dto";

interface UpdatePostInput {
  postId: string;
  userId: string;
  dto: UpdatePostDto;
}

@Injectable()
export class UpdatePostUseCase implements IUseCase<
  UpdatePostInput,
  Result<void, string>
> {
  constructor(
    @Inject(POST_REPOSITORY_TOKEN) private readonly postRepo: IPostRepository,
  ) {}

  async execute(input: UpdatePostInput): Promise<Result<void, string>> {
    const post = await this.postRepo.findById(input.postId);
    if (!post) return err("Post not found");
    if (!post.isAuthor(input.userId))
      return err("You can only edit your own posts");

    post.update({
      text: input.dto.text,
      imageUrl: input.dto.imageUrl,
      tags: input.dto.tags,
    });
    await this.postRepo.update(post);
    return ok(undefined);
  }
}
