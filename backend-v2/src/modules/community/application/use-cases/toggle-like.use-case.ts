import { Inject, Injectable } from "@nestjs/common";
import { IUseCase } from "../../../../core/application/use-case.interface";
import { Result, ok, err } from "../../../../core/application/result";
import {
  POST_REPOSITORY_TOKEN,
  IPostRepository,
} from "../../domain/repositories/post.repository.interface";

interface ToggleLikeInput {
  postId: string;
  userId: string;
}

@Injectable()
export class ToggleLikeUseCase implements IUseCase<
  ToggleLikeInput,
  Result<{ liked: boolean; likeCount: number }, string>
> {
  constructor(
    @Inject(POST_REPOSITORY_TOKEN) private readonly postRepo: IPostRepository,
  ) {}

  async execute(
    input: ToggleLikeInput,
  ): Promise<Result<{ liked: boolean; likeCount: number }, string>> {
    const post = await this.postRepo.findById(input.postId);
    if (!post) return err("Post not found");

    const result = post.toggleLike(input.userId);
    await this.postRepo.update(post);
    return ok(result);
  }
}
