import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";

@Schema({ _id: false })
export class ContentSection {
  @Prop({ default: "text" }) type!:
    | "text"
    | "image"
    | "video"
    | "definition"
    | "list";
  @Prop() title?: string;
  @Prop() content?: string;
  @Prop() imageUrl?: string;
  @Prop() videoUrl?: string;
  @Prop({ type: Map, of: String }) definitions?: Record<string, string>;
  @Prop({ type: [String] }) listItems?: string[];
  @Prop({ default: 0 }) order!: number;
}
export const ContentSectionSchema =
  SchemaFactory.createForClass(ContentSection);

@Schema({ _id: false })
export class QuizQuestion {
  @Prop({ required: true }) question!: string;
  @Prop({ type: [String], required: true }) options!: string[];
  @Prop({ required: true }) correctIndex!: number;
  @Prop({ default: 0 }) order!: number;
}
export const QuizQuestionSchema = SchemaFactory.createForClass(QuizQuestion);
