pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import "Util.js" as Util

// Live system integration. Everything here is backed by a real service:
// NetworkManager via Quickshell.Networking, BlueZ via Quickshell.Bluetooth,
// PipeWire via Quickshell.Services.Pipewire, UPower, and MPRIS.
QtObject {
    id: root

    // ---------------- Network ----------------
    readonly property var networkDevices: Networking.devices ? Networking.devices.values : []
    readonly property var wifiDevice: {
        const ds = root.networkDevices;
        for (let i = 0; i < ds.length; i++) if (ds[i].type === DeviceType.Wifi) return ds[i];
        return null;
    }
    readonly property var wiredDevice: {
        const ds = root.networkDevices;
        for (let i = 0; i < ds.length; i++) if (ds[i].type === DeviceType.Wired) return ds[i];
        return null;
    }
    readonly property bool networkAvailable: Networking.backend === NetworkBackendType.NetworkManager
    readonly property bool wifiAvailable: root.wifiDevice !== null
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled
    readonly property var wifiNetworks: root.wifiDevice && root.wifiDevice.networks
        ? root.wifiDevice.networks.values : []
    readonly property var activeWifi: {
        const ns = root.wifiNetworks;
        for (let i = 0; i < ns.length; i++) if (ns[i].connected) return ns[i];
        return null;
    }
    readonly property bool connected: root.activeWifi !== null
        || (root.wiredDevice !== null && root.wiredDevice.connected)
    readonly property string networkName: root.activeWifi ? root.activeWifi.name
        : (root.wiredDevice && root.wiredDevice.connected ? "Wired" : "")
    readonly property int wifiSignal: root.activeWifi && root.activeWifi.signalStrength !== undefined
        ? Math.round(root.activeWifi.signalStrength * 100) : 0
    readonly property int connectivity: Networking.connectivity

    function toggleWifi() { Networking.wifiEnabled = !Networking.wifiEnabled; }
    function setWifi(enabled) { Networking.wifiEnabled = enabled; }
    function connectWifi(network) {
        if (!network) return;
        network.connect();
    }
    function connectWifiPsk(network, psk) {
        if (!network) return;
        if (psk && psk.length > 0) network.connectWithPsk(psk);
        else network.connect();
    }
    function scanWifi() {
        if (root.wifiDevice) root.wifiDevice.scannerEnabled = true;
    }

    // ---------------- Bluetooth ----------------
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool bluetoothAvailable: root.btAdapter !== null
    readonly property bool bluetoothEnabled: root.btAdapter ? root.btAdapter.enabled : false
    readonly property var btDevices: Bluetooth.devices ? Bluetooth.devices.values : []
    readonly property var connectedBtDevices: {
        const ds = root.btDevices;
        const out = [];
        for (let i = 0; i < ds.length; i++) if (ds[i].connected) out.push(ds[i]);
        return out;
    }
    readonly property int bluetoothBattery: {
        const ds = root.connectedBtDevices;
        let best = -1;
        for (let i = 0; i < ds.length; i++) {
            if (ds[i].batteryAvailable) best = Math.max(best, Math.round(ds[i].battery * 100));
        }
        return best;
    }

    function toggleBluetooth() {
        if (!root.btAdapter) return;
        root.btAdapter.enabled = !root.btAdapter.enabled;
    }
    function toggleBluetoothDevice(device) {
        if (!device) return;
        if (device.connected) device.disconnect();
        else if (device.paired) device.connect();
        else device.pair();
    }

    // ---------------- Audio ----------------
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    property PwObjectTracker sinkTracker: PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }
    property PwObjectTracker sourceTracker: PwObjectTracker {
        objects: root.source ? [root.source] : []
    }
    readonly property var sinkAudio: root.sink ? root.sink.audio : null
    readonly property var sourceAudio: root.source ? root.source.audio : null
    readonly property bool audioAvailable: root.sink !== null && root.sinkAudio !== null
    readonly property real volume: root.sinkAudio ? root.sinkAudio.volume : 0
    readonly property bool muted: root.sinkAudio ? root.sinkAudio.muted : true
    readonly property real micVolume: root.sourceAudio ? root.sourceAudio.volume : 0
    readonly property bool micMuted: root.sourceAudio ? root.sourceAudio.muted : true
    readonly property string sinkName: root.sink ? (root.sink.description || root.sink.name) : "No output"

    function setVolume(v) {
        if (!root.sinkAudio) return;
        root.sinkAudio.volume = Util.clamp(v, 0, 1.5);
        if (v > 0 && root.sinkAudio.muted) root.sinkAudio.muted = false;
    }
    function toggleMute() {
        if (root.sinkAudio) root.sinkAudio.muted = !root.sinkAudio.muted;
    }
    function setMicVolume(v) {
        if (root.sourceAudio) root.sourceAudio.volume = Util.clamp(v, 0, 1.5);
    }
    function toggleMicMute() {
        if (root.sourceAudio) root.sourceAudio.muted = !root.sourceAudio.muted;
    }
    function setDefaultSink(node) {
        if (node) Pipewire.preferredDefaultAudioSink = node;
    }
    function setDefaultSource(node) {
        if (node) Pipewire.preferredDefaultAudioSource = node;
    }

    readonly property var sinks: {
        const ns = Pipewire.nodes ? Pipewire.nodes.values : [];
        const out = [];
        for (let i = 0; i < ns.length; i++)
            if (ns[i].isSink && !ns[i].isStream && ns[i].audio) out.push(ns[i]);
        return out;
    }
    readonly property var sources: {
        const ns = Pipewire.nodes ? Pipewire.nodes.values : [];
        const out = [];
        for (let i = 0; i < ns.length; i++)
            if (!ns[i].isSink && !ns[i].isStream && ns[i].audio) out.push(ns[i]);
        return out;
    }

    // ---------------- MPRIS ----------------
    readonly property var players: Mpris.players ? Mpris.players.values : []
    readonly property var player: {
        const ps = root.players;
        for (let i = 0; i < ps.length; i++) if (ps[i].isPlaying) return ps[i];
        return ps.length > 0 ? ps[0] : null;
    }
    readonly property bool hasMedia: root.player !== null
    readonly property string trackTitle: root.player ? (root.player.trackTitle || "Unknown track") : ""
    readonly property string trackArtist: root.player ? (root.player.trackArtist || "") : ""
    readonly property string trackAlbum: root.player ? (root.player.trackAlbum || "") : ""
    readonly property string trackArt: root.player ? (root.player.trackArtUrl || "") : ""
    readonly property bool playing: root.player ? root.player.isPlaying : false
    readonly property real trackPosition: root.player ? root.player.position : 0
    readonly property real trackLength: root.player ? root.player.length : 0
    readonly property bool canSeek: root.player ? root.player.canSeek : false

    function togglePlay() { if (root.player) root.player.togglePlaying(); }
    function next() { if (root.player) root.player.next(); }
    function previous() { if (root.player) root.player.previous(); }
    function seekTo(seconds) {
        if (root.player && root.player.positionSupported)
            root.player.position = Util.clamp(seconds, 0, root.trackLength);
    }
    function setPlayerVolume(v) { if (root.player) root.player.volume = Util.clamp(v, 0, 1); }

    // ---------------- Battery / power ----------------
    readonly property var batteryDevice: UPower.displayDevice
    readonly property bool hasBattery: root.batteryDevice !== null
        && root.batteryDevice.isPresent && root.batteryDevice.type === UPowerDeviceType.Battery
    readonly property real batteryLevel: root.batteryDevice ? root.batteryDevice.percentage : 0
    readonly property bool charging: root.batteryDevice
        && (root.batteryDevice.state === UPowerDeviceState.Charging
            || root.batteryDevice.state === UPowerDeviceState.FullyCharged
            || root.batteryDevice.state === UPowerDeviceState.PendingCharge)
    readonly property bool onBattery: UPower.onBattery
    readonly property int powerProfile: PowerProfiles.profile
    readonly property bool hasPerformanceProfile: PowerProfiles.hasPerformanceProfile

    function setPowerProfile(profile) { PowerProfiles.profile = profile; }

    // ---------------- Helpers ----------------
    readonly property string hostname: {
        const h = Quickshell.env("HOSTNAME");
        return h && h.length > 0 ? h : "aether";
    }

    function volumePercent() { return Math.round(root.volume * 100); }
    function batteryPercent() { return Math.round(root.batteryLevel * 100); }
    function batteryIcon() {
        if (!root.hasBattery) return "power";
        if (root.charging) return "battery";
        if (root.batteryLevel <= 0.1) return "battery";
        return "battery";
    }
}
