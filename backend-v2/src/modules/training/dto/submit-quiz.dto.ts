import { IsArray, IsNumber, IsOptional, IsString, Min } from "class-validator";

export class SubmitQuizDto {
  @IsArray()
  @IsNumber({}, { each: true })
  @Min(-1, { each: true })
  answers!: number[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  textAnswers?: string[];
}
