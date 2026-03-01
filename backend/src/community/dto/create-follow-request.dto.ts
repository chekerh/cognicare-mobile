import { IsString, IsMongoId } from 'class-validator';

export class CreateFollowRequestDto {
  @IsString()
  @IsMongoId()
  targetUserId: string;
}
