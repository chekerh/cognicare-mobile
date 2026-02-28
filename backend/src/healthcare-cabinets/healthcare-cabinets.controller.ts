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
      'Returns healthcare cabinets (orthophonistes, pédopsychiatres, centres autisme, etc.) in Tunisia for the family map.',
  })
  @ApiResponse({ status: 200, description: 'List of healthcare cabinets' })
  async findAll(): Promise<HealthcareCabinet[]> {
    return this.healthcareCabinetsService.findAll();
  }
}
