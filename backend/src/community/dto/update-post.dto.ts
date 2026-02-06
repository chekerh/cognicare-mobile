import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsArray, MaxLength } from 'class-validator';

export class UpdatePostDto {
  @ApiPropertyOptional({ description: 'Updated post text' })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  text?: string;

  @ApiPropertyOptional({ description: 'Updated image URL' })
  @IsOptional()
  @IsString()
  imageUrl?: string;

  @ApiPropertyOptional({ description: 'Updated tags', type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tags?: string[];
}
