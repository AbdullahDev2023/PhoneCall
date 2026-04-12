# PhoneCall Server

This Node.js service stores call logs per device and exposes a small admin UI to rename devices.

## Run locally

```bash
cd server
npm install
npm start
```

By default the server listens on `http://localhost:3000`.

## Environment variables

- `PORT` - HTTP port, defaults to `3000`
- `PHONECALL_DATA_FILE` - optional path to the JSON store file

## Endpoints

- `GET /health`
- `GET /api/devices`
- `GET /api/devices/:deviceId`
- `PUT /api/devices/:deviceId`
- `POST /api/devices/:deviceId/call-logs`
- `GET /admin`

## Production host

Deploy this service behind `phonecall.visioncoachinginstitute.online` and keep the Flutter app pointed at the same base URL.
