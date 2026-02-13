import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  UseGuards,
  Query,
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
  ApiConsumes,
  ApiBody,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../auth/admin.guard';
import { VolunteersService, DocumentType } from './volunteers.service';
import { ReviewApplicationDto } from './dto/review-application.dto';

@ApiTags('volunteers')
@ApiBearerAuth('JWT-auth')
@Controller('volunteers')
export class VolunteersController {
  constructor(private readonly volunteersService: VolunteersService) {}

  @Get('application/me')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({
    summary: 'Get or create my volunteer application',
    description: 'Volunteer only. Returns current application with documents.',
  })
  @ApiResponse({ status: 200, description: 'Application' })
  async getMyApplication(@Request() req: { user: { id: string } }) {
    return this.volunteersService.getOrCreateApplication(req.user.id);
  }

  @Post('application/documents')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: { type: 'string', format: 'binary' },
        type: { type: 'string', enum: ['id', 'certificate', 'other'] },
      },
      required: ['file', 'type'],
    },
  })
  @ApiOperation({
    summary: 'Upload a document (ID, certificate). Max 5MB. Images or PDF.',
  })
  @ApiResponse({ status: 200, description: 'Updated application' })
  @ApiResponse({ status: 400, description: 'Invalid file or size' })
  async uploadDocument(
    @Request() req: { user: { id: string } },
    @UploadedFile()
    file: { buffer: Buffer; mimetype: string; originalname?: string },
    @Body('type') type: string,
  ) {
    if (!file?.buffer) {
      throw new BadRequestException('No file provided');
    }
    const docType = (
      type === 'id' || type === 'certificate' ? type : 'other'
    ) as DocumentType;
    return this.volunteersService.addDocument(req.user.id, docType, {
      buffer: file.buffer,
      mimetype: file.mimetype,
      originalname: file.originalname,
    });
  }

  @Delete('application/documents/:index')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({
    summary: 'Remove a document by index (volunteer, pending only)',
  })
  @ApiResponse({ status: 200, description: 'Updated application' })
  async removeDocument(
    @Request() req: { user: { id: string } },
    @Param('index') indexStr: string,
  ) {
    const index = parseInt(indexStr, 10);
    if (Number.isNaN(index)) {
      throw new BadRequestException('Invalid index');
    }
    return this.volunteersService.removeDocument(req.user.id, index);
  }

  @Get('applications')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiOperation({ summary: 'List all volunteer applications (Admin only)' })
  @ApiResponse({ status: 200, description: 'List of applications' })
  async listApplications(
    @Query('status') status?: 'pending' | 'approved' | 'denied',
  ) {
    return this.volunteersService.listForAdmin(status ? { status } : undefined);
  }

  @Get('applications/:id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiOperation({
    summary: 'Get one application with user details (Admin only)',
  })
  @ApiResponse({ status: 200, description: 'Application details' })
  async getApplication(
    @Request() req: { user: { id: string } },
    @Param('id') id: string,
  ) {
    return this.volunteersService.getByIdForAdmin(id, req.user.id);
  }

  @Patch('applications/:id/review')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiOperation({ summary: 'Approve or deny volunteer (Admin only)' })
  @ApiResponse({ status: 200, description: 'Updated application' })
  async review(
    @Request() req: { user: { id: string } },
    @Param('id') id: string,
    @Body() dto: ReviewApplicationDto,
  ) {
    return this.volunteersService.review(id, req.user.id, dto);
  }
}
