import { Controller, Get } from "@nestjs/common";
import { ApiTags, ApiOperation } from "@nestjs/swagger";
import { Public } from "@/shared/decorators/public.decorator";

@ApiTags("calls")
@Controller("calls")
export class CallsController {
  @Get("check")
  @Public()
  @ApiOperation({ summary: "Call config check" })
  checkConfig() {
    return { provider: "webrtc", signaling: "websocket" };
  }
}
