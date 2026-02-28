import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { Public } from '../auth/decorators/public.decorator';
import { IntegrationsService } from './integrations.service';
import { ExternalWebsite } from './schemas/external-website.schema';
import { ExternalProduct } from './schemas/external-product.schema';

@ApiTags('integrations')
@Controller('integrations')
export class IntegrationsController {
  constructor(private readonly integrationsService: IntegrationsService) {}

  @Public()
  @Get('websites')
  @ApiOperation({ summary: 'List integrated e-commerce websites' })
  @ApiResponse({ status: 200, description: 'List of websites (e.g. Books to Scrape, Bioherbs)' })
  async listWebsites(): Promise<ExternalWebsite[]> {
    return this.integrationsService.listWebsites();
  }

  @Public()
  @Get('websites/:slug')
  @ApiOperation({ summary: 'Get one website config' })
  async getWebsite(@Param('slug') slug: string): Promise<ExternalWebsite> {
    return this.integrationsService.getWebsite(slug);
  }

  @Public()
  @Get('websites/:slug/catalog')
  @ApiOperation({ summary: 'Get catalog (categories + products) for a website' })
  @ApiResponse({ status: 200, description: 'Categories and paginated products' })
  async getCatalog(
    @Param('slug') slug: string,
    @Query('category') categorySlug?: string,
    @Query('page') page?: string,
  ) {
    const pageNum = page ? parseInt(page, 10) : 1;
    return this.integrationsService.getCatalog(slug, categorySlug, pageNum);
  }

  @Public()
  @Get('websites/:slug/products/:externalId')
  @ApiOperation({ summary: 'Get product detail' })
  async getProduct(
    @Param('slug') slug: string,
    @Param('externalId') externalId: string,
  ): Promise<ExternalProduct> {
    return this.integrationsService.getProduct(slug, externalId);
  }

  @Public()
  @Get('websites/:slug/products/:externalId/refresh')
  @ApiOperation({ summary: 'Refresh product data from the live site' })
  async refreshProduct(
    @Param('slug') slug: string,
    @Param('externalId') externalId: string,
  ): Promise<ExternalProduct> {
    return this.integrationsService.refreshProduct(slug, externalId);
  }
}
