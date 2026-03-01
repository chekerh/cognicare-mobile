import { Inject, Injectable } from "@nestjs/common";
import { IUseCase } from "../../../../core/application/use-case.interface";
import { Result, ok } from "../../../../core/application/result";
import {
  COMMENT_REPOSITORY_TOKEN,
  ICommentRepository,
} from "../../domain/repositories/comment.repository.interface";
import { CommentOutputDto } from "../dto/community.dto";

@Injectable()
export class GetCommentsUseCase implements IUseCase<
  string,
  Result<CommentOutputDto[], string>
> {
  constructor(
    @Inject(COMMENT_REPOSITORY_TOKEN)
    private readonly commentRepo: ICommentRepository,
  ) {}

  async execute(postId: string): Promise<Result<CommentOutputDto[], string>> {
    const comments = await this.commentRepo.findByPostId(postId);
    const output: CommentOutputDto[] = comments.map((c) => ({
      authorName: c.authorName,
      text: c.text,
      createdAt: c.createdAt?.toISOString() ?? "",
    }));
    return ok(output);
  }
}
