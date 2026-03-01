import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../auth/admin.guard';
import { TrainingService } from './training.service';
import { CreateTrainingCourseDto } from './dto/create-training-course.dto';
import { UpdateTrainingCourseDto } from './dto/update-training-course.dto';
import { ApproveTrainingCourseDto } from './dto/approve-training-course.dto';
import { SubmitQuizDto } from './dto/submit-quiz.dto';

@ApiTags('training')
@Controller('training')
export class TrainingController {
  constructor(private readonly trainingService: TrainingService) {}

  @Get('courses')
  @ApiOperation({
    summary: 'List approved training courses (for caregivers)',
  })
  @ApiResponse({ status: 200, description: 'List of approved courses' })
  async listCourses() {
    return this.trainingService.listApproved();
  }

  @Get('courses/:id')
  @ApiOperation({ summary: 'Get one training course by id' })
  @ApiResponse({ status: 200, description: 'Course details (quiz without correct answers)' })
  @ApiResponse({ status: 404, description: 'Course not found' })
  async getCourse(@Param('id') id: string) {
    return this.trainingService.getById(id, false);
  }

  @Post('courses/:id/enroll')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Enroll in a training course' })
  @ApiResponse({ status: 200, description: 'Enrollments list' })
  async enroll(
    @Request() req: { user: { id: string } },
    @Param('id') id: string,
  ) {
    return this.trainingService.enroll(req.user.id, id);
  }

  @Get('my-enrollments')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get my training enrollments and progress' })
  @ApiResponse({ status: 200, description: 'List of enrollments with progress' })
  async myEnrollments(@Request() req: { user: { id: string } }) {
    return this.trainingService.getMyEnrollments(req.user.id);
  }

  @Post('courses/:id/complete-content')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Mark course content as completed (before quiz)' })
  @ApiResponse({ status: 200, description: 'Updated enrollments' })
  async markContentCompleted(
    @Request() req: { user: { id: string } },
    @Param('id') id: string,
  ) {
    return this.trainingService.markContentCompleted(req.user.id, id);
  }

  @Post('courses/:id/submit-quiz')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Submit quiz answers; returns score and pass/fail' })
  @ApiResponse({ status: 200, description: 'Score, passed, and updated enrollments' })
  async submitQuiz(
    @Request() req: { user: { id: string } },
    @Param('id') id: string,
    @Body() dto: SubmitQuizDto,
  ) {
    return this.trainingService.submitQuiz(req.user.id, id, dto.answers);
  }

  @Get('next-course')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get next unlocked course id (for progression)' })
  @ApiResponse({ status: 200, description: 'Course id or null if all done' })
  async nextCourse(@Request() req: { user: { id: string } }) {
    const id = await this.trainingService.getNextUnlockedCourseId(req.user.id);
    return { courseId: id };
  }

  // ——— Admin ———

  @Get('admin/courses')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'List all training courses (including unapproved)' })
  @ApiResponse({ status: 200, description: 'List of all courses' })
  async listAllCourses() {
    return this.trainingService.listAll();
  }

  @Get('admin/courses/:id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get course by id (admin, includes approval info)' })
  async getCourseAdmin(@Param('id') id: string) {
    return this.trainingService.getById(id, true);
  }

  @Post('admin/courses')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Create training course (e.g. from scraper)' })
  @ApiResponse({ status: 201, description: 'Created course' })
  async createCourse(@Body() dto: CreateTrainingCourseDto) {
    return this.trainingService.create(dto);
  }

  @Patch('admin/courses/:id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Update training course' })
  async updateCourse(
    @Param('id') id: string,
    @Body() dto: UpdateTrainingCourseDto,
  ) {
    return this.trainingService.update(id, dto);
  }

  @Patch('admin/courses/:id/approve')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Approve or reject course (professional validation)' })
  async approveCourse(
    @Request() req: { user: { id: string } },
    @Param('id') id: string,
    @Body() dto: ApproveTrainingCourseDto,
  ) {
    return this.trainingService.approve(id, req.user.id, dto);
  }
}
