# EcoMargin Standalone Java 21 OCPP 1.6-J Server

Production-grade, independent **Java 21 / Spring Boot 3.2.x OCPP 1.6-J Server** powering real-time EV charger communication, live telemetry streaming, and automated financial settlement for the EcoMargin EV Charging Platform.

---

## 1. Architectural Overview

```
                          ┌───────────────────────────┐
                          │   Physical EV Charger     │
                          │   / OCPP Simulator        │
                          └─────────────┬─────────────┘
                                        │ WebSocket (OCPP 1.6-J)
                                        │ ws://<ocpp-host>/ocpp/{chargePointId}
                                        ▼
                          ┌───────────────────────────┐
                          │  EcoMargin OCPP Server    │
                          │ (D:\EcoMargin App\        │
                          │        ocpp-server)       │
                          └─────────────┬─────────────┘
                                        │
                         ┌──────────────┴──────────────┐
                         │                             │
                         ▼                             ▼
              ┌─────────────────────┐       ┌──────────────────────┐
              │ Shared PostgreSQL DB│       │ EcoMargin Main       │
              │ (chargers, sessions,│◄──────┤ Backend (Render)     │
              │  meter_values)      │       │                      │
              └─────────────────────┘       └──────────┬───────────┘
                                                       │ Live Metric Stream
                                                       ▼
                                            ┌──────────────────────┐
                                            │  Flutter Customer    │
                                            │        App           │
                                            └──────────────────────┘
```

---

## 2. Supported OCPP 1.6-J Messages & Handlers

| Message Action | Direction | Purpose | Handling & Business Logic |
| :--- | :--- | :--- | :--- |
| `BootNotification` | Charger -> Server | Initial handshake | Registers `Charger` in DB, updates model/firmware/status (`AVAILABLE`). Returns `Accepted` status and heartbeat interval. |
| `Heartbeat` | Charger -> Server | Keep-alive check | Responds with current UTC server timestamp. |
| `StatusNotification` | Charger -> Server | State change | Updates charger & connector status (`Available`, `Preparing`, `Charging`, `Faulted`). Broadcasts real-time events. |
| `Authorize` | Charger -> Server | RFID / Tag Check | Validates `idTag` or `cardUid` against `rfid_cards` DB table. Returns `Accepted` or `Invalid`. |
| `StartTransaction` | Charger -> Server | Start session | Creates `ChargingSession`, assigns `ocppTransactionId`, updates meter start Wh, sets connector/charger to `CHARGING`. |
| `MeterValues` | Charger -> Server | Live telemetry | Records energy (Wh), active power (kW), SoC (%). Updates live session kWh and cost **without deducting wallet money**. |
| `StopTransaction` | Charger -> Server | Terminate session | Finalizes session (`status = COMPLETED`, `meterStopWh`). Triggers **atomic wallet settlement** via pessimistic locking (`findByUserIdForUpdate`). Idempotent guard prevents duplicate debits. |
| `RemoteStartTransaction` | Server -> Charger | Remote command | Sends JSON WebSocket call from backend API to connected charger session. |
| `RemoteStopTransaction` | Server -> Charger | Remote command | Sends JSON WebSocket call from backend API to connected charger session. |

---

## 3. Directory Structure

```
ocpp-server/
├── pom.xml                                   # Maven Java 21 / Spring Boot 3.2.x POM
├── mvnw.cmd                                  # Windows Maven Wrapper
├── README.md                                 # Complete Documentation
├── src/
│   ├── main/
│   │   ├── java/com/ecomargin/ocpp/
│   │   │   ├── OcppServerApplication.java    # Spring Boot Entrypoint
│   │   │   ├── config/                       # Security & WebSocket Handlers
│   │   │   │   ├── OcppServerSecurityConfig.java
│   │   │   │   └── WebSocketConfig.java
│   │   │   ├── controller/                   # REST & SSE Emitter Endpoints
│   │   │   │   └── OcppApiController.java
│   │   │   ├── model/                        # JPA Database Entities
│   │   │   │   ├── Charger.java
│   │   │   │   ├── ChargingSession.java
│   │   │   │   ├── Connector.java
│   │   │   │   ├── MeterValue.java
│   │   │   │   ├── RfidCard.java
│   │   │   │   ├── Station.java
│   │   │   │   ├── Transaction.java
│   │   │   │   ├── User.java
│   │   │   │   └── Wallet.java
│   │   │   ├── protocol/                     # OCPP 1.6-J JSON Framing
│   │   │   │   ├── OcppJsonParser.java
│   │   │   │   └── OcppMessage.java
│   │   │   ├── repository/                   # Spring Data JPA Repositories
│   │   │   │   ├── ChargerRepository.java
│   │   │   │   ├── ChargingSessionRepository.java
│   │   │   │   ├── ConnectorRepository.java
│   │   │   │   ├── MeterValueRepository.java
│   │   │   │   ├── RfidCardRepository.java
│   │   │   │   ├── StationRepository.java
│   │   │   │   ├── TransactionRepository.java
│   │   │   │   ├── UserRepository.java
│   │   │   │   └── WalletRepository.java
│   │   │   ├── service/                      # Core Message Dispatcher & Telemetry Broadcaster
│   │   │   │   ├── OcppLiveEventBroadcaster.java
│   │   │   │   └── OcppMessageDispatcher.java
│   │   │   └── websocket/                    # Session Registry & Handlers
│   │   │       ├── OcppWebSocketHandler.java
│   │   │       └── WebSocketSessionRegistry.java
│   │   └── resources/
│   │       └── application.yml               # Environment Configuration
│   └── test/
│       ├── java/com/ecomargin/ocpp/
│       │   ├── OcppServerIntegrationTest.java# Test Suite
│       │   └── simulator/
│       │       └── OcppSimulator.java        # Automated Charge Point CLI Simulator
│       └── resources/
│           └── application-test.yml
```

