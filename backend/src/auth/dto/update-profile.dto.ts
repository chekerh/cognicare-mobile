import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateProfileDto {
  @ApiPropertyOptional({ description: "User's full name" })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  fullName?: string;

  @ApiPropertyOptional({ description: "User's phone number" })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  phone?: string;

  @ApiPropertyOptional({
    description: 'Profile picture URL or path (e.g. from upload)',
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  profilePic?: string;

  @ApiPropertyOptional({ description: "User's location (address or city)" })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  location?: string;

  @ApiPropertyOptional({ description: 'Latitude of user location' })
  @IsOptional()
  locationLat?: number;

  @ApiPropertyOptional({ description: 'Longitude of user location' })
  @IsOptional()
  locationLng?: number;
}
