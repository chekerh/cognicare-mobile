import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class RequestParentFeedbackDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  recommendationId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  message?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  planType?: string;
}
