import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, IsNumber, IsInt, Min, Max, IsArray } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateProductDto {
  @ApiProperty() @IsString() title!: string;
  @ApiProperty() @IsString() price!: string;
  @ApiProperty() @IsString() imageUrl!: string;
  @ApiPropertyOptional() @IsOptional() @IsString() description?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() badge?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() category?: string;
  @ApiPropertyOptional() @IsOptional() @IsNumber() @Min(0) @Type(() => Number) order?: number;
}

export class CreateReviewDto {
  @ApiProperty() @IsInt() @Min(1) @Max(5) @Type(() => Number) rating!: number;
  @ApiPropertyOptional() @IsOptional() @IsString() comment?: string;
}
