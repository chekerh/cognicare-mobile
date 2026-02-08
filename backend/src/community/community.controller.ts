import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CommunityService } from './community.service';
import { CreatePostDto } from './dto/create-post.dto';
import { UpdatePostDto } from './dto/update-post.dto';
import { CreateCommentDto } from './dto/create-comment.dto';

@ApiTags('community')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller('community')
export class CommunityController {
  constructor(private readonly communityService: CommunityService) {}

  @Post('upload-post-image')
  @UseInterceptors(FileInterceptor('file'))
  @ApiOperation({ summary: 'Upload image for a post' })
  @ApiResponse({ status: 201, description: 'Returns { imageUrl }' })
  @ApiResponse({ status: 400, description: 'No file or invalid type' })
  async uploadPostImage(
    // Avoid relying on Multer types — use a minimal inline shape for the uploaded file.
    @UploadedFile()
    file?: { buffer: Buffer; mimetype: string; originalname?: string },
  ) {
    if (!file || !file.buffer)
      throw new BadRequestException('No file provided');
    const allowed = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/webp',
      'image/heic', // iOS photos
    ];
    const mimetype = (file.mimetype ?? '').toLowerCase();
    if (!allowed.includes(mimetype) && !mimetype.startsWith('image/')) {
      throw new BadRequestException(
        'Invalid file type. Use JPEG, PNG or WebP.',
      );
    }
    const imageUrl = await this.communityService.uploadPostImage({
      buffer: file.buffer,
      mimetype: mimetype.startsWith('image/') ? mimetype : 'image/jpeg',
    });
    return { imageUrl };
  }

  @Post('posts')
  @ApiOperation({ summary: 'Create a new post' })
  @ApiResponse({ status: 201, description: 'Post created' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async createPost(
    @Request() req: { user: { id: string } },
    @Body() dto: CreatePostDto,
  ) {
    return this.communityService.createPost(req.user.id, dto);
  }

  @Get('posts')
  @ApiOperation({ summary: 'Get all posts (feed)' })
  @ApiResponse({ status: 200, description: 'List of posts' })
  async getPosts() {
    return this.communityService.getPosts();
  }

  @Patch('posts/:id')
  @ApiOperation({ summary: 'Update a post (author only)' })
  @ApiResponse({ status: 200, description: 'Post updated' })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  @ApiResponse({ status: 404, description: 'Post not found' })
  async updatePost(
    @Request() req: { user: { id: string } },
    @Param('id') postId: string,
    @Body() dto: UpdatePostDto,
  ) {
    await this.communityService.updatePost(postId, req.user.id, dto);
    return { success: true };
  }

  @Delete('posts/:id')
  @ApiOperation({ summary: 'Delete a post (author only)' })
  @ApiResponse({ status: 200, description: 'Post deleted' })
  @ApiResponse({ status: 403, description: 'Forbidden' })
  @ApiResponse({ status: 404, description: 'Post not found' })
  async deletePost(
    @Request() req: { user: { id: string } },
    @Param('id') postId: string,
  ) {
    await this.communityService.deletePost(postId, req.user.id);
    return { success: true };
  }

  @Post('posts/:id/like')
  @ApiOperation({ summary: 'Toggle like on a post' })
  @ApiResponse({ status: 200, description: 'Like toggled' })
  @ApiResponse({ status: 404, description: 'Post not found' })
  async toggleLike(
    @Request() req: { user: { id: string } },
    @Param('id') postId: string,
  ) {
    return this.communityService.toggleLike(postId, req.user.id);
  }

  @Get('posts/:id/comments')
  @ApiOperation({ summary: 'Get comments for a post' })
  @ApiResponse({ status: 200, description: 'List of comments' })
  @ApiResponse({ status: 404, description: 'Post not found' })
  async getComments(@Param('id') postId: string) {
    return this.communityService.getComments(postId);
  }

  @Post('posts/:id/comments')
  @ApiOperation({ summary: 'Add a comment to a post' })
  @ApiResponse({ status: 201, description: 'Comment added' })
  @ApiResponse({ status: 404, description: 'Post not found' })
  async addComment(
    @Request() req: { user: { id: string } },
    @Param('id') postId: string,
    @Body() dto: CreateCommentDto,
  ) {
    return this.communityService.addComment(postId, req.user.id, dto);
  }

  @Get('posts/like-status')
  @ApiOperation({ summary: 'Get like status for current user on given posts' })
  @ApiResponse({ status: 200, description: 'Map of postId -> liked' })
  async getLikeStatus(
    @Request() req: { user: { id: string } },
    @Query('postIds') postIdsParam?: string,
  ) {
    const postIds = postIdsParam ? postIdsParam.split(',').filter(Boolean) : [];
    return this.communityService.getPostLikeStatus(postIds, req.user.id);
  }
}
