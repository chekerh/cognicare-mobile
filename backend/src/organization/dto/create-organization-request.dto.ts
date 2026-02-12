import { IsNotEmpty, IsString, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateOrganizationRequestDto {
  @ApiProperty({
    description: 'Organization name',
    example: 'Hope Care Center',
  })
  @IsNotEmpty()
  @IsString()
  organizationName!: string;

  @ApiPropertyOptional({
    description: 'Brief description of the organization',
    example: 'A community center focused on cognitive health support',
  })
  @IsOptional()
  @IsString()
  description?: string;
}
