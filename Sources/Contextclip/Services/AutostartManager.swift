import ServiceManagement

/// Launch at login through SMAppService. The login item is bound to the bundle's location,
/// so moving the app after enabling it breaks the registration.
struct AutostartManager: LoginItemService {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
