import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  Request,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  NotFoundException,
} from "@nestjs/common";
import { FileInterceptor } from "@nestjs/platform-express";
import { ApiTags, ApiBearerAuth, ApiOperation } from "@nestjs/swagger";
import {
  SendMessageDto,
  CreateGroupDto,
  UpdateSettingsDto,
} from "../../application/dto/conversation.dto";
import {
  GetInboxUseCase,
  GetOrCreateConversationUseCase,
  GetMessagesUseCase,
  SendMessageUseCase,
  DeleteConversationUseCase,
  CreateGroupUseCase,
  AddMemberToGroupUseCase,
  GetSettingsUseCase,
  UpdateSettingsUseCase,
  GetMediaUseCase,
  SearchMessagesUseCase,
  UploadAttachmentUseCase,
} from "../../application/use-cases/conversation.use-cases";

@ApiTags("conversations")
@ApiBearerAuth("JWT-auth")
@Controller("conversations")
export class ConversationsController {
  constructor(
    private readonly getInboxUC: GetInboxUseCase,
    private readonly getOrCreateUC: GetOrCreateConversationUseCase,
    private readonly getMessagesUC: GetMessagesUseCase,
    private readonly sendMessageUC: SendMessageUseCase,
    private readonly deleteConvUC: DeleteConversationUseCase,
    private readonly createGroupUC: CreateGroupUseCase,
    private readonly addMemberUC: AddMemberToGroupUseCase,
    private readonly getSettingsUC: GetSettingsUseCase,
    private readonly updateSettingsUC: UpdateSettingsUseCase,
    private readonly getMediaUC: GetMediaUseCase,
    private readonly searchMsgUC: SearchMessagesUseCase,
    private readonly uploadAttachmentUC: UploadAttachmentUseCase,
  ) {}

  @Get("inbox")
  async getInbox(@Request() req: { user: { id: string } }) {
    return (await this.getInboxUC.execute(req.user.id)).value;
  }

  @Get("by-participant/:otherUserId")
  async getOrCreateConversation(
    @Request() req: { user: { id: string; fullName?: string } },
    @Param("otherUserId") otherUserId: string,
  ) {
    const result = await this.getOrCreateUC.execute({
      userId: req.user.id,
      otherUserId,
      userName: req.user.fullName ?? "",
      otherName: "",
    });
    if (result.isFailure) throw new NotFoundException(result.error);
    return result.value;
  }

  @Post("groups")
  @ApiOperation({ summary: "Create group conversation" })
  async createGroup(
    @Request() req: { user: { id: string } },
    @Body() dto: CreateGroupDto,
  ) {
    const result = await this.createGroupUC.execute({
      userId: req.user.id,
      name: dto.name,
      imageUrl: dto.imageUrl,
      participantIds: dto.participantIds,
    });
    if (result.isFailure) throw new BadRequestException(result.error);
    return result.value;
  }

  @Post(":id/members")
  async addMemberToGroup(
    @Request() req: { user: { id: string } },
    @Param("id") id: string,
    @Body("userId") userId: string,
  ) {
    const result = await this.addMemberUC.execute({
      conversationId: id,
      userId,
    });
    if (result.isFailure) throw new NotFoundException(result.error);
    return { success: true };
  }

  @Get(":id/settings")
  async getSettings(
    @Request() req: { user: { id: string } },
    @Param("id") id: string,
  ) {
    return (
      await this.getSettingsUC.execute({
        userId: req.user.id,
        conversationId: id,
      })
    ).value;
  }

  @Patch(":id/settings")
  async updateSettings(
    @Request() req: { user: { id: string } },
    @Param("id") id: string,
    @Body() dto: UpdateSettingsDto,
  ) {
    return (
      await this.updateSettingsUC.execute({
        userId: req.user.id,
        conversationId: id,
        data: dto,
      })
    ).value;
  }

  @Get(":id/media")
  async getMedia(
    @Request() req: { user: { id: string } },
    @Param("id") id: string,
  ) {
    return (
      await this.getMediaUC.execute({ conversationId: id, userId: req.user.id })
    ).value;
  }

  @Get(":id/search")
  async searchMessages(
    @Request() req: { user: { id: string } },
    @Param("id") id: string,
    @Query("q") q: string,
  ) {
    return (
      await this.searchMsgUC.execute({
        conversationId: id,
        userId: req.user.id,
        query: q ?? "",
      })
    ).value;
  }

  @Get(":id/messages")
  async getMessages(
    @Request() req: { user: { id: string } },
    @Param("id") id: string,
  ) {
    const result = await this.getMessagesUC.execute({
      conversationId: id,
      userId: req.user.id,
    });
    if (result.isFailure) throw new NotFoundException(result.error);
    return result.value;
  }

  @Post("upload")
  @UseInterceptors(FileInterceptor("file"))
  async uploadAttachment(
    @UploadedFile() file?: { buffer: Buffer; mimetype: string },
  ) {
    if (!file?.buffer) throw new BadRequestException("No file");
    const result = await this.uploadAttachmentUC.execute({
      buffer: file.buffer,
      mimetype: file.mimetype,
    });
    if (result.isFailure) throw new BadRequestException(result.error);
    return { url: result.value };
  }

  @Post(":id/messages")
  async sendMessage(
    @Request() req: { user: { id: string } },
    @Param("id") id: string,
    @Body() dto: SendMessageDto,
  ) {
    const result = await this.sendMessageUC.execute({
      conversationId: id,
      userId: req.user.id,
      text: dto.text,
      attachmentUrl: dto.attachmentUrl,
      attachmentType: dto.attachmentType,
    });
    if (result.isFailure) throw new NotFoundException(result.error);
    return result.value;
  }

  @Delete(":id")
  async deleteConversation(
    @Request() req: { user: { id: string } },
    @Param("id") id: string,
  ) {
    const result = await this.deleteConvUC.execute({
      conversationId: id,
      userId: req.user.id,
    });
    if (result.isFailure) throw new NotFoundException(result.error);
    return { success: true };
  }
}
