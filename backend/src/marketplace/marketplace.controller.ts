import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiQuery } from '@nestjs/swagger';
import { MarketplaceService } from './marketplace.service';

@ApiTags('marketplace')
@Controller('marketplace')
export class MarketplaceController {
  constructor(private readonly marketplaceService: MarketplaceService) {}

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
    await this.marketplaceService.seedIfEmpty();
    const limitNum = limit
      ? Math.min(100, Math.max(1, parseInt(limit, 10) || 20))
      : 20;
    const list = await this.marketplaceService.list(limitNum, category);
    return { products: list };
  }
}
