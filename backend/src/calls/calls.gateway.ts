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
import { Injectable } from '@nestjs/common';

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
  @WebSocketServer()
  server!: Server;

  constructor(
    private jwtService: JwtService,
    private config: ConfigService,
  ) {}

  handleConnection(client: SocketWithUserId) {
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
    } catch {
      client.emit('error', { message: 'Invalid token' });
      client.disconnect(true);
    }
  }

  handleDisconnect(client: SocketWithUserId) {
    const userId = client.userId;
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
    const sockets = userIdToSocket.get(payload.targetUserId);
    if (sockets && sockets.size > 0) {
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
    }
  }

  @SubscribeMessage('call:accept')
  handleCallAccept(
    client: SocketWithUserId,
    payload: { fromUserId: string; channelId: string },
  ) {
    if (!client.userId) return;
    const sockets = userIdToSocket.get(payload.fromUserId);
    if (sockets) {
      for (const sid of sockets) {
        const s = this.server.sockets.sockets.get(sid);
        if (s) s.emit('call:accepted', { channelId: payload.channelId });
      }
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
}
