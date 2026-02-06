import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength } from 'class-validator';

export class CreateCommentDto {
  @ApiProperty({ description: 'Comment text' })
  @IsString()
  @MaxLength(500)
  text: string;
}
