import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Injectable, Logger } from '@nestjs/common';

interface SocketWithUserId {
  id: string;
  userId?: string;
  emit: (event: string, data: unknown) => void;
  disconnect: (close?: boolean) => void;
  handshake: {
    auth?: { token?: string };
    headers?: { authorization?: string };
  };
}

const userIdToSocket = new Map<string, Set<string>>();

@Injectable()
@WebSocketGateway({
  cors: { origin: '*' },
  path: '/socket.io',
  transports: ['websocket', 'polling'],
})
export class CallsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  private readonly logger = new Logger(CallsGateway.name);

  @WebSocketServer()
  server!: Server;

  constructor(
    private jwtService: JwtService,
    private config: ConfigService,
  ) { }

  handleConnection(client: SocketWithUserId) {
    this.logger.log(`[CALL] Connexion socket client.id=${client.id}`);
    const token =
      client.handshake?.auth?.token ??
      (client.handshake?.headers?.authorization ?? '').replace('Bearer ', '');
    if (!token) {
      client.emit('error', { message: 'Authentication required' });
      client.disconnect(true);
      return;
    }
    try {
      const payload = this.jwtService.verify(token, {
        secret: this.config.get('JWT_SECRET') || 'fallback-secret',
      });
      const userId = String(payload.sub ?? payload.id ?? payload.userId ?? '');
      if (!userId) throw new Error('No user id');
      client.userId = userId;
      if (!userIdToSocket.has(userId)) {
        userIdToSocket.set(userId, new Set());
      }
      userIdToSocket.get(userId)!.add(client.id);
      this.logger.log(
        `[CALL] userId=${userId} connecté. Total users: ${userIdToSocket.size}`,
      );
    } catch (e) {
      this.logger.warn(`[CALL] Connexion refusée: ${e}`);
      client.emit('error', { message: 'Invalid token' });
      client.disconnect(true);
    }
  }

  handleDisconnect(client: SocketWithUserId) {
    const userId = client.userId;
    this.logger.log(
      `[CALL] Déconnexion client.id=${client.id} userId=${userId}`,
    );
    if (userId && userIdToSocket.has(userId)) {
      userIdToSocket.get(userId)!.delete(client.id);
      if (userIdToSocket.get(userId)!.size === 0) {
        userIdToSocket.delete(userId);
      }
    }
  }

  @SubscribeMessage('call:initiate')
  handleCallInitiate(
    client: SocketWithUserId,
    payload: {
      targetUserId: string;
      channelId: string;
      isVideo: boolean;
      callerName: string;
    },
  ) {
    const callerId = client.userId;
    if (!callerId) return;
    this.logger.log(
      `[CALL] call:initiate callerId=${callerId} targetUserId=${payload.targetUserId} channelId=${payload.channelId}`,
    );
    const sockets = userIdToSocket.get(payload.targetUserId);
    if (sockets && sockets.size > 0) {
      this.logger.log(
        `[CALL] Cible trouvée: ${sockets.size} socket(s), envoi call:incoming`,
      );
      for (const sid of sockets) {
        const targetSocket = this.server.sockets.sockets.get(sid);
        if (targetSocket) {
          targetSocket.emit('call:incoming', {
            fromUserId: callerId,
            fromUserName: payload.callerName,
            channelId: payload.channelId,
            isVideo: payload.isVideo,
          });
        }
      }
    } else {
      this.logger.warn(
        `[CALL] Cible NON trouvée! targetUserId=${payload.targetUserId} n'est pas connecté. Users connectés: ${Array.from(userIdToSocket.keys()).join(', ')}`,
      );
    }
  }

  @SubscribeMessage('call:accept')
  handleCallAccept(
    client: SocketWithUserId,
    payload: { fromUserId: string; channelId: string },
  ) {
    if (!client.userId) return;
    this.logger.log(
      `[CALL] call:accept calleeId=${client.userId} fromUserId=${payload.fromUserId} channelId=${payload.channelId}`,
    );
    const sockets = userIdToSocket.get(payload.fromUserId);
    if (sockets) {
      this.logger.log(`[CALL] Envoi call:accepted au caller`);
      for (const sid of sockets) {
        const s = this.server.sockets.sockets.get(sid);
        if (s) s.emit('call:accepted', { channelId: payload.channelId });
      }
    } else {
      this.logger.warn(
        `[CALL] call:accept - caller fromUserId=${payload.fromUserId} non trouvé`,
      );
    }
  }

  @SubscribeMessage('call:reject')
  handleCallReject(client: SocketWithUserId, payload: { fromUserId: string }) {
    if (!client.userId) return;
    const sockets = userIdToSocket.get(payload.fromUserId);
    if (sockets) {
      for (const sid of sockets) {
        const s = this.server.sockets.sockets.get(sid);
        if (s) s.emit('call:rejected');
      }
    }
  }

  @SubscribeMessage('call:end')
  handleCallEnd(client: SocketWithUserId, payload: { targetUserId: string }) {
    if (!client.userId) return;
    const sockets = userIdToSocket.get(payload.targetUserId);
    if (sockets) {
      for (const sid of sockets) {
        const s = this.server.sockets.sockets.get(sid);
        if (s) s.emit('call:ended');
      }
    }
  }

  // ─── WebRTC Signaling ──────────────────────────────────────────────

  @SubscribeMessage('webrtc:offer')
  handleWebRTCOffer(
    client: SocketWithUserId,
    payload: { targetUserId: string; sdp: string; type: string },
  ) {
    if (!client.userId) return;
    this.logger.log(
      `[WEBRTC] offer from=${client.userId} to=${payload.targetUserId}`,
    );
    const sockets = userIdToSocket.get(payload.targetUserId);
    if (sockets) {
      for (const sid of sockets) {
        const s = this.server.sockets.sockets.get(sid);
        if (s)
          s.emit('webrtc:offer', {
            fromUserId: client.userId,
            sdp: payload.sdp,
            type: payload.type,
          });
      }
    }
  }

  @SubscribeMessage('webrtc:answer')
  handleWebRTCAnswer(
    client: SocketWithUserId,
    payload: { targetUserId: string; sdp: string; type: string },
  ) {
    if (!client.userId) return;
    this.logger.log(
      `[WEBRTC] answer from=${client.userId} to=${payload.targetUserId}`,
    );
    const sockets = userIdToSocket.get(payload.targetUserId);
    if (sockets) {
      for (const sid of sockets) {
        const s = this.server.sockets.sockets.get(sid);
        if (s)
          s.emit('webrtc:answer', {
            fromUserId: client.userId,
            sdp: payload.sdp,
            type: payload.type,
          });
      }
    }
  }

  @SubscribeMessage('webrtc:ice-candidate')
  handleWebRTCIceCandidate(
    client: SocketWithUserId,
    payload: {
      targetUserId: string;
      candidate: string;
      sdpMid: string;
      sdpMLineIndex: number;
    },
  ) {
    if (!client.userId) return;
    const sockets = userIdToSocket.get(payload.targetUserId);
    if (sockets) {
      for (const sid of sockets) {
        const s = this.server.sockets.sockets.get(sid);
        if (s)
          s.emit('webrtc:ice-candidate', {
            fromUserId: client.userId,
            candidate: payload.candidate,
            sdpMid: payload.sdpMid,
            sdpMLineIndex: payload.sdpMLineIndex,
          });
      }
    }
  }

  @SubscribeMessage('chat:typing')
  handleChatTyping(
    client: SocketWithUserId,
    payload: { targetUserId: string; conversationId: string; isTyping: boolean },
  ) {
    if (!client.userId) return;
    const sockets = userIdToSocket.get(payload.targetUserId);
    if (sockets) {
      for (const sid of sockets) {
        const s = this.server.sockets.sockets.get(sid);
        if (s) {
          s.emit('chat:typing', {
            userId: client.userId,
            conversationId: payload.conversationId,
            isTyping: payload.isTyping,
          });
        }
      }
    }
  }

  /** Emit message:new to a user (for in-app notifications when they receive a chat message). */
  emitMessageNew(
    targetUserId: string,
    payload: {
      senderId: string;
      senderName: string;
      preview: string;
      text?: string;
      attachmentUrl?: string;
      attachmentType?: 'image' | 'voice' | 'call_missed' | 'call_summary';
      callDuration?: number;
      conversationId: string;
      messageId?: string;
      createdAt?: string;
    },
  ) {
    const sockets = userIdToSocket.get(targetUserId);
    if (sockets) {
      for (const sid of sockets) {
        const s = this.server.sockets.sockets.get(sid);
        if (s) s.emit('message:new', payload);
      }
      this.logger.log(
        `[CALL] message:new envoyé à targetUserId=${targetUserId}`,
      );
    }
  }
}
