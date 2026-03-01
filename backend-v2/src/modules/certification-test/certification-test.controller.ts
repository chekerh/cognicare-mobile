import { Controller, Get, Post, Body, Request } from "@nestjs/common";
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from "@nestjs/swagger";
import { CertificationTestService } from "./certification-test.service";

class SubmitCertificationTestDto {
  answers!: { questionIndex: number; value: string }[];
}

@ApiTags("volunteers")
@ApiBearerAuth("JWT-auth")
@Controller("volunteers/certification-test")
export class CertificationTestController {
  constructor(
    private readonly certificationTestService: CertificationTestService,
  ) {}

  @Get()
  @ApiOperation({
    summary:
      "Get certification test (requires approved app + completed course)",
  })
  @ApiResponse({ status: 200, description: "Test or alreadyCertified" })
  async getTest(@Request() req: { user: { id: string } }) {
    return this.certificationTestService.getTest(req.user.id);
  }

  @Post("submit")
  @ApiOperation({ summary: "Submit certification test answers" })
  @ApiResponse({
    status: 200,
    description: "Result with passed, scorePercent, certified",
  })
  async submit(
    @Body() dto: SubmitCertificationTestDto,
    @Request() req: { user: { id: string } },
  ) {
    if (!Array.isArray(dto?.answers)) {
      return this.certificationTestService.submit(req.user.id, []);
    }
    return this.certificationTestService.submit(req.user.id, dto.answers);
  }

  @Get("insights")
  @ApiOperation({
    summary: "Get AI-generated insights and recommendations for the volunteer",
  })
  @ApiResponse({ status: 200, description: "summary and recommendations[]" })
  async getInsights(@Request() req: { user: { id: string } }) {
    return this.certificationTestService.getVolunteerInsights(req.user.id);
  }
}
