@extends('layout.app')

@section('contents')
<div class="container-fluid">
    <style>
        @media (max-width: 576px) {
            .container-fluid {
                padding-left: 10px !important;
                padding-right: 10px !important;
            }
            .card-body {
                padding: 1rem !important;
            }
            .card-header {
                padding: 0.75rem 1rem !important;
            }
            .alert {
                padding: 0.75rem 1rem !important;
            }
        }
    </style>
    <!-- Info Card -->
    <div class="alert alert-info" role="alert">
        <i class="fas fa-info-circle"></i>
        <strong>Informasi Penting:</strong>
        <ul class="mb-0 mt-2">
            <li>Perubahan SSID dan Password akan diterapkan ke router WiFi Anda</li>
            <li>Proses membutuhkan waktu 1-2 menit</li>
            <li>Setelah berhasil, hubungkan ulang perangkat Anda ke WiFi dengan nama dan password baru</li>
        </ul>
    </div>

    <!-- Current WiFi Info -->
    <div class="card shadow mb-4">
        <div class="card-header py-3">
            <h6 class="m-0 font-weight-bold text-primary">
                <i class="fas fa-wifi"></i> Informasi WiFi Saat Ini
            </h6>
        </div>
        <div class="card-body">
            <div class="row">
                <div class="col-md-4">
                    <div class="mb-3">
                        <small class="text-muted">Nama WiFi (SSID)</small>
                        <h5 class="mb-0">{{ $currentWifi['ssid'] }}</h5>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="mb-3">
                        <small class="text-muted">Password WiFi</small>
                        <h5 class="mb-0">{{ $currentWifi['password'] }}</h5>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="mb-3">
                        <small class="text-muted">IP Address</small>
                        <h5 class="mb-0">{{ $currentWifi['ip'] }}</h5>
                    </div>
                </div>
            </div>
            <small class="text-muted">
                <i class="fas fa-exclamation-triangle"></i> 
                SSID saat ini mungkin tidak dapat diambil karena keterbatasan akses. Anda tetap dapat mengganti WiFi dengan mengisi form di bawah.
            </small>
        </div>
    </div>

    <!-- Perangkat Terhubung -->
    <div class="card shadow mb-4">
        <div class="card-header py-3 d-flex justify-content-between align-items-center">
            <h6 class="m-0 font-weight-bold text-primary">
                <i class="fas fa-network-wired"></i> Perangkat Terhubung
            </h6>
            <button type="button" class="btn btn-sm btn-primary" id="refresh-devices-btn">
                <i class="fas fa-sync-alt"></i> Refresh
            </button>
        </div>
        <div class="card-body">
            <div id="devices-container">
                @if(count($connectedDevices) > 0)
                <div class="table-responsive">
                    <table class="table table-bordered table-sm">
                        <thead class="thead-light">
                            <tr>
                                <th>Device</th>
                                <th>IP Address</th>
                                <th>MAC Address</th>
                                <th>Type</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($connectedDevices as $device)
                            <tr>
                                <td><small>{{ $device['device_name'] }}</small></td>
                                <td><small>{{ $device['ip_address'] }}</small></td>
                                <td><small>{{ $device['mac_address'] }}</small></td>
                                <td><small>{{ $device['type'] }}</small></td>
                            </tr>
                            @endforeach
                        </tbody>
                    </table>
                    <small class="text-muted">
                        <i class="fas fa-info-circle"></i> 
                        Total: {{ count($connectedDevices) }} perangkat terhubung
                    </small>
                </div>
                @else
                <div class="text-center py-4">
                    <i class="fas fa-plug fa-3x text-muted mb-3"></i>
                    <p class="text-muted">Tidak ada perangkat terhubung atau data tidak dapat diambil</p>
                    <small class="text-muted">Klik tombol Refresh untuk memuat ulang</small>
                </div>
                @endif
            </div>
        </div>
    </div>

    <!-- Form Ganti WiFi -->
    <div class="card shadow mb-4">
        <div class="card-header py-3">
            <h6 class="m-0 font-weight-bold text-primary">
                <i class="fas fa-edit"></i> Ganti SSID & Password
            </h6>
        </div>
        <div class="card-body">
            <form action="{{ route('wifi-settings.update') }}" method="POST" id="wifi-form">
                @csrf
                
                <!-- SSID Baru -->
                <div class="form-group">
                    <label for="new_ssid">Nama WiFi Baru (SSID)</label>
                    <input type="text" class="form-control @error('new_ssid') is-invalid @enderror" 
                           id="new_ssid" name="new_ssid" 
                           value="{{ old('new_ssid') }}"
                           placeholder="Contoh: WiFi-Rumah-Saya (opsional)" 
                           maxlength="32">
                    <small class="form-text text-muted">Kosongkan jika tidak ingin mengganti SSID. Maksimal 32 karakter.</small>
                    @error('new_ssid')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>

                <!-- Password Baru -->
                <div class="form-group">
                    <label for="new_password">Password WiFi Baru</label>
                    <div class="input-group">
                        <input type="password" class="form-control @error('new_password') is-invalid @enderror" 
                               id="new_password" name="new_password" 
                               placeholder="Minimal 8 karakter (opsional)" 
                               minlength="8">
                        <div class="input-group-append">
                            <button class="btn btn-outline-secondary" type="button" id="toggle-new-password">
                                <i class="fas fa-eye"></i>
                            </button>
                        </div>
                        @error('new_password')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>
                    <small class="form-text text-muted">Kosongkan jika tidak ingin mengganti password. Minimal 8 karakter jika diisi.</small>
                </div>

                <!-- Konfirmasi Password -->
                <div class="form-group">
                    <label for="confirm_password">Konfirmasi Password</label>
                    <div class="input-group">
                        <input type="password" class="form-control @error('confirm_password') is-invalid @enderror" 
                               id="confirm_password" name="confirm_password" 
                               placeholder="Ketik ulang password (jika diisi)" 
                               minlength="8">
                        <div class="input-group-append">
                            <button class="btn btn-outline-secondary" type="button" id="toggle-confirm-password">
                                <i class="fas fa-eye"></i>
                            </button>
                        </div>
                        @error('confirm_password')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>
                    <small id="password-match-error" class="form-text text-danger" style="display: none;">
                        <i class="fas fa-times-circle"></i> Password tidak cocok
                    </small>
                </div>

                <hr>

                <!-- Submit Button -->
                <div class="d-flex gap-2">
                    <button type="submit" class="btn btn-primary" id="submit-btn">
                        <i class="fas fa-save"></i> <span id="submit-text">Simpan Perubahan</span>
                        <span id="submit-loading" style="display: none;">
                            <i class="fas fa-spinner fa-spin"></i> Memproses...
                        </span>
                    </button>
                    <a href="{{ route('dashboard-pelanggan') }}" class="btn btn-secondary">
                        <i class="fas fa-arrow-left"></i> Kembali
                    </a>
                </div>
            </form>
        </div>
    </div>

    <!-- Riwayat Perubahan -->
    <div class="card shadow mb-4">
        <div class="card-header py-3">
            <h6 class="m-0 font-weight-bold text-primary">
                <i class="fas fa-history"></i> Riwayat Perubahan
            </h6>
        </div>
        <div class="card-body">
            @if($history->count() > 0)
            <div class="table-responsive">
                <table class="table table-bordered table-sm">
                    <thead>
                        <tr>
                            <th>Tanggal</th>
                            <th>SSID Lama</th>
                            <th>SSID Baru</th>
                            <th>Password Diubah</th>
                            <th>Status</th>
                            <th>Aksi</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($history as $item)
                        <tr>
                            <td><small>{{ $item->created_at->format('d/m/Y H:i') }}</small></td>
                            <td><small>{{ $item->old_value ?? '-' }}</small></td>
                            <td><small>{{ $item->new_value ?? '-' }}</small></td>
                            <td>
                                <small>
                                    @if($item->type == 'password')
                                        <span class="badge badge-info">Ya</span>
                                    @else
                                        <span class="badge badge-secondary">Tidak</span>
                                    @endif
                                </small>
                            </td>
                            <td>
                                <small>
                                    @if($item->status == 'success')
                                        <span class="badge badge-success">Berhasil</span>
                                    @elseif($item->status == 'failed')
                                        <span class="badge badge-danger" title="{{ $item->description }}">Gagal</span>
                                    @else
                                        <span class="badge badge-warning">Pending</span>
                                    @endif
                                </small>
                            </td>
                            <td>
                                <form action="{{ route('wifi-settings.destroy', $item->id) }}" method="POST" onsubmit="return confirm('Yakin ingin menghapus riwayat ini?');" style="display: inline;">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="btn btn-danger btn-sm p-1" title="Hapus Riwayat">
                                        <i class="fas fa-trash-alt fa-xs"></i>
                                    </button>
                                </form>
                            </td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
            @else
            <div class="text-center py-4">
                <i class="fas fa-inbox fa-3x text-muted mb-3"></i>
                <p class="text-muted">Belum ada riwayat perubahan</p>
            </div>
            @endif
        </div>
    </div>
