import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, IsBoolean, IsArray } from 'class-validator';

export class SendMessageDto {
  @ApiProperty() @IsString() text!: string;
  @ApiPropertyOptional() @IsOptional() @IsString() attachmentUrl?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() attachmentType?: string;
}

export class CreateGroupDto {
  @ApiProperty() @IsString() name!: string;
  @ApiPropertyOptional() @IsOptional() @IsString() imageUrl?: string;
  @ApiProperty({ type: [String] }) @IsArray() @IsString({ each: true }) participantIds!: string[];
}

export class UpdateSettingsDto {
  @ApiPropertyOptional() @IsOptional() @IsBoolean() autoSavePhotos?: boolean;
  @ApiPropertyOptional() @IsOptional() @IsBoolean() muted?: boolean;
}
