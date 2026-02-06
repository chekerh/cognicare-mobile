import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, IsArray, MaxLength } from 'class-validator';

export class CreatePostDto {
  @ApiProperty({ description: 'Post text content' })
  @IsString()
  @MaxLength(2000)
  text: string;

  @ApiPropertyOptional({ description: 'URL of attached image (optional)' })
  @IsOptional()
  @IsString()
  imageUrl?: string;

  @ApiPropertyOptional({ description: 'Tags for the post', type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tags?: string[];
}
