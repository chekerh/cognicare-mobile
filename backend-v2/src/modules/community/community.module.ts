import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PostMongoSchema, PostSchema } from './infrastructure/persistence/mongo/post.schema';
import { CommentMongoSchema, CommentSchema } from './infrastructure/persistence/mongo/comment.schema';
import { POST_REPOSITORY_TOKEN } from './domain/repositories/post.repository.interface';
import { COMMENT_REPOSITORY_TOKEN } from './domain/repositories/comment.repository.interface';
import { PostMongoRepository } from './infrastructure/persistence/mongo/post.mongo-repository';
import { CommentMongoRepository } from './infrastructure/persistence/mongo/comment.mongo-repository';
import { CreatePostUseCase } from './application/use-cases/create-post.use-case';
import { GetPostsUseCase } from './application/use-cases/get-posts.use-case';
import { UpdatePostUseCase } from './application/use-cases/update-post.use-case';
import { DeletePostUseCase } from './application/use-cases/delete-post.use-case';
import { ToggleLikeUseCase } from './application/use-cases/toggle-like.use-case';
import { GetCommentsUseCase } from './application/use-cases/get-comments.use-case';
import { AddCommentUseCase } from './application/use-cases/add-comment.use-case';
import { GetLikeStatusUseCase } from './application/use-cases/get-like-status.use-case';
import { UploadPostImageUseCase } from './application/use-cases/upload-post-image.use-case';
import { CommunityController } from './interface/http/community.controller';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: PostMongoSchema.name, schema: PostSchema },
      { name: CommentMongoSchema.name, schema: CommentSchema },
    ]),
  ],
  controllers: [CommunityController],
  providers: [
    { provide: POST_REPOSITORY_TOKEN, useClass: PostMongoRepository },
    { provide: COMMENT_REPOSITORY_TOKEN, useClass: CommentMongoRepository },
    CreatePostUseCase,
    GetPostsUseCase,
    UpdatePostUseCase,
    DeletePostUseCase,
    ToggleLikeUseCase,
    GetCommentsUseCase,
    AddCommentUseCase,
    GetLikeStatusUseCase,
    UploadPostImageUseCase,
  ],
  exports: [POST_REPOSITORY_TOKEN, COMMENT_REPOSITORY_TOKEN],
})
export class CommunityModule {}
