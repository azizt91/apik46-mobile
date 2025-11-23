<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\GenieAcsSetting;
use App\Models\WifiChangeHistory;
use App\Models\Pelanggan;
use Illuminate\Support\Facades\Auth;
use RealRashid\SweetAlert\Facades\Alert;

class WifiSettingController extends Controller
{
    /**
     * Display WiFi settings page for customer
     */
    public function index()
    {
        // Check if GenieACS is enabled
        if (!GenieAcsSetting::isEnabled()) {
            Alert::warning('Tidak Tersedia', 'Fitur pengaturan WiFi belum diaktifkan oleh admin');
            return redirect()->route('dashboard-pelanggan');
        }

        $pelanggan = Auth::guard('pelanggan')->user();
        
        // Get current WiFi info
        $currentWifi = $this->getCurrentWifiInfo($pelanggan);
        
        // Get connected devices
        $connectedDevices = $this->getConnectedDevices($pelanggan);
        
        // Get change history
        $history = WifiChangeHistory::where('id_pelanggan', $pelanggan->id_pelanggan)
                                    ->orderBy('created_at', 'desc')
                                    ->limit(10)
                                    ->get();

        return view('pelanggan.wifi-settings', compact('currentWifi', 'connectedDevices', 'history'));
    }

    /**
     * Get current WiFi information from GenieACS
     */
    private function getCurrentWifiInfo($pelanggan)
    {
        try {
            $url = GenieAcsSetting::getValue('genieacs_url');
            $username = GenieAcsSetting::getValue('genieacs_username');
            $password = GenieAcsSetting::getValue('genieacs_password');

            if (!$url || !$pelanggan->ip_address) {
                return [
                    'ssid' => 'Tidak tersedia',
                    'password' => '********',
                    'ip' => $pelanggan->ip_address ?? 'Tidak ada'
                ];
            }

            // Query device by IP address (Robust query matching MobileWiFiController)
            $query = json_encode([
                '$or' => [
                    ['InternetGatewayDevice.WANDevice.1.WANConnectionDevice.1.WANIPConnection.1.ExternalIPAddress' => $pelanggan->ip_address],
                    ['VirtualParameters.pppoeIP' => $pelanggan->ip_address]
                ]
            ]);
            
            $deviceUrl = $url . '/devices?query=' . urlencode($query);
            
            $ch = curl_init($deviceUrl);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_TIMEOUT, 10);
            
            if ($username && $password) {
                try {
                    $decryptedPassword = decrypt($password);
                    curl_setopt($ch, CURLOPT_USERPWD, "$username:$decryptedPassword");
                } catch (\Exception $e) {
                    curl_setopt($ch, CURLOPT_USERPWD, "$username:$password");
                }
            }

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            $devices = [];
            if ($httpCode == 200 && $response) {
                $devices = json_decode($response, true);
            }

            // Fallback to regex query if strict query fails
            if (empty($devices)) {
                $deviceUrl = $url . '/devices?query=' . urlencode('{"InternetGatewayDevice.ManagementServer.ConnectionRequestURL":{"$regex":"' . $pelanggan->ip_address . '"}}');
                
                $ch = curl_init($deviceUrl);
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                curl_setopt($ch, CURLOPT_TIMEOUT, 10);
                
                if ($username && $password) {
                    try {
                        $decryptedPassword = decrypt($password);
                        curl_setopt($ch, CURLOPT_USERPWD, "$username:$decryptedPassword");
                    } catch (\Exception $e) {
                        curl_setopt($ch, CURLOPT_USERPWD, "$username:$password");
                    }
                }

                $response = curl_exec($ch);
                $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                curl_close($ch);

                if ($httpCode == 200 && $response) {
                    $devices = json_decode($response, true);
                }
            }

            if (!empty($devices)) {
                $device = $devices[0];
                
                // Try to get SSID from common paths
                $ssid = $device['InternetGatewayDevice']['LANDevice']['1']['WLANConfiguration']['1']['SSID']['_value'] ?? 'Tidak tersedia';
                
                return [
                    'ssid' => $ssid,
                    'password' => '********', // Don't show actual password
                    'ip' => $pelanggan->ip_address,
                    'device_id' => $device['_id'] // Store for updates
                ];
            }

            return [
                'ssid' => 'Tidak dapat diambil',
                'password' => '********',
                'ip' => $pelanggan->ip_address ?? 'Tidak ada'
            ];
        } catch (\Exception $e) {
            return [
                'ssid' => 'Error: ' . $e->getMessage(),
                'password' => '********',
                'ip' => $pelanggan->ip_address ?? 'Tidak ada'
            ];
        }
    }

    /**
     * Update WiFi settings via GenieACS
     */
    public function update(Request $request)
    {
        $request->validate([
            'new_ssid' => 'nullable|string|max:32',
            'new_password' => 'nullable|string|min:8',
            'confirm_password' => 'nullable|same:new_password'
        ]);

        // Check if at least one field is filled
        if (!$request->filled('new_ssid') && !$request->filled('new_password')) {
            Alert::warning('Perhatian', 'Minimal isi salah satu: SSID atau Password');
            return redirect()->back();
        }

        $pelanggan = Auth::guard('pelanggan')->user();

        // Check if GenieACS is enabled
        if (!GenieAcsSetting::isEnabled()) {
            Alert::error('Error', 'Fitur pengaturan WiFi tidak aktif');
            return redirect()->back();
        }

        try {
            // Get current info to get device_id
            $currentWifi = $this->getCurrentWifiInfo($pelanggan);
            
            if (!isset($currentWifi['device_id'])) {
                Alert::error('Gagal', 'Router tidak ditemukan atau offline.');
                return redirect()->back();
            }

            $deviceId = $currentWifi['device_id'];
            $success = true;
            $messages = [];

            // 1. Handle SSID Change
            if ($request->filled('new_ssid') && $request->new_ssid !== $currentWifi['ssid']) {
                // Log history
                $logSSID = WifiChangeHistory::create([
                    'id_pelanggan' => $pelanggan->id_pelanggan,
                    'type' => 'ssid',
                    'description' => 'Mengubah SSID via Web',
                    'old_value' => $currentWifi['ssid'],
                    'new_value' => $request->new_ssid,
                    'changed_by' => 'customer',
                    'ip_address' => $request->ip(),
                    'user_agent' => $request->userAgent(),
                    'status' => 'processing'
                ]);

                $ssidSuccess = $this->updateGenieACSParameter(
                    $deviceId,
                    'InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.SSID',
                    $request->new_ssid
                );

                if ($ssidSuccess) {
                    $logSSID->update(['status' => 'success']);
                    $messages[] = 'SSID berhasil diubah';
                } else {
                    $logSSID->update(['status' => 'failed', 'description' => 'Gagal mengubah SSID ke GenieACS']);
                    $success = false;
                    $messages[] = 'Gagal mengubah SSID';
                }
            }

            // 2. Handle Password Change
            if ($request->filled('new_password')) {
                // Log history
                $logPass = WifiChangeHistory::create([
                    'id_pelanggan' => $pelanggan->id_pelanggan,
                    'type' => 'password',
                    'description' => 'Mengubah Password via Web',
                    'old_value' => '***',
                    'new_value' => '***',
                    'changed_by' => 'customer',
                    'ip_address' => $request->ip(),
                    'user_agent' => $request->userAgent(),
                    'status' => 'processing'
                ]);

                $passSuccess = $this->updateGenieACSParameter(
                    $deviceId,
                    'InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.PreSharedKey.1.KeyPassphrase',
                    $request->new_password
                );

                if ($passSuccess) {
                    $logPass->update(['status' => 'success']);
                    $messages[] = 'Password berhasil diubah';
                } else {
                    $logPass->update(['status' => 'failed', 'description' => 'Gagal mengubah Password ke GenieACS']);
                    $success = false;
                    $messages[] = 'Gagal mengubah Password';
                }
            }

            if ($success) {
                Alert::success('Berhasil', implode(', ', $messages) . '. Perubahan akan diterapkan dalam 1-2 menit.');
            } else {
                Alert::warning('Peringatan', implode(', ', $messages));
            }

            return redirect()->route('wifi-settings.index');

        } catch (\Exception $e) {
            Alert::error('Error', 'Terjadi kesalahan: ' . $e->getMessage());
            return redirect()->back();
        }
    }

    /**
     * Update GenieACS parameter (Robust helper)
     */
    private function updateGenieACSParameter($deviceId, $parameterName, $value)
    {
        try {
            $url = GenieAcsSetting::getValue('genieacs_url');
            $username = GenieAcsSetting::getValue('genieacs_username');
            $password = GenieAcsSetting::getValue('genieacs_password');

            if (!$url || !$deviceId) {
                return false;
            }

            // Use connection_request for immediate execution
            $requestUrl = $url . '/devices/' . urlencode($deviceId) . '/tasks?timeout=3000&connection_request';
            
            $postData = json_encode([
                'name' => 'setParameterValues',
                'parameterValues' => [
                    [
                        'name' => $parameterName,
                        'value' => $value
                    ]
                ]
            ]);
            
            $ch = curl_init($requestUrl);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, $postData);
            curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
            curl_setopt($ch, CURLOPT_TIMEOUT, 30);
            
            if ($username && $password) {
                try {
                    $decryptedPassword = decrypt($password);
                    curl_setopt($ch, CURLOPT_USERPWD, "$username:$decryptedPassword");
                } catch (\Exception $e) {
                    curl_setopt($ch, CURLOPT_USERPWD, "$username:$password");
                }
            }

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            return $httpCode == 200 || $httpCode == 202;
        } catch (\Exception $e) {
            return false;
        }
    }

    /**
     * Get connected devices from GenieACS
     */
    private function getConnectedDevices($pelanggan)
    {
        try {
            $url = GenieAcsSetting::getValue('genieacs_url');
            $username = GenieAcsSetting::getValue('genieacs_username');
            $password = GenieAcsSetting::getValue('genieacs_password');

            if (!$url || !$pelanggan->ip_address) {
                return [];
            }

            // Query device by IP address (Robust)
            $query = json_encode([
                '$or' => [
                    ['InternetGatewayDevice.WANDevice.1.WANConnectionDevice.1.WANIPConnection.1.ExternalIPAddress' => $pelanggan->ip_address],
                    ['VirtualParameters.pppoeIP' => $pelanggan->ip_address]
                ]
            ]);
            
            $deviceUrl = $url . '/devices?query=' . urlencode($query);
            
            $ch = curl_init($deviceUrl);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_TIMEOUT, 10);
            
            if ($username && $password) {
                try {
                    $decryptedPassword = decrypt($password);
                    curl_setopt($ch, CURLOPT_USERPWD, "$username:$decryptedPassword");
                } catch (\Exception $e) {
                    curl_setopt($ch, CURLOPT_USERPWD, "$username:$password");
                }
            }

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            $devices = [];
            if ($httpCode == 200 && $response) {
                $devices = json_decode($response, true);
            }

            // Fallback to regex query if strict query fails
            if (empty($devices)) {
                $deviceUrl = $url . '/devices?query=' . urlencode('{"InternetGatewayDevice.ManagementServer.ConnectionRequestURL":{"$regex":"' . $pelanggan->ip_address . '"}}');
                
                $ch = curl_init($deviceUrl);
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                curl_setopt($ch, CURLOPT_TIMEOUT, 10);
                
                if ($username && $password) {
                    try {
                        $decryptedPassword = decrypt($password);
                        curl_setopt($ch, CURLOPT_USERPWD, "$username:$decryptedPassword");
                    } catch (\Exception $e) {
                        curl_setopt($ch, CURLOPT_USERPWD, "$username:$password");
                    }
                }

                $response = curl_exec($ch);
                $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                curl_close($ch);

                if ($httpCode == 200 && $response) {
                    $devices = json_decode($response, true);
                }
            }

            if (!empty($devices)) {
                    $device = $devices[0];
                    
                    // Get connected hosts from LANDevice
                    $connectedDevices = [];
                    
                    // Try to get hosts from common paths
                    if (isset($device['InternetGatewayDevice']['LANDevice'])) {
                        foreach ($device['InternetGatewayDevice']['LANDevice'] as $lanKey => $lanDevice) {
                            if (isset($lanDevice['Hosts']['Host'])) {
                                foreach ($lanDevice['Hosts']['Host'] as $hostKey => $host) {
                                    // Check if host is active
                                    $active = $host['Active']['_value'] ?? false;
                                    
                                    if ($active) {
                                        $connectedDevices[] = [
                                            'device_name' => $host['HostName']['_value'] ?? 'Unknown',
                                            'ip_address' => $host['IPAddress']['_value'] ?? '-',
                                            'mac_address' => $host['MACAddress']['_value'] ?? '-',
                                            'type' => $host['InterfaceType']['_value'] ?? '-'
                                        ];
                                    }
                                }
                            }
                        }
                    }
                    
                    return $connectedDevices;
                }

            return [];
        } catch (\Exception $e) {
            return [];
        }
    }

    /**
     * Delete history log
     */
    public function destroy($id)
    {
        $pelanggan = Auth::guard('pelanggan')->user();
        
        $log = WifiChangeHistory::where('id', $id)
            ->where('id_pelanggan', $pelanggan->id_pelanggan)
            ->first();
            
        if (!$log) {
            Alert::error('Error', 'Riwayat tidak ditemukan');
            return redirect()->back();
        }
        
        $log->delete();
        
        Alert::success('Berhasil', 'Riwayat berhasil dihapus');
        return redirect()->back();
    }
}
