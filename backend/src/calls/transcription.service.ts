import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, LiveClient, LiveTranscriptionEvents } from '@deepgram/sdk';

@Injectable()
export class TranscriptionService implements OnModuleInit {
    private readonly logger = new Logger(TranscriptionService.name);
    private deepgram: any;

    constructor(private config: ConfigService) { }

    onModuleInit() {
        const apiKey = this.config.get<string>('DEEPGRAM_API_KEY');
        if (!apiKey) {
            this.logger.warn('DEEPGRAM_API_KEY not found. Transcription will be disabled.');
            return;
        }

        try {
            this.deepgram = createClient(apiKey);
            this.logger.log('Deepgram client initialized successfully.');
        } catch (error) {
            this.logger.error(`Failed to initialize Deepgram client: ${error.message}`);
        }
    }

    createStream(callbacks: {
        onTranscription: (text: string, isFinal: boolean) => void;
        onError: (error: any) => void;
    }): any {
        if (!this.deepgram) {
            this.logger.error('Deepgram client not initialized');
            return null;
        }

        try {
            const connection: LiveClient = this.deepgram.listen.live({
                model: 'nova-2',
                language: 'multi', // Arabe, anglais, français et autres (codeswitching)
                smart_format: true,
                interim_results: true,
                encoding: 'linear16',
                sample_rate: 16000,
                endpointing: 100, // Recommandé pour le changement de langue en direct
            });

            connection.on(LiveTranscriptionEvents.Transcript, (data) => {
                const transcript = data.channel.alternatives[0].transcript;
                if (transcript) {
                    callbacks.onTranscription(transcript, data.is_final);
                }
            });

            connection.on(LiveTranscriptionEvents.Error, (err) => {
                this.logger.error(`Deepgram Error: ${err.message}`);
                callbacks.onError(err);
            });

            connection.on(LiveTranscriptionEvents.Close, () => {
                this.logger.log('Deepgram connection closed');
            });

            // Wrapper to match previous stream interface (write method)
            return {
                write: (chunk: Buffer) => {
                    if (connection.getReadyState() === 1) { // 1 = OPEN
                        // Deepgram expects ArrayBuffer, Blob, or string
                        const arrayBuffer = chunk.buffer.slice(chunk.byteOffset, chunk.byteOffset + chunk.byteLength);
                        connection.send(arrayBuffer);
                    }
                },
                end: () => {
                    connection.finish();
                },
            };
        } catch (error) {
            this.logger.error(`Failed to create Deepgram stream: ${error.message}`);
            callbacks.onError(error);
            return null;
        }
    }
}
