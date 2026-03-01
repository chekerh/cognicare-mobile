import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  UseGuards,
  Request,
} from "@nestjs/common";
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from "@nestjs/swagger";
import { AdminGuard } from "@/shared/guards/admin.guard";
import { Public } from "@/shared/decorators/public.decorator";
import { TrainingService } from "./training.service";
import { CreateTrainingCourseDto } from "./dto/create-training-course.dto";
import { UpdateTrainingCourseDto } from "./dto/update-training-course.dto";
import { ApproveTrainingCourseDto } from "./dto/approve-training-course.dto";
import { SubmitQuizDto } from "./dto/submit-quiz.dto";

@ApiTags("training")
@Controller("training")
export class TrainingController {
  constructor(private readonly trainingService: TrainingService) {}

  @Get("courses")
  @Public()
  @ApiOperation({ summary: "List approved training courses (for caregivers)" })
  @ApiResponse({ status: 200, description: "List of approved courses" })
  async listCourses() {
    return this.trainingService.listApproved();
  }

  @Get("courses/:id")
  @Public()
  @ApiOperation({ summary: "Get one training course by id" })
  @ApiResponse({
    status: 200,
    description: "Course details (quiz without correct answers)",
  })
  async getCourse(@Param("id") id: string) {
    return this.trainingService.getById(id, false);
  }

  @Post("courses/:id/enroll")
  @ApiBearerAuth("JWT-auth")
  @ApiOperation({ summary: "Enroll in a training course" })
  async enroll(
    @Request() req: { user: { id: string } },
    @Param("id") id: string,
  ) {
    return this.trainingService.enroll(req.user.id, id);
  }

  @Get("my-enrollments")
  @ApiBearerAuth("JWT-auth")
  @ApiOperation({ summary: "Get my training enrollments and progress" })
  async myEnrollments(@Request() req: { user: { id: string } }) {
    return this.trainingService.getMyEnrollments(req.user.id);
  }

  @Post("courses/:id/complete-content")
  @ApiBearerAuth("JWT-auth")
  @ApiOperation({ summary: "Mark course content as completed (before quiz)" })
  async markContentCompleted(
    @Request() req: { user: { id: string } },
    @Param("id") id: string,
  ) {
    return this.trainingService.markContentCompleted(req.user.id, id);
  }

  @Post("courses/:id/submit-quiz")
  @ApiBearerAuth("JWT-auth")
  @ApiOperation({
    summary:
      "Submit quiz answers; returns score, pass/fail, and review with correct answers",
  })
  async submitQuiz(
    @Request() req: { user: { id: string } },
    @Param("id") id: string,
    @Body() dto: SubmitQuizDto,
  ) {
    return this.trainingService.submitQuiz(
      req.user.id,
      id,
      dto.answers,
      dto.textAnswers,
    );
  }

  @Get("next-course")
  @ApiBearerAuth("JWT-auth")
  @ApiOperation({ summary: "Get next unlocked course id (for progression)" })
  async nextCourse(@Request() req: { user: { id: string } }) {
    const id = await this.trainingService.getNextUnlockedCourseId(req.user.id);
    return { courseId: id };
  }

  // ——— Admin ———

  @Get("admin/courses")
  @UseGuards(AdminGuard)
  @ApiBearerAuth("JWT-auth")
  @ApiOperation({ summary: "List all training courses (including unapproved)" })
  async listAllCourses() {
    return this.trainingService.listAll();
  }

  @Get("admin/courses/:id")
  @UseGuards(AdminGuard)
  @ApiBearerAuth("JWT-auth")
  @ApiOperation({ summary: "Get course by id (admin, includes approval info)" })
  async getCourseAdmin(@Param("id") id: string) {
    return this.trainingService.getById(id, true);
  }

  @Post("admin/courses")
  @UseGuards(AdminGuard)
  @ApiBearerAuth("JWT-auth")
  @ApiOperation({ summary: "Create training course" })
  async createCourse(@Body() dto: CreateTrainingCourseDto) {
    return this.trainingService.create(dto);
  }

  @Patch("admin/courses/:id")
  @UseGuards(AdminGuard)
  @ApiBearerAuth("JWT-auth")
  @ApiOperation({ summary: "Update training course" })
  async updateCourse(
    @Param("id") id: string,
    @Body() dto: UpdateTrainingCourseDto,
  ) {
    return this.trainingService.update(id, dto);
  }

  @Patch("admin/courses/:id/approve")
  @UseGuards(AdminGuard)
  @ApiBearerAuth("JWT-auth")
  @ApiOperation({
    summary: "Approve or reject course (professional validation)",
  })
  async approveCourse(
    @Request() req: { user: { id: string } },
    @Param("id") id: string,
    @Body() dto: ApproveTrainingCourseDto,
  ) {
    return this.trainingService.approve(id, req.user.id, dto);
  }
}
