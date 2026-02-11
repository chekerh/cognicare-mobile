import { Injectable } from '@nestjs/common';
import { Readable } from 'stream';
import { v2 as cloudinary } from 'cloudinary';

@Injectable()
export class CloudinaryService {
  private configured = false;

  constructor() {
    const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
    const apiKey = process.env.CLOUDINARY_API_KEY;
    const apiSecret = process.env.CLOUDINARY_API_SECRET;
    if (cloudName && apiKey && apiSecret) {
      cloudinary.config({
        cloud_name: cloudName,
        api_key: apiKey,
        api_secret: apiSecret,
      });
      this.configured = true;
    }
  }

  isConfigured(): boolean {
    return this.configured;
  }

  /**
   * Upload image from buffer. Returns the public URL (secure_url).
   * Throws if Cloudinary is not configured.
   */
  async uploadBuffer(
    buffer: Buffer,
    options: { folder: string; publicId?: string },
  ): Promise<string> {
    if (!this.configured) {
      throw new Error(
        'Cloudinary is not configured. Set CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET.',
      );
    }
    return new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          folder: options.folder,
          public_id: options.publicId,
          resource_type: 'image',
        },
        (err, result) => {
          if (err) {
            const error: Error =
              err instanceof Error
                ? err
                : new Error(
                    typeof (err as { message?: string })?.message === 'string'
                      ? (err as { message: string }).message
                      : 'Cloudinary upload failed',
                  );
            reject(error);
            return;
          }
          if (!result?.secure_url) {
            reject(new Error('Cloudinary did not return a URL'));
            return;
          }
          resolve(result.secure_url);
        },
      );
      const readStream = Readable.from(buffer);
      readStream.pipe(uploadStream);
    });
  }
}
