import { Entity } from "../../../../core/entity.base";

export interface NotificationProps {
  userId: string;
  type: string;
  title: string;
  description: string;
  read: boolean;
  data?: Record<string, unknown>;
  createdAt?: Date;
  updatedAt?: Date;
}

export class NotificationEntity extends Entity {
  private props: NotificationProps;
  private constructor(props: NotificationProps, id: string) {
    super(id);
    this.props = props;
  }
  static create(props: Omit<NotificationProps, "read">): NotificationEntity {
    return new NotificationEntity(
      { ...props, read: false },
      Entity.generateId(),
    );
  }
  static reconstitute(
    id: string,
    props: NotificationProps,
  ): NotificationEntity {
    return new NotificationEntity(props, id);
  }

  get userId() {
    return this.props.userId;
  }
  get type() {
    return this.props.type;
  }
  get title() {
    return this.props.title;
  }
  get description() {
    return this.props.description;
  }
  get read() {
    return this.props.read;
  }
  get data() {
    return this.props.data;
  }
  get createdAt() {
    return this.props.createdAt;
  }

  markRead(): void {
    this.props.read = true;
  }
}
