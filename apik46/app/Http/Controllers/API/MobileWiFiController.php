<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\WiFiSettings;
use App\Models\WifiChangeHistory;
use Illuminate\Support\Facades\Validator;

class MobileWiFiController extends Controller
{
    /**
     * Get current WiFi settings from GenieACS
     */
    public function index(Request $request)
    {
        $pelanggan = $request->user();
        
        // Try to get WiFi info from GenieACS first
        $wifiInfo = $this->getWiFiFromGenieACS($pelanggan);
        
        if ($wifiInfo) {
            return response()->json([
                'success' => true,
                'data' => [
                    'ssid' => $wifiInfo['ssid'],
                    'password' => $wifiInfo['password'],
                    'security_type' => 'WPA2-PSK',
                    'is_active' => true,
                    'last_changed' => null,
                    'pelanggan_nama' => $pelanggan->nama,
                    'pelanggan_id' => $pelanggan->id_pelanggan,
                    'ip_address' => $pelanggan->ip_address,
                ]
            ]);
        }
        
        // Fallback to database if GenieACS fails
        $wifiSettings = WiFiSettings::where('id_pelanggan', $pelanggan->id_pelanggan)->first();
        
        if (!$wifiSettings) {
            // Auto-create default WiFi settings
            $defaultSSID = 'APIK-' . $pelanggan->id_pelanggan;
            $defaultPassword = strtolower($pelanggan->id_pelanggan);
            
            $wifiSettings = WiFiSettings::create([
                'id_pelanggan' => $pelanggan->id_pelanggan,
                'ssid' => $defaultSSID,
                'password' => $defaultPassword,
                'security_type' => 'WPA2-PSK',
                'is_active' => true,
            ]);
            
            // Log creation
            WifiChangeHistory::create([
                'id_pelanggan' => $pelanggan->id_pelanggan,
                'type' => 'reset',
                'description' => 'WiFi settings auto-created with default values',
                'old_value' => null,
                'new_value' => $defaultSSID,
                'changed_by' => 'system',
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
            ]);
        }
        
        return response()->json([
            'success' => true,
            'data' => [
                'ssid' => $wifiSettings->ssid,
                'password' => $wifiSettings->getAttributeValue('password'),
                'security_type' => $wifiSettings->security_type,
                'is_active' => $wifiSettings->is_active,
                'last_changed' => $wifiSettings->updated_at,
                'pelanggan_nama' => $pelanggan->nama,
                'pelanggan_id' => $pelanggan->id_pelanggan,
                'ip_address' => $pelanggan->ip_address,
            ]
        ]);
    }
    
