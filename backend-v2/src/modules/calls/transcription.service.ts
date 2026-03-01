import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class TranscriptionService implements OnModuleInit {
  private readonly logger = new Logger(TranscriptionService.name);
  private deepgram: any;

  constructor(private config: ConfigService) {}

  onModuleInit() {
    const apiKey = this.config.get<string>('DEEPGRAM_API_KEY');
    if (!apiKey) { this.logger.warn('DEEPGRAM_API_KEY not found. Transcription disabled.'); return; }
    try {
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const { createClient } = require('@deepgram/sdk');
      this.deepgram = createClient(apiKey);
      this.logger.log('Deepgram client initialized.');
    } catch (error: any) { this.logger.error(`Failed to init Deepgram: ${error.message}`); }
  }

  createStream(callbacks: { onTranscription: (text: string, isFinal: boolean) => void; onError: (error: any) => void }): any {
    if (!this.deepgram) { this.logger.error('Deepgram not initialized'); return null; }
    try {
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const { LiveTranscriptionEvents } = require('@deepgram/sdk');
      const connection = this.deepgram.listen.live({
        model: 'nova-2', language: 'multi', smart_format: true, interim_results: true,
        encoding: 'linear16', sample_rate: 16000, endpointing: 100,
      });
      connection.on(LiveTranscriptionEvents.Transcript, (data: any) => {
        const transcript = data.channel.alternatives[0].transcript;
        if (transcript) callbacks.onTranscription(transcript, data.is_final);
      });
      connection.on(LiveTranscriptionEvents.Error, (err: any) => { this.logger.error(`Deepgram Error: ${err.message}`); callbacks.onError(err); });
      connection.on(LiveTranscriptionEvents.Close, () => this.logger.log('Deepgram connection closed'));
      return {
        write: (chunk: Buffer) => { if (connection.getReadyState() === 1) connection.send(chunk.buffer.slice(chunk.byteOffset, chunk.byteOffset + chunk.byteLength)); },
        end: () => connection.finish(),
      };
    } catch (error: any) { this.logger.error(`Failed to create Deepgram stream: ${error.message}`); callbacks.onError(error); return null; }
  }
}