</div>

@push('scripts')
<script>
// Refresh devices button
document.getElementById('refresh-devices-btn').addEventListener('click', function() {
    const btn = this;
    const originalHtml = btn.innerHTML;
    const icon = btn.querySelector('i');
    
    // Show loading
    btn.disabled = true;
    icon.classList.add('fa-spin');
    
    // Reload page to refresh devices
    setTimeout(function() {
        window.location.reload();
    }, 500);
});

// Toggle password visibility
function togglePassword(inputId, buttonId) {
    const input = document.getElementById(inputId);
    const button = document.getElementById(buttonId);
    const icon = button.querySelector('i');
    
    if (input.type === 'password') {
        input.type = 'text';
        icon.classList.remove('fa-eye');
        icon.classList.add('fa-eye-slash');
    } else {
        input.type = 'password';
        icon.classList.remove('fa-eye-slash');
        icon.classList.add('fa-eye');
    }
}

document.getElementById('toggle-new-password').addEventListener('click', function() {
    togglePassword('new_password', 'toggle-new-password');
});

document.getElementById('toggle-confirm-password').addEventListener('click', function() {
    togglePassword('confirm_password', 'toggle-confirm-password');
});

// Check password match
document.getElementById('confirm_password').addEventListener('input', function() {
    const newPassword = document.getElementById('new_password').value;
    const confirmPassword = this.value;
    const errorMsg = document.getElementById('password-match-error');
    
    if (newPassword && confirmPassword && newPassword !== confirmPassword) {
        errorMsg.style.display = 'block';
        this.classList.add('is-invalid');
    } else {
        errorMsg.style.display = 'none';
        this.classList.remove('is-invalid');
    }
});

