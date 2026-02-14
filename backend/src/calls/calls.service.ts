import { Injectable } from '@nestjs/common';

/**
 * Appels voix/vidéo : signalisation via WebSocket (calls.gateway),
 * média via Jitsi Meet (frontend, meet.jit.si). Aucun token backend nécessaire.
 */
@Injectable()
export class CallsService {}
