import { IsEnum, IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { GameType } from '../schemas/game-session.schema';

export class RecordGameSessionDto {
  @ApiProperty({ enum: GameType, description: 'Type of game played' })
  @IsEnum(GameType)
  gameType: GameType;

  @ApiProperty({ required: false, description: 'Level within the game' })
  @IsOptional()
  @IsNumber()
  @Min(1)
  level?: number;

  @ApiProperty({ description: 'Did the child complete/win the game?' })
  completed: boolean;

  @ApiProperty({ required: false, description: 'Score/points earned' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  score?: number;

  @ApiProperty({ required: false, description: 'Time spent in seconds' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  timeSpentSeconds?: number;

  @ApiProperty({ required: false, description: 'Additional metrics (matches, errors, etc.)' })
  @IsOptional()
  metrics?: Record<string, number>;
}
