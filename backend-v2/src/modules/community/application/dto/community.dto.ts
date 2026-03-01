import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { IsString, IsOptional, IsArray, MaxLength } from "class-validator";

export class CreatePostDto {
  @ApiProperty({ description: "Post text content" })
  @IsString()
  @MaxLength(2000)
  text!: string;

  @ApiPropertyOptional({ description: "URL of attached image" })
  @IsOptional()
  @IsString()
  imageUrl?: string;

  @ApiPropertyOptional({ description: "Tags for the post", type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tags?: string[];
}

export class UpdatePostDto {
  @ApiPropertyOptional({ description: "Updated post text" })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  text?: string;

  @ApiPropertyOptional({ description: "Updated image URL" })
  @IsOptional()
  @IsString()
  imageUrl?: string;

  @ApiPropertyOptional({ description: "Updated tags", type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tags?: string[];
}

export class CreateCommentDto {
  @ApiProperty({ description: "Comment text" })
  @IsString()
  @MaxLength(500)
  text!: string;
}

export class PostOutputDto {
  id!: string;
  authorId!: string;
  authorName!: string;
  text!: string;
  createdAt!: string;
  hasImage!: boolean;
  imagePath!: string | null;
  imageUrl?: string;
  tags!: string[];
  likeCount!: number;
}

export class CommentOutputDto {
  authorName!: string;
  text!: string;
  createdAt!: string;
}
