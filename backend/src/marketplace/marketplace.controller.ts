import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiQuery,
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { MarketplaceService } from './marketplace.service';
import { CreateProductDto } from './dto/create-product.dto';
import { CreateReviewDto } from './dto/create-review.dto';
import { Public } from '../auth/decorators/public.decorator';

@ApiTags('marketplace')
@Controller('marketplace')
export class MarketplaceController {
  constructor(private readonly marketplaceService: MarketplaceService) {}

  @Public()
  @Get('products')
  @ApiOperation({ summary: 'List products for family marketplace' })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    description: 'Max items (default 20)',
  })
  @ApiQuery({
    name: 'category',
    required: false,
    type: String,
    description: 'all | sensory | motor | cognitive',
  })
  @ApiResponse({ status: 200, description: 'List of products' })
  async getProducts(
    @Query('limit') limit?: string,
    @Query('category') category?: string,
  ) {
    const limitNum = limit
      ? Math.min(100, Math.max(1, parseInt(limit, 10) || 20))
      : 20;
    const list = await this.marketplaceService.list(limitNum, category);
    return { products: list };
  }

  @Get('products/mine')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'List only products created by the logged-in user' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'category', required: false, type: String })
  @ApiResponse({ status: 200, description: 'List of my products' })
  async getMyProducts(
    @Request() req: { user: { id: string } },
    @Query('limit') limit?: string,
    @Query('category') category?: string,
  ) {
    const limitNum = limit
      ? Math.min(100, Math.max(1, parseInt(limit, 10) || 50))
      : 50;
    const list = await this.marketplaceService.listBySeller(
      req.user.id,
      limitNum,
      category,
    );
    return { products: list };
  }

  @Public()
  @Get('products/:id')
  @ApiOperation({ summary: 'Get product by ID' })
  @ApiParam({ name: 'id', description: 'Product ID' })
  @ApiResponse({ status: 200, description: 'Product details' })
  @ApiResponse({ status: 404, description: 'Product not found' })
  async getProductById(@Param('id') id: string) {
    return this.marketplaceService.findById(id);
  }

  @Public()
  @Get('products/:id/reviews')
  @ApiOperation({ summary: 'List reviews for a product' })
  @ApiParam({ name: 'id', description: 'Product ID' })
  @ApiResponse({ status: 200, description: 'List of reviews' })
  async getProductReviews(@Param('id') id: string) {
    const reviews = await this.marketplaceService.listReviews(id);
    return { reviews };
  }

  @Post('products/:id/reviews')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Add or update my review for a product' })
  @ApiParam({ name: 'id', description: 'Product ID' })
  @ApiResponse({ status: 201, description: 'Review created or updated' })
  async createReview(
    @Request() req: { user: { id: string } },
    @Param('id') productId: string,
    @Body() dto: CreateReviewDto,
  ) {
    const review = await this.marketplaceService.createOrUpdateReview(
      productId,
      req.user.id,
      dto,
    );
    return {
      id: review._id.toString(),
      productId: review.productId.toString(),
      userId: review.userId.toString(),
      userName: review.userName,
      rating: review.rating,
      comment: review.comment,
      createdAt: review.createdAt,
      updatedAt: review.updatedAt,
    };
  }

  @Post('products/upload-image')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('file'))
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Upload image for a product' })
  async uploadImage(
    @UploadedFile()
    file?: { buffer: Buffer; mimetype: string },
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
    const imageUrl = await this.marketplaceService.uploadProductImage({
      buffer: file.buffer,
      mimetype: mimetype.startsWith('image/') ? mimetype : 'image/jpeg',
    });
    return { imageUrl };
  }

  @Post('products')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Create a product (sell)' })
  @ApiResponse({ status: 201, description: 'Product created' })
  async create(
    @Request() req: { user: { id: string } },
    @Body() dto: CreateProductDto,
  ) {
    const product = await this.marketplaceService.create(req.user.id, dto);
    return {
      id: product._id.toString(),
      sellerId: product.sellerId?.toString(),
      title: product.title,
      price: product.price,
      imageUrl: product.imageUrl,
      description: product.description,
      badge: product.badge,
      category: product.category,
      order: product.order,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    };
  }
}