    /**
     * Get WiFi info from GenieACS
     */
    private function getWiFiFromGenieACS($pelanggan)
    {
        try {
            // Check if GenieACS is enabled using model method
            if (!\App\Models\GenieAcsSetting::isEnabled()) {
                return null;
            }
            
            $url = \App\Models\GenieAcsSetting::getValue('genieacs_url');
            $username = \App\Models\GenieAcsSetting::getValue('genieacs_username');
            $password = \App\Models\GenieAcsSetting::getValue('genieacs_password');

            if (!$url || !$pelanggan->ip_address) {
                return null;
            }

            // Query device by IP address using the reference implementation's query
            // Checks both ExternalIPAddress and VirtualParameters.pppoeIP
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
                
                // Try to get SSID and password from common paths
                $ssid = $device['InternetGatewayDevice']['LANDevice']['1']['WLANConfiguration']['1']['SSID']['_value'] ?? null;
                $password = $device['InternetGatewayDevice']['LANDevice']['1']['WLANConfiguration']['1']['PreSharedKey']['1']['KeyPassphrase']['_value'] ?? '********';
                
                if ($ssid) {
                    return [
                        'ssid' => $ssid,
                        'password' => $password,
                        'device_id' => $device['_id'] // Return device ID for updates
                    ];
                }
            }

            return null;
        } catch (\Exception $e) {
            return null;
        }
    }
    
    /**
     * Change SSID
     */
    public function changeSSID(Request $request)
    {
        $request->validate([
            'ssid' => 'required|string|min:3|max:32',
        ]);
        
        $pelanggan = $request->user();
        $newSSID = $request->ssid;
        
        // Log the attempt
        $log = WifiChangeHistory::create([
            'id_pelanggan' => $pelanggan->id_pelanggan,
            'type' => 'ssid',
            'description' => 'Changing SSID to ' . $newSSID,
            'old_value' => null, // Will be updated if successful
            'new_value' => $newSSID,
            'changed_by' => 'customer',
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
            'status' => 'processing'
        ]);

        // Try to update via GenieACS
        $wifiInfo = $this->getWiFiFromGenieACS($pelanggan);
        
        if ($wifiInfo && isset($wifiInfo['device_id'])) {
            $deviceId = $wifiInfo['device_id'];
            $success = $this->updateGenieACSParameter(
                $deviceId, 
                'InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.SSID', 
                $newSSID
            );
            
            if ($success) {
                // Update local database as backup/cache
                WiFiSettings::updateOrCreate(
                    ['id_pelanggan' => $pelanggan->id_pelanggan],
                    ['ssid' => $newSSID]
                );
                
                $log->update(['status' => 'success', 'old_value' => $wifiInfo['ssid']]);
                
                return response()->json([
                    'success' => true,
                    'message' => 'SSID berhasil diubah. Perubahan akan diterapkan dalam 1-2 menit.'
                ]);
            }
        }
        
        $log->update(['status' => 'failed', 'description' => 'Failed to connect to device']);
        
        return response()->json([
            'success' => false,
            'message' => 'Gagal mengubah SSID. Pastikan router terhubung ke internet.'
        ], 500);
    }

    /**
     * Change Password
     */
    public function changePassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'password' => 'required|string|min:8|max:63',
        ], [
            'password.required' => 'Password wajib diisi',
            'password.min' => 'Password minimal 8 karakter',
            'password.max' => 'Password maksimal 63 karakter',
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $pelanggan = $request->user();
        
        // Get WiFi settings
        $wifiSettings = WiFiSettings::where('id_pelanggan', $pelanggan->id_pelanggan)->first();
        
        if (!$wifiSettings) {
            return response()->json([
                'success' => false,
                'message' => 'Pengaturan WiFi belum ada. Silakan setup SSID terlebih dahulu.',
            ], 404);
        }
        
        $wifiSettings->password = $request->password;
        $wifiSettings->save();
        
        // Log history (don't store actual passwords)
        WifiChangeHistory::create([
            'id_pelanggan' => $pelanggan->id_pelanggan,
            'type' => 'password',
            'old_value' => '***',
            'new_value' => '***',
            'changed_by' => 'customer',
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);
        
        return response()->json([
            'success' => true,
            'message' => 'Password WiFi berhasil diubah',
            'data' => [
                'updated_at' => $wifiSettings->updated_at,
            ]
        ]);
    }
    
    /**
     * Get change history
     */
    public function history(Request $request)
    {
        $pelanggan = $request->user();
        
        $history = WifiChangeHistory::where('id_pelanggan', $pelanggan->id_pelanggan)
            ->orderBy('created_at', 'desc')
            ->limit(20)
            ->get()
            ->map(function ($item) {
                return [
                    'id' => $item->id,
                    'type' => $item->type,
                    'description' => $item->description,
                    'old_value' => $item->type === 'password' ? '***' : $item->old_value,
                    'new_value' => $item->type === 'password' ? '***' : $item->new_value,
                    'changed_by' => $item->changed_by,
                    'changed_at' => $item->created_at,
                    'ip_address' => $item->ip_address,
                    'status' => $item->status ?? 'success', // Add status field
                ];
            });
        
        return response()->json([
            'success' => true,
            'data' => $history
        ]);
    }
    
    /**
     * Update GenieACS parameter
     */
    private function updateGenieACSParameter($deviceId, $parameterName, $value)
    {
        try {
            if (!\App\Models\GenieAcsSetting::isEnabled()) {
                return false;
            }
            
            $url = \App\Models\GenieAcsSetting::getValue('genieacs_url');
            $username = \App\Models\GenieAcsSetting::getValue('genieacs_username');
            $password = \App\Models\GenieAcsSetting::getValue('genieacs_password');

            if (!$url || !$deviceId) {
                return false;
            }

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
     * Delete history log
     */
    public function deleteHistory(Request $request, $id)
    {
        $pelanggan = $request->user();
        
        $log = WifiChangeHistory::where('id', $id)
            ->where('id_pelanggan', $pelanggan->id_pelanggan)
            ->first();
            
        if (!$log) {
            return response()->json([
                'success' => false,
                'message' => 'Riwayat tidak ditemukan'
            ], 404);
        }
        
        $log->delete();
        
        return response()->json([
            'success' => true,
            'message' => 'Riwayat berhasil dihapus'
        ]);
    }
}

