import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  Request,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from "@nestjs/common";
import { FileInterceptor } from "@nestjs/platform-express";
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from "@nestjs/swagger";
import {
  CreatePostDto,
  UpdatePostDto,
  CreateCommentDto,
} from "../../application/dto/community.dto";
import { CreatePostUseCase } from "../../application/use-cases/create-post.use-case";
import { GetPostsUseCase } from "../../application/use-cases/get-posts.use-case";
import { UpdatePostUseCase } from "../../application/use-cases/update-post.use-case";
import { DeletePostUseCase } from "../../application/use-cases/delete-post.use-case";
import { ToggleLikeUseCase } from "../../application/use-cases/toggle-like.use-case";
import { GetCommentsUseCase } from "../../application/use-cases/get-comments.use-case";
import { AddCommentUseCase } from "../../application/use-cases/add-comment.use-case";
import { GetLikeStatusUseCase } from "../../application/use-cases/get-like-status.use-case";
import { UploadPostImageUseCase } from "../../application/use-cases/upload-post-image.use-case";

@ApiTags("community")
@ApiBearerAuth("JWT-auth")
@Controller("community")
export class CommunityController {
  constructor(
    private readonly createPostUC: CreatePostUseCase,
    private readonly getPostsUC: GetPostsUseCase,
    private readonly updatePostUC: UpdatePostUseCase,
    private readonly deletePostUC: DeletePostUseCase,
    private readonly toggleLikeUC: ToggleLikeUseCase,
    private readonly getCommentsUC: GetCommentsUseCase,
    private readonly addCommentUC: AddCommentUseCase,
    private readonly getLikeStatusUC: GetLikeStatusUseCase,
    private readonly uploadPostImageUC: UploadPostImageUseCase,
  ) {}

  @Post("upload-post-image")
  @UseInterceptors(FileInterceptor("file"))
  @ApiOperation({ summary: "Upload image for a post" })
  @ApiResponse({ status: 201, description: "Returns { imageUrl }" })
  async uploadPostImage(
    @UploadedFile() file?: { buffer: Buffer; mimetype: string },
  ) {
    if (!file || !file.buffer)
      throw new BadRequestException("No file provided");
    const allowed = [
      "image/jpeg",
      "image/jpg",
      "image/png",
      "image/webp",
      "image/heic",
    ];
    let mimetype = (file.mimetype ?? "").toLowerCase();
    if (!mimetype || mimetype === "application/octet-stream")
      mimetype = "image/jpeg";
    if (!allowed.includes(mimetype) && !mimetype.startsWith("image/")) {
      throw new BadRequestException(
        "Invalid file type. Use JPEG, PNG or WebP.",
      );
    }
    const result = await this.uploadPostImageUC.execute({
      buffer: file.buffer,
      mimetype: mimetype.startsWith("image/") ? mimetype : "image/jpeg",
    });
    if (result.isFailure) throw new BadRequestException(result.error);
    return { imageUrl: result.value };
  }

  @Post("posts")
  @ApiOperation({ summary: "Create a new post" })
  @ApiResponse({ status: 201, description: "Post created" })
  async createPost(
    @Request() req: { user: { id: string; fullName?: string } },
    @Body() dto: CreatePostDto,
  ) {
    const result = await this.createPostUC.execute({
      userId: req.user.id,
      userName: req.user.fullName ?? "Unknown",
      dto,
    });
    if (result.isFailure) throw new BadRequestException(result.error);
    return result.value;
  }

  @Get("posts")
  @ApiOperation({ summary: "Get all posts (feed)" })
  @ApiResponse({ status: 200, description: "List of posts" })
  async getPosts() {
    const result = await this.getPostsUC.execute();
    if (result.isFailure) throw new BadRequestException(result.error);
    return result.value;
  }

  @Patch("posts/:id")
  @ApiOperation({ summary: "Update a post (author only)" })
  async updatePost(
    @Request() req: { user: { id: string } },
    @Param("id") postId: string,
    @Body() dto: UpdatePostDto,
  ) {
    const result = await this.updatePostUC.execute({
      postId,
      userId: req.user.id,
      dto,
    });
    if (result.isFailure) {
      if (result.error === "Post not found")
        throw new NotFoundException(result.error);
      throw new ForbiddenException(result.error);
    }
    return { success: true };
  }

  @Delete("posts/:id")
  @ApiOperation({ summary: "Delete a post (author only)" })
  async deletePost(
    @Request() req: { user: { id: string } },
    @Param("id") postId: string,
  ) {
    const result = await this.deletePostUC.execute({
      postId,
      userId: req.user.id,
    });
    if (result.isFailure) {
      if (result.error === "Post not found")
        throw new NotFoundException(result.error);
      throw new ForbiddenException(result.error);
    }
    return { success: true };
  }

  @Post("posts/:id/like")
  @ApiOperation({ summary: "Toggle like on a post" })
  async toggleLike(
    @Request() req: { user: { id: string } },
    @Param("id") postId: string,
  ) {
    const result = await this.toggleLikeUC.execute({
      postId,
      userId: req.user.id,
    });
    if (result.isFailure) throw new NotFoundException(result.error);
    return result.value;
  }

  @Get("posts/:id/comments")
  @ApiOperation({ summary: "Get comments for a post" })
  async getComments(@Param("id") postId: string) {
    const result = await this.getCommentsUC.execute(postId);
    if (result.isFailure) throw new BadRequestException(result.error);
    return result.value;
  }

  @Post("posts/:id/comments")
  @ApiOperation({ summary: "Add a comment to a post" })
  async addComment(
    @Request() req: { user: { id: string; fullName?: string } },
    @Param("id") postId: string,
    @Body() dto: CreateCommentDto,
  ) {
    const result = await this.addCommentUC.execute({
      postId,
      userId: req.user.id,
      userName: req.user.fullName ?? "Unknown",
      dto,
    });
    if (result.isFailure) throw new NotFoundException(result.error);
    return result.value;
  }

  @Get("posts/like-status")
  @ApiOperation({ summary: "Get like status for current user" })
  async getLikeStatus(
    @Request() req: { user: { id: string } },
    @Query("postIds") postIdsParam?: string,
  ) {
    const postIds = postIdsParam ? postIdsParam.split(",").filter(Boolean) : [];
    const result = await this.getLikeStatusUC.execute({
      postIds,
      userId: req.user.id,
    });
    if (result.isFailure) throw new BadRequestException(result.error);
    return result.value;
  }
}
