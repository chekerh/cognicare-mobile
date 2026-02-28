import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
  Query,
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
import { CoursesService } from './courses.service';

@ApiTags('courses')
@Controller('courses')
export class CoursesController {
  constructor(private readonly coursesService: CoursesService) {}

  @Get()
  @ApiOperation({
    summary: 'List courses with optional filters (qualification, courseType, certification)',
  })
  @ApiResponse({ status: 200, description: 'List of courses' })
  async list(
    @Query('qualification') qualification?: string,
    @Query('courseType') courseType?: string,
    @Query('certification') certification?: string,
  ) {
    const qualificationOnly = qualification === 'true';
    const hasCertification = certification === 'true';
    return this.coursesService.findAll({
      qualificationOnly,
      courseType: courseType?.trim() || undefined,
      hasCertification,
    });
  }

  @Post()
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Create course (Admin). Used to import scraped training data.',
  })
  @ApiResponse({ status: 201, description: 'Course created' })
  async create(
    @Body()
    body: {
      title: string;
      description?: string;
      slug: string;
      isQualificationCourse?: boolean;
      startDate?: string;
      endDate?: string;
      courseType?: string;
      price?: string;
      location?: string;
      enrollmentLink?: string;
      certification?: string;
      targetAudience?: string;
      prerequisites?: string;
      sourceUrl?: string;
    },
  ) {
    const dto = {
      ...body,
      startDate: body.startDate ? new Date(body.startDate) : undefined,
      endDate: body.endDate ? new Date(body.endDate) : undefined,
    };
    return this.coursesService.create(dto);
  }

  @Get('admin/enrollments')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'List course enrollments (Admin). Optional userId filter.',
  })
  @ApiResponse({
    status: 200,
    description: 'List of enrollments with user and course',
  })
  async listEnrollmentsForAdmin(@Query('userId') userId?: string) {
    return this.coursesService.listEnrollmentsForAdmin(userId);
  }

  @Post(':id/enroll')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Enroll in a course (authenticated user)' })
  @ApiResponse({ status: 200, description: 'Updated enrollments' })
  async enroll(
    @Request() req: { user: { id: string } },
    @Param('id') courseId: string,
  ) {
    return this.coursesService.enroll(req.user.id, courseId);
  }

  @Get('my-enrollments')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get my course enrollments' })
  @ApiResponse({ status: 200, description: 'List of enrollments' })
  async myEnrollments(@Request() req: { user: { id: string } }) {
    return this.coursesService.myEnrollments(req.user.id);
  }

  @Patch('enrollments/:id/progress')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Update progress for an enrollment (0-100)' })
  @ApiResponse({ status: 200, description: 'Updated enrollments' })
  async updateProgress(
    @Request() req: { user: { id: string } },
    @Param('id') enrollmentId: string,
    @Body('progressPercent') progressPercent: number,
  ) {
    const value =
      typeof progressPercent === 'number'
        ? progressPercent
        : parseInt(String(progressPercent), 10) || 0;
    return this.coursesService.updateProgress(req.user.id, enrollmentId, value);
  }
}
