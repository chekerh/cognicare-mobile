import { IsString, IsNumber, IsBoolean, IsArray, IsOptional, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

export class CreateDonationDto {
  @ApiProperty() @IsString() title!: string;
  @ApiProperty() @IsString() description!: string;
  @ApiProperty() @IsNumber() @Min(0) @Max(2) @Type(() => Number) category!: number;
  @ApiProperty() @IsNumber() @Min(0) @Max(2) @Type(() => Number) condition!: number;
  @ApiProperty() @IsString() location!: string;
  @ApiProperty({ required: false }) @IsOptional() @IsNumber() @Type(() => Number) latitude?: number;
  @ApiProperty({ required: false }) @IsOptional() @IsNumber() @Type(() => Number) longitude?: number;
  @ApiProperty({ required: false }) @IsOptional() @IsString() suitableAge?: string;
  @ApiProperty({ required: false }) @IsOptional() @IsBoolean() @Type(() => Boolean) isOffer?: boolean;
  @ApiProperty({ required: false }) @IsOptional() @IsArray() @IsString({ each: true }) imageUrls?: string[];
}
