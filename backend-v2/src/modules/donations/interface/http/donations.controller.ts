import {
  Controller, Get, Post, Body, Query, Request, UseInterceptors,
  UploadedFile, BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { CreateDonationDto } from '../../application/dto/donation.dto';
import {
  CreateDonationUseCase, ListDonationsUseCase, UploadDonationImageUseCase,
} from '../../application/use-cases/donation.use-cases';

@ApiTags('donations')
@ApiBearerAuth('JWT-auth')
@Controller('donations')
export class DonationsController {
  constructor(
    private readonly createUC: CreateDonationUseCase,
    private readonly listUC: ListDonationsUseCase,
    private readonly uploadUC: UploadDonationImageUseCase,
  ) {}

  @Post('upload-image')
  @UseInterceptors(FileInterceptor('file'))
  @ApiOperation({ summary: 'Upload image for a donation' })
  async uploadImage(@UploadedFile() file?: { buffer: Buffer; mimetype: string }) {
    if (!file?.buffer) throw new BadRequestException('No file provided');
    const allowed = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/heic'];
    let mimetype = (file.mimetype ?? '').toLowerCase();
    if (!mimetype || mimetype === 'application/octet-stream') mimetype = 'image/jpeg';
    if (!allowed.includes(mimetype) && !mimetype.startsWith('image/')) {
      throw new BadRequestException('Invalid file type. Use JPEG, PNG or WebP.');
    }
    const result = await this.uploadUC.execute({ buffer: file.buffer, mimetype });
    if (result.isFailure) throw new BadRequestException(result.error);
    return { imageUrl: result.value };
  }

  @Post()
  @ApiOperation({ summary: 'Create a donation' })
  async create(@Request() req: { user: { id: string; fullName?: string } }, @Body() dto: CreateDonationDto) {
    const result = await this.createUC.execute(req.user.id, req.user.fullName ?? '', dto);
    return result.value;
  }

  @Get()
  @ApiOperation({ summary: 'List donations with filters' })
  async findAll(
    @Query('isOffer') isOffer?: string,
    @Query('category') category?: string,
    @Query('search') search?: string,
  ) {
    const filters: { isOffer?: boolean; category?: number; search?: string } = {};
    if (isOffer !== undefined && isOffer !== '') filters.isOffer = isOffer === 'true';
    if (category !== undefined && category !== '') {
      const c = parseInt(category, 10);
      if (!isNaN(c)) filters.category = c;
    }
    if (search?.trim()) filters.search = search.trim();
    const result = await this.listUC.execute(filters);
    return result.value;
  }
}
