import http from 'k6/http';
import ws from 'k6/ws';
import { check, sleep } from 'k6';

export const options = {
    stages: [
        { duration: '30s', target: 20 },  // Ramp up to 20 virtual users
        { duration: '1m', target: 20 },   // Stay at 20 users
        { duration: '30s', target: 0 },   // Ramp down to 0
    ],
    thresholds: {
        http_req_duration: ['p(95)<500'], // 95% of API requests must complete under 500ms
    },
};

export default function () {
    // 1. Test REST API Paging
    const res = http.get('http://localhost:8080/api/v1/stations?page=0&size=10');
    check(res, {
        'API status is 200': (r) => r.status === 200,
        'API returned content': (r) => r.json().content !== undefined,
    });

    // 2. Test Realtime WebSocket connections
    const url = 'ws://localhost:8080/ws/realtime';
    const params = { tags: { my_tag: 'hello' } };

    ws.connect(url, params, function (socket) {
        socket.on('open', () => {
            // Subscribe to telemetry topic
            socket.send('SUBSCRIBE charger:TX_AUS_DWTN_01');
            
            // Periodically ping to verify heartbeat latency
            socket.setInterval(() => {
                socket.send('PING');
            }, 10000);
        });

        socket.on('message', (data) => {
            check(data, {
                'received response': (d) => d.length > 0,
            });
        });

        socket.on('close', () => console.log('WebSocket disconnected'));
        socket.on('error', (e) => console.log('WebSocket error: ', e.error()));

        socket.setTimeout(() => {
            socket.close();
        }, 15000); // stay connected for 15 seconds
    });

    sleep(1);
}
