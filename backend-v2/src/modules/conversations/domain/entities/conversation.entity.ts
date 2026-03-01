import { Entity } from "../../../../core/domain/entity.base";

export type ConversationSegment =
  | "persons"
  | "families"
  | "benevole"
  | "healthcare";

export interface ConversationProps {
  userId: string;
  name: string;
  subtitle?: string;
  lastMessage: string;
  timeAgo: string;
  imageUrl: string;
  unread: boolean;
  segment: ConversationSegment;
  threadId?: string;
  otherUserId?: string;
  participants?: string[];
  createdAt?: Date;
  updatedAt?: Date;
}

export class ConversationEntity extends Entity<string> {
  private props: ConversationProps;
  private constructor(id: string, props: ConversationProps) {
    super(id);
    this.props = props;
  }

  static create(props: ConversationProps, id?: string): ConversationEntity {
    return new ConversationEntity(id ?? Entity.generateId(), {
      ...props,
      unread: props.unread ?? false,
      segment: props.segment ?? "persons",
      createdAt: props.createdAt ?? new Date(),
      updatedAt: props.updatedAt ?? new Date(),
    });
  }

  static reconstitute(
    id: string,
    props: ConversationProps,
  ): ConversationEntity {
    return new ConversationEntity(id, props);
  }

  get userId(): string {
    return this.props.userId;
  }
  get name(): string {
    return this.props.name;
  }
  get subtitle(): string | undefined {
    return this.props.subtitle;
  }
  get lastMessage(): string {
    return this.props.lastMessage;
  }
  get timeAgo(): string {
    return this.props.timeAgo;
  }
  get imageUrl(): string {
    return this.props.imageUrl;
  }
  get unread(): boolean {
    return this.props.unread;
  }
  get segment(): ConversationSegment {
    return this.props.segment;
  }
  get threadId(): string | undefined {
    return this.props.threadId;
  }
  get otherUserId(): string | undefined {
    return this.props.otherUserId;
  }
  get participants(): string[] | undefined {
    return this.props.participants;
  }
  get createdAt(): Date | undefined {
    return this.props.createdAt;
  }
  get updatedAt(): Date | undefined {
    return this.props.updatedAt;
  }

  updateLastMessage(text: string): void {
    this.props.lastMessage = text;
    this.props.timeAgo = "just now";
    this.props.updatedAt = new Date();
  }

  markRead(): void {
    this.props.unread = false;
  }
  markUnread(): void {
    this.props.unread = true;
  }

  addParticipant(userId: string): void {
    if (!this.props.participants) this.props.participants = [];
    if (!this.props.participants.includes(userId))
      this.props.participants.push(userId);
  }

  toObject(): ConversationProps & { id: string } {
    return { id: this.id, ...this.props };
  }
}

export type AttachmentType = "image" | "voice" | "call_missed" | "call_summary";

export interface MessageProps {
  threadId: string;
  senderId: string;
  text: string;
  attachmentUrl?: string;
  attachmentType?: AttachmentType;
  callDuration?: number;
  createdAt?: Date;
  updatedAt?: Date;
}

export class MessageEntity extends Entity<string> {
  private props: MessageProps;
  private constructor(id: string, props: MessageProps) {
    super(id);
    this.props = props;
  }

  static create(props: MessageProps, id?: string): MessageEntity {
    return new MessageEntity(id ?? Entity.generateId(), {
      ...props,
      createdAt: props.createdAt ?? new Date(),
      updatedAt: props.updatedAt ?? new Date(),
    });
  }

  static reconstitute(id: string, props: MessageProps): MessageEntity {
    return new MessageEntity(id, props);
  }

  get threadId(): string {
    return this.props.threadId;
  }
  get senderId(): string {
    return this.props.senderId;
  }
  get text(): string {
    return this.props.text;
  }
  get attachmentUrl(): string | undefined {
    return this.props.attachmentUrl;
  }
  get attachmentType(): AttachmentType | undefined {
    return this.props.attachmentType;
  }
  get callDuration(): number | undefined {
    return this.props.callDuration;
  }
  get createdAt(): Date | undefined {
    return this.props.createdAt;
  }
  get updatedAt(): Date | undefined {
    return this.props.updatedAt;
  }

  toObject(): MessageProps & { id: string } {
    return { id: this.id, ...this.props };
  }
}

export interface ConversationSettingProps {
  userId: string;
  conversationId: string;
  autoSavePhotos: boolean;
  muted: boolean;
}

export class ConversationSettingEntity extends Entity<string> {
  private props: ConversationSettingProps;
  private constructor(id: string, props: ConversationSettingProps) {
    super(id);
    this.props = props;
  }

  static create(
    props: ConversationSettingProps,
    id?: string,
  ): ConversationSettingEntity {
    return new ConversationSettingEntity(id ?? Entity.generateId(), props);
  }

  static reconstitute(
    id: string,
    props: ConversationSettingProps,
  ): ConversationSettingEntity {
    return new ConversationSettingEntity(id, props);
  }

  get userId(): string {
    return this.props.userId;
  }
  get conversationId(): string {
    return this.props.conversationId;
  }
  get autoSavePhotos(): boolean {
    return this.props.autoSavePhotos;
  }
  get muted(): boolean {
    return this.props.muted;
  }

  update(data: { autoSavePhotos?: boolean; muted?: boolean }): void {
    if (data.autoSavePhotos !== undefined)
      this.props.autoSavePhotos = data.autoSavePhotos;
    if (data.muted !== undefined) this.props.muted = data.muted;
  }

  toObject(): ConversationSettingProps & { id: string } {
    return { id: this.id, ...this.props };
  }
}