---

## 4. Environment Variables Reference

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `PORT` | `8081` | Server HTTP & WebSocket listening port. |
| `SPRING_DATASOURCE_URL` | `jdbc:postgresql://localhost:5432/ecomargin_db` | PostgreSQL JDBC connection URL. |
| `SPRING_DATASOURCE_USERNAME` | `postgres` | Database user credentials. |
| `SPRING_DATASOURCE_PASSWORD` | `postgres` | Database password. |
| `MAIN_BACKEND_URL` | `https://ecomargin-app.onrender.com` | EcoMargin Core Backend Base URL. |
| `OCPP_HEARTBEAT_INTERVAL` | `60` | Default heartbeat interval in seconds sent to chargers during `BootNotification`. |
| `INTERNAL_API_SECRET` | `ecomargin-internal-secret-key-2026` | Secret key for inter-service communication. |

---

## 5. Local Testing & Verification

### Running the Server
```powershell
cd "D:\EcoMargin App\ocpp-server"
.\mvnw.cmd spring-boot:run
```

### Running Automated Test Suite
```powershell
cd "D:\EcoMargin App\ocpp-server"
.\mvnw.cmd clean test
```

### Running the Interactive `CHG-DC-04` Charger Simulator
While `ocpp-server` is running on port 8081:
```powershell
cd "D:\EcoMargin App\ocpp-server"
.\mvnw.cmd test-compile exec:java -Dexec.mainClass="com.ecomargin.ocpp.simulator.OcppSimulator" -Dexec.classpathScope="test"
```

The simulator will connect to `ws://localhost:8081/ocpp/CHG-DC-04` and execute:
1. `BootNotification`
2. `StatusNotification (Preparing)`
3. `StartTransaction`
4. `StatusNotification (Charging)`
5. Periodic `MeterValues` (Energy, Power, SoC)
6. `StopTransaction` (Settlement)
7. `StatusNotification (Available)`

---

## 6. How to Connect a Real Physical EV Charger

1. **Configure Physical Charger Settings:**
   - **Central System URL / WebSocket Endpoint:**
     ```
     ws://<your-ocpp-server-domain>:8081/ocpp/{chargePointId}
     ```
     For production SSL/TLS deployments:
     ```
     wss://ocpp.ecomargin.com/ocpp/{chargePointId}
     ```
   - **Charge Point ID / Name:** Ensure the charge point ID matches the `ocppId` in your `chargers` DB table (e.g. `CHG-DC-04` or `IN_JAI_01`).
   - **Subprotocol:** Select `ocpp1.6` or `ocpp1.6j` (JSON over WebSocket).

2. **Handshake Verification:**
   - Once powered on, the physical charger sends `BootNotification`.
   - `ocpp-server` responds with `status: Accepted` and the heartbeat interval.
   - The charger's status automatically shifts to `AVAILABLE` in the EcoMargin Flutter app map.

3. **Charging Session:**
   - When a user plugs in their vehicle or taps an authorized RFID card, `StartTransaction` initiates telemetry logging.
   - Live metrics (`kWh`, `kW`, `SoC`, estimated `₹` cost) stream directly to the user's mobile screen.
   - Upon session completion (`StopTransaction`), the server performs atomic wallet deduction and records a ledger transaction entry.

---

## 7. Render Production Deployment

1. **Create New Web Service on Render:**
   - **Build Command:** `./mvnw clean package -DskipTests`
   - **Start Command:** `java -jar target/ocpp-server-1.0.0.jar`
   - **Port:** Set `PORT` environment variable to `10000`.

2. **Configure Production Environment Variables:**
   - `SPRING_DATASOURCE_URL`: PostgreSQL Production Internal/External URL.
   - `SPRING_DATASOURCE_USERNAME`: Render PostgreSQL username.
   - `SPRING_DATASOURCE_PASSWORD`: Render PostgreSQL password.
   - `MAIN_BACKEND_URL`: `https://ecomargin-app.onrender.com`

3. **Public WebSocket Endpoint:**
   - Render automatically secures incoming connections with TLS/SSL:
     ```
     wss://ocpp-server-ecomargin.onrender.com/ocpp/{chargePointId}
     ```
