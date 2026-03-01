import { Inject, Injectable } from "@nestjs/common";
import { IUseCase } from "../../../../core/application/use-case.interface";
import { Result, ok } from "../../../../core/application/result";
import {
  POST_REPOSITORY_TOKEN,
  IPostRepository,
} from "../../domain/repositories/post.repository.interface";

interface GetLikeStatusInput {
  postIds: string[];
  userId: string;
}

@Injectable()
export class GetLikeStatusUseCase implements IUseCase<
  GetLikeStatusInput,
  Result<Record<string, boolean>, string>
> {
  constructor(
    @Inject(POST_REPOSITORY_TOKEN) private readonly postRepo: IPostRepository,
  ) {}

  async execute(
    input: GetLikeStatusInput,
  ): Promise<Result<Record<string, boolean>, string>> {
    if (input.postIds.length === 0) return ok({});

    const posts = await this.postRepo.findByIds(input.postIds);
    const result: Record<string, boolean> = {};
    for (const post of posts) {
      result[post.id] = post.isLikedBy(input.userId);
    }
    return ok(result);
  }
}
