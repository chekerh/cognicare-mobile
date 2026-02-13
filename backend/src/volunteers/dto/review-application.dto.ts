import { IsEnum, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ReviewApplicationDto {
  @ApiProperty({
    description: 'Review decision',
    enum: ['approved', 'denied'],
  })
  @IsEnum(['approved', 'denied'])
  decision!: 'approved' | 'denied';

  @ApiPropertyOptional({
    description:
      'Reason for denial (required when decision is denied). Shown to volunteer and can include link to qualification course.',
  })
  @IsOptional()
  @IsString()
  deniedReason?: string;
}
