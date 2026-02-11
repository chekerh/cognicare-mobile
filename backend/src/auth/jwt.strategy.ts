import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User, UserDocument } from '../users/schemas/user.schema';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private configService: ConfigService,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey:
        configService.get<string>('JWT_SECRET') || 'fallback-secret-key',
    });
  }

  async validate(payload: { sub: string | { toString?: () => string }; email: string; role: string }) {
    const sub = payload.sub;
    const userId =
      typeof sub === 'string' ? sub : sub?.toString?.() ?? String(sub);
    const user = await this.userModel.findById(userId);

    if (!user) {
      throw new UnauthorizedException();
    }

    return {
      id: user._id.toString(),
      email: user.email,
      role: user.role,
    };
  }
}
