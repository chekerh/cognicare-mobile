import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  Request,
  NotFoundException,
} from "@nestjs/common";
import { ApiTags, ApiBearerAuth, ApiOperation } from "@nestjs/swagger";
import { Roles } from "../../../../shared/decorators/roles.decorator";
import {
  CreateCourseUseCase,
  ListCoursesUseCase,
  EnrollCourseUseCase,
  MyEnrollmentsUseCase,
  ListEnrollmentsForAdminUseCase,
  UpdateProgressUseCase,
} from "../../application/use-cases/course.use-cases";
import { Public } from "../../../../shared/decorators/public.decorator";

@ApiTags("courses")
@Controller("courses")
export class CoursesController {
  constructor(
    private readonly createUC: CreateCourseUseCase,
    private readonly listUC: ListCoursesUseCase,
    private readonly enrollUC: EnrollCourseUseCase,
    private readonly myEnrollUC: MyEnrollmentsUseCase,
    private readonly adminEnrollUC: ListEnrollmentsForAdminUseCase,
    private readonly updateProgressUC: UpdateProgressUseCase,
  ) {}

  @Get()
  @Public()
  @ApiOperation({ summary: "List courses with optional filters" })
  async list(
    @Query("qualification") qualification?: string,
    @Query("courseType") courseType?: string,
    @Query("certification") certification?: string,
  ) {
    const result = await this.listUC.execute({
      qualificationOnly: qualification === "true",
      courseType: courseType?.trim() || undefined,
      hasCertification: certification === "true",
    });
    return result.value;
  }

  @Post()
  @Roles("admin")
  @ApiBearerAuth("JWT-auth")
  @ApiOperation({ summary: "Create course (Admin)" })
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
    const result = await this.createUC.execute(dto);
    return result.value;
  }

  @Get("admin/enrollments")
  @Roles("admin")
  @ApiBearerAuth("JWT-auth")
  @ApiOperation({ summary: "List course enrollments (Admin)" })
  async listEnrollments(@Query("userId") userId?: string) {
    const result = await this.adminEnrollUC.execute(userId);
    return result.value;
  }

  @Post(":id/enroll")
  @ApiBearerAuth("JWT-auth")
  @ApiOperation({ summary: "Enroll in a course" })
  async enroll(
    @Request() req: { user: { id: string } },
    @Param("id") courseId: string,
  ) {
    const result = await this.enrollUC.execute(req.user.id, courseId);
    if (result.isFailure) throw new NotFoundException(result.error);
    return result.value;
  }

  @Get("my-enrollments")
  @ApiBearerAuth("JWT-auth")
  @ApiOperation({ summary: "Get my course enrollments" })
  async myEnrollments(@Request() req: { user: { id: string } }) {
    const result = await this.myEnrollUC.execute(req.user.id);
    return result.value;
  }

  @Patch("enrollments/:id/progress")
  @ApiBearerAuth("JWT-auth")
  @ApiOperation({ summary: "Update progress for an enrollment (0-100)" })
  async updateProgress(
    @Request() req: { user: { id: string } },
    @Param("id") enrollmentId: string,
    @Body("progressPercent") progressPercent: number,
  ) {
    const value =
      typeof progressPercent === "number"
        ? progressPercent
        : parseInt(String(progressPercent), 10) || 0;
    const result = await this.updateProgressUC.execute(
      req.user.id,
      enrollmentId,
      value,
    );
    if (result.isFailure) throw new NotFoundException(result.error);
    return result.value;
  }
}
