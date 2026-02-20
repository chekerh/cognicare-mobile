import { IsNotEmpty, IsString, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreatePlanDto {
  @ApiProperty({
    description: 'ID of the child for this plan',
    example: '507f1f77bcf86cd799439011',
  })
  @IsNotEmpty()
  @IsString()
  childId!: string;

  @ApiProperty({
    description: 'Type of specialized plan',
    enum: ['PECS', 'TEACCH'],
    example: 'PECS',
  })
  @IsNotEmpty()
  @IsEnum(['PECS', 'TEACCH'])
  type!: 'PECS' | 'TEACCH';

  @ApiProperty({
    description: 'Title of the plan',
    example: 'Daily Communication Cards',
  })
  @IsNotEmpty()
  @IsString()
  title!: string;

  @ApiProperty({
    description: 'Plan content (structure varies by type)',
    example: { cards: [], activities: [] },
  })
  @IsNotEmpty()
  content!: any;
}
