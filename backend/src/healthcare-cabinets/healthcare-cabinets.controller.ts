import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { HealthcareCabinetsService } from './healthcare-cabinets.service';
import { HealthcareCabinet } from './schemas/healthcare-cabinet.schema';
import { Public } from '../auth/decorators/public.decorator';

@ApiTags('healthcare-cabinets')
@Controller('healthcare-cabinets')
export class HealthcareCabinetsController {
  constructor(
    private readonly healthcareCabinetsService: HealthcareCabinetsService,
  ) {}

  @Public()
  @Get()
  @ApiOperation({
    summary: 'List cabinets and centres in Tunisia',
    description:
      'Returns healthcare cabinets and centres in Tunisia for the family map. Data from OpenStreetMap (Overpass) after GET /refresh, or seed minimal if empty.',
  })
  @ApiResponse({ status: 200, description: 'List of healthcare cabinets' })
  async findAll(): Promise<HealthcareCabinet[]> {
    return this.healthcareCabinetsService.findAll();
  }

  @Public()
  @Get('refresh')
  @ApiOperation({
    summary: 'Refresh cabinets from OpenStreetMap (Overpass API)',
    description:
      'Fetches healthcare facilities in Tunisia from OpenStreetMap (free, no API key). Returns the full list after upsert.',
  })
  @ApiResponse({ status: 200, description: 'List of healthcare cabinets after refresh' })
  async refresh(): Promise<{ added: number; total: number; cabinets: HealthcareCabinet[] }> {
    const { added, total } =
      await this.healthcareCabinetsService.fetchFromOverpassAndUpsert();
    const cabinets = await this.healthcareCabinetsService.findAll();
    return { added, total, cabinets };
  }
}
