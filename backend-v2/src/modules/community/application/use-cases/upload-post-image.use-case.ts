import { Injectable } from '@nestjs/common';
import { IUseCase } from '../../../../core/application/use-case.interface';
import { Result, ok, err } from '../../../../core/application/result';

interface UploadPostImageInput {
  buffer: Buffer;
  mimetype: string;
}

@Injectable()
export class UploadPostImageUseCase implements IUseCase<UploadPostImageInput, Result<string, string>> {
  async execute(input: UploadPostImageInput): Promise<Result<string, string>> {
    try {
      // Try Cloudinary first, fallback to local storage
      let cloudinary: any;
      try {
        const { v2 } = await import('cloudinary');
        cloudinary = v2;
      } catch {
        // cloudinary not available
      }

      if (cloudinary && process.env.CLOUDINARY_CLOUD_NAME) {
        const crypto = await import('crypto');
        const publicId = `post-${crypto.randomUUID()}`;
        const url = await new Promise<string>((resolve, reject) => {
          const { Readable } = require('stream');
          const uploadStream = cloudinary.uploader.upload_stream(
            { folder: 'cognicare/posts', public_id: publicId, resource_type: 'image' },
            (uploadErr: any, result: any) => {
              if (uploadErr) return reject(uploadErr);
              if (!result?.secure_url) return reject(new Error('No URL returned'));
              resolve(result.secure_url);
            },
          );
          Readable.from(input.buffer).pipe(uploadStream);
        });
        return ok(url);
      }

      // Fallback: local storage
      const path = await import('path');
      const fs = await import('fs/promises');
      const crypto = await import('crypto');
      const uploadsDir = path.join(process.cwd(), 'uploads', 'posts');
      await fs.mkdir(uploadsDir, { recursive: true });
      const ext = input.mimetype === 'image/png' ? 'png' : input.mimetype === 'image/webp' ? 'webp' : 'jpg';
      const filename = `${crypto.randomUUID()}.${ext}`;
      const filePath = path.join(uploadsDir, filename);
      await fs.writeFile(filePath, input.buffer);
      return ok(`/uploads/posts/${filename}`);
    } catch (error) {
      return err(error instanceof Error ? error.message : 'Upload failed');
    }
  }
}