// Form submission
document.getElementById('wifi-form').addEventListener('submit', function(e) {
    const newSsid = document.getElementById('new_ssid').value.trim();
    const newPassword = document.getElementById('new_password').value;
    const confirmPassword = document.getElementById('confirm_password').value;
    
    // Check if at least one field is filled
    if (!newSsid && !newPassword) {
        e.preventDefault();
        alert('Minimal isi salah satu: SSID atau Password');
        return false;
    }
    
    // Check password match
    if (newPassword && newPassword !== confirmPassword) {
        e.preventDefault();
        alert('Password dan konfirmasi password tidak cocok');
        return false;
    }
    
    // Show loading
    const submitBtn = document.getElementById('submit-btn');
    const submitText = document.getElementById('submit-text');
    const submitLoading = document.getElementById('submit-loading');
    
    submitBtn.disabled = true;
    submitText.style.display = 'none';
    submitLoading.style.display = 'inline';
    
    // Confirm
    if (!confirm('Apakah Anda yakin ingin mengubah pengaturan WiFi?\n\nSetelah berhasil, Anda perlu menghubungkan ulang perangkat ke WiFi.')) {
        e.preventDefault();
        submitBtn.disabled = false;
        submitText.style.display = 'inline';
        submitLoading.style.display = 'none';
        return false;
    }
});
</script>
@endpush

@endsection
