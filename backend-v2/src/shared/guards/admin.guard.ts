/**
 * Admin Guard - Shared Infrastructure
 */
import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';

@Injectable()
export class AdminGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('Access denied: Authentication required');
    }

    if (user.role?.toLowerCase() !== 'admin') {
      throw new ForbiddenException('Access denied: Admin privileges required');
    }

    return true;
  }
}
