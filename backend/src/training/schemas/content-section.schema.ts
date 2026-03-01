import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

@Schema({ _id: false })
export class ContentSection {
  @Prop({ default: 'text' })
  type: 'text' | 'image' | 'video' | 'definition' | 'list';

  @Prop()
  title?: string;

  @Prop()
  content?: string;

  @Prop()
  imageUrl?: string;

  @Prop()
  videoUrl?: string;

  /** For type 'definition': term -> definition */
  @Prop({ type: Map, of: String })
  definitions?: Record<string, string>;

  @Prop({ type: [String] })
  listItems?: string[];

  @Prop({ default: 0 })
  order: number;
}

export const ContentSectionSchema =
  SchemaFactory.createForClass(ContentSection);
