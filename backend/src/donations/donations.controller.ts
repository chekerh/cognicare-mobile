import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
  Request,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { DonationsService } from './donations.service';
import { CreateDonationDto } from './dto/create-donation.dto';

@ApiTags('donations')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller('donations')
export class DonationsController {
  constructor(private readonly donationsService: DonationsService) {}

  @Post('upload-image')
  @UseInterceptors(FileInterceptor('file'))
  @ApiOperation({ summary: 'Upload image for a donation' })
  async uploadImage(
    @UploadedFile()
    file?: {
      buffer: Buffer;
      mimetype: string;
    },
  ) {
    if (!file || !file.buffer)
      throw new BadRequestException('No file provided');
    const allowed = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/webp',
      'image/heic',
    ];
    let mimetype = (file.mimetype ?? '').toLowerCase();
    if (!mimetype || mimetype === 'application/octet-stream') {
      mimetype = 'image/jpeg';
    }
    if (!allowed.includes(mimetype) && !mimetype.startsWith('image/')) {
      throw new BadRequestException(
        'Invalid file type. Use JPEG, PNG or WebP.',
      );
    }
    const imageUrl = await this.donationsService.uploadDonationImage({
      buffer: file.buffer,
      mimetype: mimetype.startsWith('image/') ? mimetype : 'image/jpeg',
    });
    return { imageUrl };
  }

  @Post()
  @ApiOperation({ summary: 'Create a donation' })
  async create(
    @Request() req: { user: { id: string } },
    @Body() dto: CreateDonationDto,
  ) {
    return this.donationsService.create(req.user.id, dto);
  }

  @Get()
  @ApiOperation({ summary: 'List donations with filters' })
  async findAll(
    @Query('isOffer') isOffer?: string,
    @Query('category') category?: string,
    @Query('search') search?: string,
  ) {
    const filters: { isOffer?: boolean; category?: number; search?: string } =
      {};
    if (isOffer !== undefined && isOffer !== '') {
      filters.isOffer = isOffer === 'true';
    }
    if (category !== undefined && category !== '') {
      const c = parseInt(category, 10);
      if (!isNaN(c)) filters.category = c;
    }
    if (search !== undefined && search.trim() !== '') {
      filters.search = search.trim();
    }
    return this.donationsService.findAll(filters);
  }
}
