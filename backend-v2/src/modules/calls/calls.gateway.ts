import {
  WebSocketGateway, WebSocketServer, SubscribeMessage,
  OnGatewayConnection, OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Injectable, Logger } from '@nestjs/common';
import { TranscriptionService } from './transcription.service';

interface SocketWithUserId { id: string; userId?: string; emit: (event: string, data: unknown) => void; disconnect: (close?: boolean) => void; handshake: { auth?: { token?: string }; headers?: { authorization?: string } }; }

const userIdToSocket = new Map<string, Set<string>>();

@Injectable()
@WebSocketGateway({ cors: { origin: '*' }, path: '/socket.io', transports: ['websocket', 'polling'] })
export class CallsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  private readonly logger = new Logger(CallsGateway.name);
  @WebSocketServer() server!: Server;
  private transcriptionStreams = new Map<string, any>();

  constructor(private jwtService: JwtService, private config: ConfigService, private transcriptionService: TranscriptionService) {}

  handleConnection(client: SocketWithUserId) {
    const token = client.handshake?.auth?.token ?? (client.handshake?.headers?.authorization ?? '').replace('Bearer ', '');
    if (!token) { client.emit('error', { message: 'Authentication required' }); client.disconnect(true); return; }
    try {
      const payload = this.jwtService.verify(token, { secret: this.config.get('JWT_SECRET') || 'fallback-secret' });
      const userId = String(payload.sub ?? payload.id ?? payload.userId ?? '');
      if (!userId) throw new Error('No user id');
      client.userId = userId;
      if (!userIdToSocket.has(userId)) userIdToSocket.set(userId, new Set());
      userIdToSocket.get(userId)!.add(client.id);
    } catch (e) { client.emit('error', { message: 'Invalid token' }); client.disconnect(true); }
  }

  handleDisconnect(client: SocketWithUserId) {
    const userId = client.userId;
    if (userId && userIdToSocket.has(userId)) {
      userIdToSocket.get(userId)!.delete(client.id);
      if (userIdToSocket.get(userId)!.size === 0) userIdToSocket.delete(userId);
    }
    const stream = this.transcriptionStreams.get(client.id);
    if (stream) { stream.end(); this.transcriptionStreams.delete(client.id); }
  }

  private emitToUser(targetUserId: string, event: string, data: unknown) {
    const sockets = userIdToSocket.get(targetUserId);
    if (!sockets) return;
    for (const sid of sockets) { const s = this.server.sockets.sockets.get(sid); if (s) s.emit(event, data); }
  }

  @SubscribeMessage('call:initiate')
  handleCallInitiate(client: SocketWithUserId, payload: { targetUserId: string; channelId: string; isVideo: boolean; callerName: string }) {
    if (!client.userId) return;
    this.emitToUser(payload.targetUserId, 'call:incoming', { fromUserId: client.userId, fromUserName: payload.callerName, channelId: payload.channelId, isVideo: payload.isVideo });
  }

  @SubscribeMessage('call:accept')
  handleCallAccept(client: SocketWithUserId, payload: { fromUserId: string; channelId: string }) {
    if (!client.userId) return;
    this.emitToUser(payload.fromUserId, 'call:accepted', { channelId: payload.channelId });
  }

  @SubscribeMessage('call:reject')
  handleCallReject(client: SocketWithUserId, payload: { fromUserId: string }) {
    if (!client.userId) return;
    this.emitToUser(payload.fromUserId, 'call:rejected', {});
  }

  @SubscribeMessage('call:end')
  handleCallEnd(client: SocketWithUserId, payload: { targetUserId: string }) {
    if (!client.userId) return;
    this.emitToUser(payload.targetUserId, 'call:ended', {});
  }

  @SubscribeMessage('webrtc:offer')
  handleWebRTCOffer(client: SocketWithUserId, payload: { targetUserId: string; sdp: string; type: string }) {
    if (!client.userId) return;
    this.emitToUser(payload.targetUserId, 'webrtc:offer', { fromUserId: client.userId, sdp: payload.sdp, type: payload.type });
  }

  @SubscribeMessage('webrtc:answer')
  handleWebRTCAnswer(client: SocketWithUserId, payload: { targetUserId: string; sdp: string; type: string }) {
    if (!client.userId) return;
    this.emitToUser(payload.targetUserId, 'webrtc:answer', { fromUserId: client.userId, sdp: payload.sdp, type: payload.type });
  }

  @SubscribeMessage('webrtc:ice-candidate')
  handleICE(client: SocketWithUserId, payload: { targetUserId: string; candidate: string; sdpMid: string; sdpMLineIndex: number }) {
    if (!client.userId) return;
    this.emitToUser(payload.targetUserId, 'webrtc:ice-candidate', { fromUserId: client.userId, candidate: payload.candidate, sdpMid: payload.sdpMid, sdpMLineIndex: payload.sdpMLineIndex });
  }

  @SubscribeMessage('call:audio_chunk')
  handleAudioChunk(client: SocketWithUserId, payload: { targetUserId: string; chunk: Buffer; channelId: string }) {
    if (!client.userId) return;
    let stream = this.transcriptionStreams.get(client.id);
    if (!stream) {
      stream = this.transcriptionService.createStream({
        onTranscription: (text: string, isFinal: boolean) => {
          const tp = { fromUserId: client.userId, text, isFinal, channelId: payload.channelId };
          client.emit('call:transcription', tp);
          this.emitToUser(payload.targetUserId, 'call:transcription', tp);
        },
        onError: () => this.transcriptionStreams.delete(client.id),
      });
      if (stream) this.transcriptionStreams.set(client.id, stream);
    }
    if (stream) stream.write(payload.chunk);
  }

  @SubscribeMessage('chat:typing')
  handleTyping(client: SocketWithUserId, payload: { targetUserId: string; conversationId: string; isTyping: boolean }) {
    if (!client.userId) return;
    this.emitToUser(payload.targetUserId, 'chat:typing', { userId: client.userId, conversationId: payload.conversationId, isTyping: payload.isTyping });
  }

  emitMessageNew(targetUserId: string, payload: any) {
    this.emitToUser(targetUserId, 'message:new', payload);
  }
}
