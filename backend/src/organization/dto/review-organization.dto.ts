import { IsEnum, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ReviewOrganizationDto {
  @ApiProperty({
    description: 'Review decision',
    enum: ['approved', 'rejected'],
    example: 'approved',
  })
  @IsEnum(['approved', 'rejected'])
  decision!: 'approved' | 'rejected';

  @ApiPropertyOptional({
    description: 'Reason for rejection (required if decision is rejected)',
    example: 'Organization does not meet eligibility criteria',
  })
  @IsOptional()
  @IsString()
  rejectionReason?: string;
}
