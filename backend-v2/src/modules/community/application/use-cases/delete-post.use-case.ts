import { Inject, Injectable } from "@nestjs/common";
import { IUseCase } from "../../../../core/application/use-case.interface";
import { Result, ok, err } from "../../../../core/application/result";
import {
  POST_REPOSITORY_TOKEN,
  IPostRepository,
} from "../../domain/repositories/post.repository.interface";
import {
  COMMENT_REPOSITORY_TOKEN,
  ICommentRepository,
} from "../../domain/repositories/comment.repository.interface";

interface DeletePostInput {
  postId: string;
  userId: string;
}

@Injectable()
export class DeletePostUseCase implements IUseCase<
  DeletePostInput,
  Result<void, string>
> {
  constructor(
    @Inject(POST_REPOSITORY_TOKEN) private readonly postRepo: IPostRepository,
    @Inject(COMMENT_REPOSITORY_TOKEN)
    private readonly commentRepo: ICommentRepository,
  ) {}

  async execute(input: DeletePostInput): Promise<Result<void, string>> {
    const post = await this.postRepo.findById(input.postId);
    if (!post) return err("Post not found");
    if (!post.isAuthor(input.userId))
      return err("You can only delete your own posts");

    await this.commentRepo.deleteByPostId(input.postId);
    await this.postRepo.delete(input.postId);
    return ok(undefined);
  }
}
