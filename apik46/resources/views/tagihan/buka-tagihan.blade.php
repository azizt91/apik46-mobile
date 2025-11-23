@extends('template.app')

@section('contents')
<div class="card shadow mb-4">
    <div class="card-header py-3">
        <h6 class="m-0 font-weight-bold text-primary">Data Tagihan</h6>	
    </div>
    <div class="card-body">
        <form class="form-horizontal" action="{{ route('data-tagihan') }}" method="GET">
            @csrf
            <div class="container">
                <!-- Dropdown Bulan -->
                <div class="row">
                    <label class="col-md-2 control-label">Bulan</label>
                    <div class="col-md-4">
                        <div class="form-group">
                            <select name="bulan" id="bulan" class="custom-select" style="width: 100%;" required>
                                <option value="">Pilih Bulan</option>
                                @foreach($bulanList as $bulanItem)
                                    <option value="{{ $bulanItem['id'] }}" {{ $bulan == $bulanItem['id'] ? 'selected' : '' }}>
                                        {{ $bulanItem['bulan'] }}
                                    </option>
                                @endforeach
                            </select>
                        </div>
                    </div>
                </div>
        
                <!-- Dropdown Tahun -->
                <div class="row">
                    <label class="col-md-2 control-label">Tahun</label>
                    <div class="col-md-4">
                        <div class="form-group">
                            <select name="tahun" id="tahun" class="custom-select" style="width: 100%;" required>
                                <option value="">Pilih Tahun</option>
                                @for($year = 2021; $year <= date('Y')+5; $year++)
                                    <option value="{{ $year }}" {{ $tahun == $year ? 'selected' : '' }}>{{ $year }}</option>
                                @endfor
                            </select>
                        </div>
                    </div>
                </div>
        
                <!-- Tombol Submit -->
                <div class="row">
                    <div class="col-md-12">
                        <button type="submit" class="btn btn-primary" name="Lihat">
                            <i class="fas fa-search"></i> Lihat
                        </button>
                    </div>
                </div>
            </div>
        </form>        
    </div>
</div>

<!-- Alert Info Periode -->
<div class="alert alert-info" role="alert">
    <i class="fas fa-info-circle"></i> 
    Data Tagihan Belum Lunas - {{ DateTime::createFromFormat('m', $bulan)->format('F') }} {{ $tahun }}
</div>

<!-- Card Data Tagihan -->
<div class="card shadow mb-4">
    <div class="card-header py-3 d-flex justify-content-between align-items-center">
        <h6 class="m-0 font-weight-bold text-primary">Daftar Tagihan</h6>
        @if(count($tagihanList) > 0)
        <a href="{{ route('export-tagihan', ['bulan' => $bulan, 'tahun' => $tahun]) }}" class="btn btn-success btn-sm">
            <i class="fas fa-file-excel"></i> Export to Excel
        </a>
        @endif
    </div>
    <div class="card-body">
        @if(count($tagihanList) > 0)
        <div class="table-responsive">
            <table class="table table-striped table-bordered table-sm" id="dataTable" width="100%">
                <thead>
                    <tr>
                        <th>No</th>
                        <th>ID PELANGGAN</th>
                        <th>Nama</th>
                        <th>Tagihan</th>
                        <th>Status</th>
                        <th>Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($tagihanList as $no => $data)
                    <tr>
                        <td>{{ $no + 1 }}</td>
                        <td>{{ $data->id_pelanggan }}</td>
                        <td>{{ $data->pelanggan->nama }}</td>
                        <td>{{ rupiah($data->tagihan) }}</td>
                        <td>
                            @if($data->status === 'BL' || !isset($data->tgl_bayar))
                            <span class="badge bg-danger text-white rounded-pill">Belum Bayar</span>
                            @else
                            <span class="badge bg-success text-white rounded-pill">Lunas ({{ $data->tgl_bayar }})</span>
                            @endif
                        </td>
                        <td>
                            <form action="{{ route('bayar-tagihan', ['kode' => $data->id]) }}" method="POST" class="d-inline form-lunas">
                                @csrf
                                <button type="button" class="btn btn-info btn-sm btn-lunas" title="Bayar">
                                    <i class="fas fa-money-bill-wave"></i>
                                </button>
                            </form>
                            <a href="https://api.whatsapp.com/send?phone={{ $data->pelanggan->whatsapp }}&text=Sdr/i%20{{ $data->pelanggan->nama }},%20Anda%20belum%20melakukan%20pembayaran%20Tagihan%20Internet%20untuk%20Bulan%20{{ $data->bulan }}%20Tahun%20{{ $data->tahun }}%20*Admin Selinggo-Net*" 
                               target="_blank" 
                               title="Pesan WhatsApp" 
                               class="btn btn-success btn-sm">
                                <i class="fab fa-whatsapp"></i>
                            </a>
                            <form action="{{ route('delete-tagihan', ['id' => $data->id]) }}" method="POST" class="d-inline form-hapus">
                                @csrf
                                @method('DELETE')
                                <button type="button" class="btn btn-danger btn-sm btn-hapus" title="Hapus">
                                    <i class="fas fa-trash"></i>
                                </button>
                            </form>
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
        @else
        <div class="text-center py-5">
            <img class="img-fluid px-3 px-sm-4 mt-3 mb-4" style="width: 20rem;" src="{{ asset('template/img/empty.svg') }}" alt="No Data">
            <p class="text-muted">Tidak ada tagihan untuk periode ini.</p>
        </div>
        @endif
    </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function () {
    // Confirm Lunas
    const lunasButtons = document.querySelectorAll('.btn-lunas');
    lunasButtons.forEach(button => {
        button.addEventListener('click', function () {
            Swal.fire({
                title: 'Apakah yakin sudah lunas?',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#3085d6',
                cancelButtonColor: '#d33',
                confirmButtonText: 'Ya, lunas!',
                cancelButtonText: 'Batal'
            }).then((result) => {
                if (result.isConfirmed) {
                    this.closest('form').submit();
                }
            })
        });
    });

    // Confirm Hapus
    const hapusButtons = document.querySelectorAll('.btn-hapus');
    hapusButtons.forEach(button => {
        button.addEventListener('click', function () {
            Swal.fire({
                title: 'Apakah yakin ingin menghapus tagihan ini?',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#3085d6',
                cancelButtonColor: '#d33',
                confirmButtonText: 'Ya, hapus!',
                cancelButtonText: 'Batal'
            }).then((result) => {
                if (result.isConfirmed) {
                    this.closest('form').submit();
                }
            })
        });
    });
});
</script>
@endsection
