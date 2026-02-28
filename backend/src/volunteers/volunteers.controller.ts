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
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { VolunteersService, DocumentType } from './volunteers.service';
import { ReviewApplicationDto } from './dto/review-application.dto';
import { UpdateApplicationMeDto } from './dto/update-application-me.dto';

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

  @Patch('application/me')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({
    summary: 'Update my application (careProviderType, specialty, organization)',
    description:
      'Care Provider only. Update type and optional specialty/org fields. Only when status is pending.',
  })
  @ApiResponse({ status: 200, description: 'Updated application' })
  async updateMyApplication(
    @Request() req: { user: { id: string } },
    @Body() dto: UpdateApplicationMeDto,
  ) {
    return this.volunteersService.updateApplicationMe(req.user.id, dto);
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

  @Post('application/complete-certification')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({
    summary: 'Mark training as certified',
    description:
      'Volunteer must have completed at least one qualification course (100%) and application must be approved.',
  })
  @ApiResponse({ status: 200, description: 'Updated application' })
  @ApiResponse({
    status: 400,
    description: 'Course not completed or application not approved',
  })
  async completeCertification(@Request() req: { user: { id: string } }) {
    return this.volunteersService.completeCertification(req.user.id);
  }

  @Get('my-tasks')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'List my assigned tasks (volunteer)' })
  @ApiResponse({ status: 200, description: 'List of tasks' })
  async getMyTasks(@Request() req: { user: { id: string } }) {
    return this.volunteersService.getMyTasks(req.user.id);
  }

  @Post('tasks')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(
    'admin',
    'organization_leader',
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
    'doctor',
    'other',
  )
  @ApiOperation({
    summary: 'Assign a task to a volunteer (specialist or admin)',
  })
  @ApiResponse({ status: 201, description: 'Task created; volunteer notified' })
  async assignTask(
    @Request() req: { user: { id: string } },
    @Body()
    body: { volunteerId: string; title: string; description?: string; dueDate?: string },
  ) {
    return this.volunteersService.assignTask(req.user.id, {
      volunteerId: body.volunteerId,
      title: body.title,
      description: body.description,
      dueDate: body.dueDate,
    });
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
