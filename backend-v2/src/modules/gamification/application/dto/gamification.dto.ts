import { IsEnum, IsNumber, IsOptional, Min, IsBoolean } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { GameType } from '../../domain/entities/gamification.entity';

export class RecordGameSessionDto {
  @ApiProperty({ enum: GameType }) @IsEnum(GameType) gameType!: GameType;
  @ApiProperty({ required: false }) @IsOptional() @IsNumber() @Min(1) level?: number;
  @ApiProperty() @IsBoolean() completed!: boolean;
  @ApiProperty({ required: false }) @IsOptional() @IsNumber() @Min(0) score?: number;
  @ApiProperty({ required: false }) @IsOptional() @IsNumber() @Min(0) timeSpentSeconds?: number;
  @ApiProperty({ required: false }) @IsOptional() metrics?: Record<string, number>;
}
