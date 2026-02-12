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
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../auth/admin.guard';
import { CoursesService } from './courses.service';

@ApiTags('courses')
@Controller('courses')
export class CoursesController {
  constructor(private readonly coursesService: CoursesService) {}

  @Get()
  @ApiOperation({ summary: 'List courses (optionally qualification only)' })
  @ApiResponse({ status: 200, description: 'List of courses' })
  async list(@Query('qualification') qualification?: string) {
    const qualificationOnly = qualification === 'true';
    return this.coursesService.findAll(qualificationOnly);
  }

  @Get('admin/enrollments')
  @UseGuards(JwtAuthGuard, AdminGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'List course enrollments (Admin). Optional userId filter.' })
  @ApiResponse({ status: 200, description: 'List of enrollments with user and course' })
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
    const value = typeof progressPercent === 'number' ? progressPercent : parseInt(String(progressPercent), 10) || 0;
    return this.coursesService.updateProgress(req.user.id, enrollmentId, value);
  }
}
