import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import {
  HealthCheck,
  HealthCheckService,
  MongooseHealthIndicator,
} from '@nestjs/terminus';

@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private mongoose: MongooseHealthIndicator,
  ) {}

  @Get()
  @ApiOperation({
    summary: 'Health check',
    description: 'Check the health status of the application and its dependencies',
  })
  @ApiResponse({
    status: 200,
    description: 'Application is healthy',
    schema: {
      type: 'object',
      properties: {
        status: { type: 'string', example: 'ok' },
        details: {
          type: 'object',
          properties: {
            mongodb: {
              type: 'object',
              properties: {
                status: { type: 'string', example: 'up' }
              }
            }
          }
        }
      }
    }
  })
  @ApiResponse({ status: 503, description: 'Service unavailable' })
  @HealthCheck()
  check() {
    return this.health.check([
      () => this.mongoose.pingCheck('mongodb'),
    ]);
  }
}