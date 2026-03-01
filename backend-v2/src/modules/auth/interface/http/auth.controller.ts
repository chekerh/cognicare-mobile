/**
 * Auth Controller - Interface Layer
 */
import {
  Controller,
  Post,
  Body,
  HttpStatus,
  HttpCode,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiOperation, ApiResponse, ApiConsumes } from '@nestjs/swagger';
import { Public } from '../../../../shared/decorators/public.decorator';
import {
  SendVerificationCodeDto,
  SignupDto,
  LoginDto,
  AuthResponseDto,
} from '../../application/dto/auth.dto';
import { SendVerificationCodeUseCase } from '../../application/use-cases/send-verification-code.use-case';
import { SignupUseCase } from '../../application/use-cases/signup.use-case';
import { LoginUseCase } from '../../application/use-cases/login.use-case';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(
    private readonly sendVerificationCodeUseCase: SendVerificationCodeUseCase,
    private readonly signupUseCase: SignupUseCase,
    private readonly loginUseCase: LoginUseCase,
  ) {}

  @Public()
  @Post('send-verification-code')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Send verification code to email' })
  @ApiResponse({ status: 200, description: 'Code sent successfully' })
  @ApiResponse({ status: 400, description: 'Email already registered' })
  async sendVerificationCode(@Body() dto: SendVerificationCodeDto) {
    const result = await this.sendVerificationCodeUseCase.execute(dto);
    
    if (result.isErr()) {
      throw new BadRequestException(result.error);
    }

    return result.value;
  }

  @Public()
  @Post('signup')
  @HttpCode(HttpStatus.CREATED)
  @UseInterceptors(FileInterceptor('certificate'))
  @ApiOperation({ summary: 'Create a new account' })
  @ApiConsumes('multipart/form-data')
  @ApiResponse({ status: 201, description: 'Account created', type: AuthResponseDto })
  @ApiResponse({ status: 400, description: 'Validation error' })
  async signup(
    @Body() dto: SignupDto,
    @UploadedFile() certificate?: Express.Multer.File,
  ) {
    const result = await this.signupUseCase.execute({
      ...dto,
      certificateBuffer: certificate?.buffer,
      certificateMimetype: certificate?.mimetype,
    });

    if (result.isErr()) {
      throw new BadRequestException(result.error);
    }

    return result.value;
  }

  @Public()
  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Login with email and password' })
  @ApiResponse({ status: 200, description: 'Login successful', type: AuthResponseDto })
  @ApiResponse({ status: 400, description: 'Invalid credentials' })
  async login(@Body() dto: LoginDto) {
    const result = await this.loginUseCase.execute(dto);

    if (result.isErr()) {
      throw new BadRequestException(result.error);
    }

    return result.value;
  }
}
