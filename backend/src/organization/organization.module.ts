import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { OrganizationController } from './organization.controller';
import { OrganizationService } from './organization.service';
import {
  Organization,
  OrganizationSchema,
} from './schemas/organization.schema';
import { Invitation, InvitationSchema } from './schemas/invitation.schema';
import {
  PendingOrganization,
  PendingOrganizationSchema,
} from './schemas/pending-organization.schema';
import { User, UserSchema } from '../users/schemas/user.schema';
import { Child, ChildSchema } from '../children/schemas/child.schema';
import {
  SpecializedPlan,
  SpecializedPlanSchema,
} from '../specialized-plans/schemas/specialized-plan.schema';
import { MailModule } from '../mail/mail.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Organization.name, schema: OrganizationSchema },
      { name: Invitation.name, schema: InvitationSchema },
      { name: PendingOrganization.name, schema: PendingOrganizationSchema },
      { name: User.name, schema: UserSchema },
      { name: Child.name, schema: ChildSchema },
      { name: SpecializedPlan.name, schema: SpecializedPlanSchema },
    ]),
    MailModule,
  ],
  controllers: [OrganizationController],
  providers: [OrganizationService],
  exports: [OrganizationService],
})
export class OrganizationModule {}
