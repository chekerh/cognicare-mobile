import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  Req,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  ParseIntPipe,
  Inject,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiConsumes } from '@nestjs/swagger';
import { Roles } from '@/shared/decorators/roles.decorator';
import {
  GetOrCreateApplicationUseCase,
  UpdateApplicationMeUseCase,
  AddDocumentUseCase,
  RemoveDocumentUseCase,
  CompleteCertificationUseCase,
  ListApplicationsForAdminUseCase,
  GetApplicationByIdUseCase,
  ReviewApplicationUseCase,
  AssignTaskUseCase,
  GetMyTasksUseCase,
} from '../../application/use-cases/volunteer.use-cases';
import { UpdateApplicationMeDto, ReviewApplicationDto, AssignTaskDto } from '../../application/dto/volunteer.dto';

@ApiTags('volunteers')
@ApiBearerAuth()
@Controller('volunteers')
export class VolunteersController {
  constructor(
    private readonly getOrCreate: GetOrCreateApplicationUseCase,
    private readonly updateMe: UpdateApplicationMeUseCase,
    private readonly addDoc: AddDocumentUseCase,
    private readonly removeDoc: RemoveDocumentUseCase,
    private readonly completeCert: CompleteCertificationUseCase,
    private readonly listAdmin: ListApplicationsForAdminUseCase,
    private readonly getById: GetApplicationByIdUseCase,
    private readonly review: ReviewApplicationUseCase,
    private readonly assignTask: AssignTaskUseCase,
    private readonly getMyTasks: GetMyTasksUseCase,
    @Inject('CLOUDINARY_UPLOAD_FN') private readonly uploadFn: (buffer: Buffer, options: any) => Promise<string>,
    @Inject('HAS_COMPLETED_QUALIFICATION_FN') private readonly hasCompletedQualificationFn: (userId: string) => Promise<boolean>,
    @Inject('SEND_VOLUNTEER_EMAIL_FN') private readonly sendEmailFn: (userId: string, decision: string, reason?: string) => Promise<void>,
  ) {}

  /* ── Volunteer self-management ── */

  @Get('application/me')
  @ApiOperation({ summary: 'Get or create my volunteer application' })
  async getApplication(@Req() req: any) {
    return this.getOrCreate.execute(req.user.userId);
  }

  @Patch('application/me')
  @ApiOperation({ summary: 'Update my application profile' })
  async updateApplication(@Req() req: any, @Body() dto: UpdateApplicationMeDto) {
    return this.updateMe.execute(req.user.userId, dto);
  }

  @Post('application/documents')
  @ApiOperation({ summary: 'Upload a document' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file'))
  async addDocument(
    @Req() req: any,
    @UploadedFile() file: Express.Multer.File,
    @Body('type') docType: string,
  ) {
    return this.addDoc.execute(req.user.userId, file, docType, this.uploadFn);
  }

  @Delete('application/documents/:index')
  @ApiOperation({ summary: 'Remove a document by index' })
  async removeDocument(@Req() req: any, @Param('index', ParseIntPipe) index: number) {
    return this.removeDoc.execute(req.user.userId, index);
  }

  @Post('application/complete-certification')
  @ApiOperation({ summary: 'Mark training certification complete' })
  async completeCertification(@Req() req: any) {
    return this.completeCert.execute(
      req.user.userId,
      () => this.hasCompletedQualificationFn(req.user.userId),
    );
  }

  @Get('my-tasks')
  @ApiOperation({ summary: 'Get tasks assigned to me' })
  async myTasks(@Req() req: any) {
    return this.getMyTasks.execute(req.user.userId);
  }

  /* ── Admin endpoints ── */

  @Get('applications')
  @Roles('admin')
  @ApiOperation({ summary: 'List all volunteer applications (admin)' })
  async listApplications(@Query('status') status?: string) {
    return this.listAdmin.execute(status);
  }

  @Get('applications/:id')
  @Roles('admin')
  @ApiOperation({ summary: 'Get a volunteer application by ID (admin)' })
  async getApplicationById(@Param('id') id: string) {
    return this.getById.execute(id);
  }

  @Patch('applications/:id/review')
  @Roles('admin')
  @ApiOperation({ summary: 'Approve or deny an application (admin)' })
  async reviewApplication(
    @Param('id') id: string,
    @Req() req: any,
    @Body() dto: ReviewApplicationDto,
  ) {
    const sendEmail = async (userId: string, reason?: string) => {
      await this.sendEmailFn(userId, dto.decision, reason);
    };
    return this.review.execute(id, req.user.userId, dto, sendEmail);
  }

  @Post('tasks')
  @Roles('admin')
  @ApiOperation({ summary: 'Assign a task to a volunteer (admin)' })
  async createTask(@Req() req: any, @Body() dto: AssignTaskDto) {
    return this.assignTask.execute(req.user.userId, dto);
  }
}
