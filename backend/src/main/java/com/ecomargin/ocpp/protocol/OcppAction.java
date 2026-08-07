package com.ecomargin.ocpp.protocol;

public enum OcppAction {
    // Core Profile (Inbound from Charger)
    BootNotification,
    Heartbeat,
    Authorize,
    StartTransaction,
    StopTransaction,
    StatusNotification,
    MeterValues,

    // Core Profile (Outbound to Charger)
    RemoteStartTransaction,
    RemoteStopTransaction,
    UnlockConnector,
    ChangeConfiguration,
    GetConfiguration,
    Reset,

    // Firmware Management Profile (Outbound)
    UpdateFirmware,
    GetDiagnostics,
    DiagnosticsStatusNotification,
    FirmwareStatusNotification,

    // Reservation Profile (Outbound)
    ReserveNow,
    CancelReservation
}
