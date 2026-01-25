import { Controller, Get, Redirect } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AppService } from './app.service';

@ApiTags('app')
@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  @ApiOperation({
    summary: 'Welcome endpoint',
    description: 'Returns a welcome message for the CogniCare API'
  })
  @ApiResponse({
    status: 200,
    description: 'Welcome message',
    schema: {
      type: 'object',
      properties: {
        message: { type: 'string', example: 'Welcome to CogniCare API v1.0' },
        timestamp: { type: 'string', format: 'date-time' },
        documentation: { type: 'string', example: '/api' }
      }
    }
  })
  getWelcome() {
    return {
      message: 'Welcome to CogniCare API v1.0',
      timestamp: new Date().toISOString(),
      documentation: '/api'
    };
  }

  @Get('api')
  @Redirect('/api', 302)
  @ApiOperation({
    summary: 'API Documentation redirect',
    description: 'Redirects to Swagger API documentation'
  })
  getApiDocs() {
    // This will redirect to /api where Swagger is set up
  }
}
