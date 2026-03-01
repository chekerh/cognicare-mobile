import { Inject, Injectable } from "@nestjs/common";
import { IUseCase } from "../../../../core/application/use-case.interface";
import { Result, ok, err } from "../../../../core/application/result";
import {
  COMMENT_REPOSITORY_TOKEN,
  ICommentRepository,
} from "../../domain/repositories/comment.repository.interface";
import {
  POST_REPOSITORY_TOKEN,
  IPostRepository,
} from "../../domain/repositories/post.repository.interface";
import { CommentEntity } from "../../domain/entities/comment.entity";
import { CreateCommentDto, CommentOutputDto } from "../dto/community.dto";

interface AddCommentInput {
  postId: string;
  userId: string;
  userName: string;
  dto: CreateCommentDto;
}

@Injectable()
export class AddCommentUseCase implements IUseCase<
  AddCommentInput,
  Result<CommentOutputDto, string>
> {
  constructor(
    @Inject(POST_REPOSITORY_TOKEN) private readonly postRepo: IPostRepository,
    @Inject(COMMENT_REPOSITORY_TOKEN)
    private readonly commentRepo: ICommentRepository,
  ) {}

  async execute(
    input: AddCommentInput,
  ): Promise<Result<CommentOutputDto, string>> {
    const post = await this.postRepo.findById(input.postId);
    if (!post) return err("Post not found");

    const comment = CommentEntity.create({
      postId: input.postId,
      authorId: input.userId,
      authorName: input.userName,
      text: input.dto.text,
    });

    const saved = await this.commentRepo.save(comment);
    return ok({
      authorName: saved.authorName,
      text: saved.text,
      createdAt: saved.createdAt?.toISOString() ?? new Date().toISOString(),
    });
  }
}
