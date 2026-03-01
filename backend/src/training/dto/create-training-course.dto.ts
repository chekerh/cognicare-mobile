import { IsString, IsOptional, IsBoolean, IsArray, IsNumber, Min } from 'class-validator';

export class ContentSectionDto {
  type?: 'text' | 'image' | 'video' | 'definition' | 'list';
  title?: string;
  content?: string;
  imageUrl?: string;
  videoUrl?: string;
  definitions?: Record<string, string>;
  listItems?: string[];
  order?: number;
}

export class QuizQuestionDto {
  @IsString()
  question: string;

  @IsArray()
  @IsString({ each: true })
  options: string[];

  @IsNumber()
  @Min(0)
  correctIndex: number;

  @IsOptional()
  @IsNumber()
  order?: number;
}

export class CreateTrainingCourseDto {
  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsArray()
  contentSections?: ContentSectionDto[];

  @IsOptional()
  @IsString()
  sourceUrl?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  topics?: string[];

  @IsOptional()
  @IsArray()
  quiz?: QuizQuestionDto[];

  @IsOptional()
  @IsBoolean()
  approved?: boolean;

  @IsOptional()
  @IsNumber()
  order?: number;
}
