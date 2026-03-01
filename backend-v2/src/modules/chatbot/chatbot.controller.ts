import { Body, Controller, Post, Req, UseGuards } from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";
import { JwtAuthGuard } from "@/shared/guards/jwt-auth.guard";
import { ChatbotService, ChatMessage } from "./chatbot.service";

class ChatDto {
  message!: string;
  history?: ChatMessage[];
}

@ApiTags("Chatbot")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("chatbot")
export class ChatbotController {
  constructor(private readonly chatbotService: ChatbotService) {}

  @Post("chat")
  @ApiOperation({ summary: "Send a message to Cogni chatbot" })
  async chat(@Req() req: any, @Body() body: ChatDto) {
    const reply = await this.chatbotService.chat(
      req.user.userId,
      body.message,
      body.history ?? [],
    );
    return { reply };
  }
}
