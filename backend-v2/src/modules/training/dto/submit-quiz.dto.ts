import { IsArray, IsNumber, Min } from "class-validator";

export class SubmitQuizDto {
  @IsArray()
  @IsNumber({}, { each: true })
  @Min(0, { each: true })
  answers!: number[];
}
