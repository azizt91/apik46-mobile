<?php

namespace App\Http\Controllers;

use App\Models\Bulan;
use App\Models\Pelanggan;
use App\Models\Tagihan;
use App\Models\Paket;
use RealRashid\SweetAlert\Facades\Alert;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\View;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;
use Dompdf\Dompdf;
use GuzzleHttp\Client;
use PDF;

class TagihanController extends Controller
{
    public function index()
    {
        $bulanList = Bulan::all();
        $pelangganList = Pelanggan::where('status', 'aktif')->get();

        return view('tagihan.index', compact('bulanList', 'pelangganList'));
    }


    public function storeTagihan(Request $request)
    {
        // Validasi input dengan aturan yang lebih ketat
        $request->validate([
            'bulan' => 'required|integer|min:1|max:12', // Pastikan bulan valid
            'tahun' => 'required|integer|min:2000', // Tahun minimum
            'id_pelanggan' => 'required|array|min:1', // Pastikan ada minimal 1 pelanggan
            'id_pelanggan.*' => 'exists:pelanggan,id_pelanggan', // Setiap ID pelanggan harus ada di tabel pelanggan
        ]);

        $bulan = $request->bulan;
        $tahun = $request->tahun;
        $idPelangganBaru = []; // Array untuk menyimpan id_pelanggan baru

        try {
            // Logging input yang diterima
            Log::info('Data yang diterima untuk penyimpanan tagihan:', [
                'bulan' => $bulan,
                'tahun' => $tahun,
                'id_pelanggan' => $request->id_pelanggan
            ]);

            // Iterasi setiap pelanggan dari array
            foreach ($request->id_pelanggan as $id_pelanggan) {
                // Cek apakah tagihan untuk pelanggan ini sudah ada di bulan dan tahun yang sama
                $existingTagihan = Tagihan::where('bulan', $bulan)
                    ->where('tahun', $tahun)
                    ->where('id_pelanggan', $id_pelanggan)
                    ->first();

                if ($existingTagihan) {
                    Log::warning('Tagihan sudah ada untuk pelanggan ini. Melewati.', ['id_pelanggan' => $id_pelanggan]);
                    continue; // Skip jika tagihan sudah ada
                }

                // Tambahkan id_pelanggan baru ke array
                $idPelangganBaru[] = $id_pelanggan;
            }

            // Proses hanya pelanggan baru
            foreach ($idPelangganBaru as $id_pelanggan) {
                // Ambil pelanggan dengan relasi paket dan log jika pelanggan ditemukan
                $pelanggan = Pelanggan::with('paket')->findOrFail($id_pelanggan);
                Log::info('Pelanggan ditemukan:', ['id_pelanggan' => $id_pelanggan]);

                // Cek apakah pelanggan statusnya aktif
                if ($pelanggan->status == 'aktif') {
                    Log::info('Pelanggan aktif, ID:', ['id_pelanggan' => $id_pelanggan]);

                    // Pastikan relasi paket ada, jika tidak, log error dan lanjutkan ke pelanggan berikutnya
                    if ($pelanggan->paket) {
                        $tarifPelanggan = $pelanggan->paket->tarif;
                        Log::info('Tarif paket pelanggan:', ['id_pelanggan' => $id_pelanggan, 'tarif' => $tarifPelanggan]);

                        // Buat objek Tagihan baru
                        $tagihan = new Tagihan([
                            'bulan' => $bulan,
                            'tahun' => $tahun,
                            'id_pelanggan' => $id_pelanggan,
                            'tagihan' => $tarifPelanggan,
                            'status' => 'BL', // Status 'BL' untuk tagihan baru
                        ]);

                        // Simpan tagihan ke database
                        $tagihan->save();
                        Log::info('Tagihan berhasil disimpan untuk pelanggan:', ['id_pelanggan' => $id_pelanggan]);

                    } else {
                        Log::warning('Pelanggan tidak memiliki paket, melewati.', ['id_pelanggan' => $id_pelanggan]);
                        continue; // Skip pelanggan yang tidak memiliki paket
                    }
                } else {
                    Log::warning('Pelanggan tidak aktif, melewati.', ['id_pelanggan' => $id_pelanggan]);
                }
            }

            // Jika semua tagihan berhasil disimpan, tampilkan alert sukses
            Alert::success('Sukses', 'Tagihan berhasil disimpan');
            Log::info('Semua tagihan berhasil disimpan.');
        } catch (\Exception $e) {
            // Tangkap error dan tampilkan alert error
            Log::error('Error menyimpan tagihan:', ['message' => $e->getMessage(), 'trace' => $e->getTraceAsString()]);
            Alert::error('Error', 'Tagihan gagal disimpan. Pesan: ' . $e->getMessage());
        }

        // Redirect kembali ke halaman 'buka-tagihan'
        return redirect()->route('buka-tagihan');
    }



    // public function storeTagihan(Request $request)
    // {
    //     // Validasi input dengan aturan yang lebih ketat
    //     $request->validate([
    //         'bulan' => 'required|integer|min:1|max:12', // Pastikan bulan valid
    //         'tahun' => 'required|integer|min:2000', // Tahun minimum
    //         'id_pelanggan' => 'required|array|min:1', // Pastikan ada minimal 1 pelanggan
    //         'id_pelanggan.*' => 'exists:pelanggan,id_pelanggan', // Setiap ID pelanggan harus ada di tabel pelanggan
    //     ]);

    //     $bulan = $request->bulan;
    //     $tahun = $request->tahun;

    //     try {
    //         // Logging input yang diterima
    //         Log::info('Data yang diterima untuk penyimpanan tagihan:', [
    //             'bulan' => $bulan,
    //             'tahun' => $tahun,
    //             'id_pelanggan' => $request->id_pelanggan
    //         ]);

    //         // Iterasi setiap pelanggan dari array
    //         foreach ($request->id_pelanggan as $id_pelanggan) {
    //             // Ambil pelanggan dengan relasi paket dan log jika pelanggan ditemukan
    //             $pelanggan = Pelanggan::with('paket')->findOrFail($id_pelanggan);
    //             Log::info('Pelanggan ditemukan:', ['id_pelanggan' => $id_pelanggan]);

    //             // Cek apakah pelanggan statusnya aktif
    //             if ($pelanggan->status == 'aktif') {
    //                 Log::info('Pelanggan aktif, ID:', ['id_pelanggan' => $id_pelanggan]);

    //                 // Pastikan relasi paket ada, jika tidak, log error dan lanjutkan ke pelanggan berikutnya
    //                 if ($pelanggan->paket) {
    //                     $tarifPelanggan = $pelanggan->paket->tarif;
    //                     Log::info('Tarif paket pelanggan:', ['id_pelanggan' => $id_pelanggan, 'tarif' => $tarifPelanggan]);

    //                     // Cek apakah tagihan untuk pelanggan ini sudah ada di bulan dan tahun yang sama
    //                     $existingTagihan = Tagihan::where('bulan', $bulan)
    //                     ->where('tahun', $tahun)
    //                     ->where('id_pelanggan', $id_pelanggan)
    //                     ->first();

    //                     if ($existingTagihan) {
    //                         Log::warning('Tagihan sudah ada untuk pelanggan ini. Melewati.', ['id_pelanggan' => $id_pelanggan]);
    //                         continue; // Skip jika tagihan sudah ada
    //                     }

    //                     // Buat objek Tagihan baru
    //                     $tagihan = new Tagihan([
    //                         'bulan' => $bulan,
    //                         'tahun' => $tahun,
    //                         'id_pelanggan' => $id_pelanggan,
    //                         'tagihan' => $tarifPelanggan,
    //                         'status' => 'BL', // Status 'BL' untuk tagihan baru
    //                     ]);

    //                     // Simpan tagihan ke database
    //                     $tagihan->save();
    //                     Log::info('Tagihan berhasil disimpan untuk pelanggan:', ['id_pelanggan' => $id_pelanggan]);

    //                 } else {
    //                     Log::warning('Pelanggan tidak memiliki paket, melewati.', ['id_pelanggan' => $id_pelanggan]);
    //                     continue; // Skip pelanggan yang tidak memiliki paket
    //                 }
    //             } else {
    //                 Log::warning('Pelanggan tidak aktif, melewati.', ['id_pelanggan' => $id_pelanggan]);
    //             }
    //         }

    //         // Jika semua tagihan berhasil disimpan, tampilkan alert sukses
    //         Alert::success('Sukses', 'Tagihan berhasil disimpan');
    //         Log::info('Semua tagihan berhasil disimpan.');
    //     } catch (\Exception $e) {
    //         // Tangkap error dan tampilkan alert error
    //         Log::error('Error menyimpan tagihan:', ['message' => $e->getMessage(), 'trace' => $e->getTraceAsString()]);
    //         Alert::error('Error', 'Tagihan gagal disimpan. Pesan: ' . $e->getMessage());
    //     }

    //     // Redirect kembali ke halaman 'buka-tagihan'
    //     return redirect()->route('buka-tagihan');
    // }

    // public function storeTagihan(Request $request)
    // {
    //     // Validasi input dengan aturan yang lebih ketat
    //     $request->validate([
    //         'bulan' => 'required|integer|min:1|max:12', // Pastikan bulan valid
    //         'tahun' => 'required|integer|min:2000', // Tahun minimum
    //         'id_pelanggan' => 'required|array|min:1', // Pastikan ada minimal 1 pelanggan
    //         'id_pelanggan.*' => 'exists:pelanggan,id_pelanggan', // Setiap ID pelanggan harus ada di tabel pelanggan
    //     ]);

    //     $bulan = $request->bulan;
    //     $tahun = $request->tahun;

    //     try {
    //         // Logging input yang diterima
    //         Log::info('Data yang diterima untuk penyimpanan tagihan:', [
    //             'bulan' => $bulan,
    //             'tahun' => $tahun,
    //             'id_pelanggan' => $request->id_pelanggan
    //         ]);

    //         // Ambil nama bulan dari tabel bulan
    //         $namaBulan = Bulan::where('id', $bulan)->first()->bulan;

    //         // Iterasi setiap pelanggan dari array
    //         foreach ($request->id_pelanggan as $id_pelanggan) {
    //             // Ambil pelanggan dengan relasi paket dan log jika pelanggan ditemukan
    //             $pelanggan = Pelanggan::with('paket')->findOrFail($id_pelanggan);
    //             Log::info('Pelanggan ditemukan:', ['id_pelanggan' => $id_pelanggan]);

    //             // Cek apakah pelanggan statusnya aktif
    //             if ($pelanggan->status == 'aktif') {
    //                 Log::info('Pelanggan aktif, ID:', ['id_pelanggan' => $id_pelanggan]);

    //                 // Pastikan relasi paket ada, jika tidak, log error dan lanjutkan ke pelanggan berikutnya
    //                 if ($pelanggan->paket) {
    //                     $tarifPelanggan = $pelanggan->paket->tarif;
    //                     Log::info('Tarif paket pelanggan:', ['id_pelanggan' => $id_pelanggan, 'tarif' => $tarifPelanggan]);

    //                     // Cek apakah tagihan untuk pelanggan ini sudah ada di bulan dan tahun yang sama
    //                     $existingTagihan = Tagihan::where('bulan', $bulan)
    //                     ->where('tahun', $tahun)
    //                     ->where('id_pelanggan', $id_pelanggan)
    //                     ->first();

    //                     if ($existingTagihan) {
    //                         Log::warning('Tagihan sudah ada untuk pelanggan ini. Melewati.', ['id_pelanggan' => $id_pelanggan]);
    //                         continue; // Skip jika tagihan sudah ada
    //                     }

    //                     // Buat objek Tagihan baru
    //                     $tagihan = new Tagihan([
    //                         'bulan' => $bulan,
    //                         'tahun' => $tahun,
    //                         'id_pelanggan' => $id_pelanggan,
    //                         'tagihan' => $tarifPelanggan,
    //                         'status' => 'BL', // Status 'BL' untuk tagihan baru
    //                     ]);

    //                     // Simpan tagihan ke database
    //                     $tagihan->save();
    //                     Log::info('Tagihan berhasil disimpan untuk pelanggan:', ['id_pelanggan' => $id_pelanggan]);

    //                     // Kirim pesan WhatsApp setelah tagihan disimpan

    //                     // Format pesan dengan jumlah tagihan menggunakan Rupiah dan bulan dalam teks
    //                     $formattedTagihan = rupiah($tagihan->tagihan);
    //                     $paymentUrl = url("/tagihan/{$tagihan->id}/payment");
    //                     $message = "Hai Bapak/Ibu {$pelanggan->nama},\nID Pelanggan: {$tagihan->id_pelanggan}\n\nInformasi tagihan Bapak/Ibu bulan ini adalah:\n\nJumlah Tagihan: {$formattedTagihan}\nPeriode Tagihan: {$namaBulan} {$tagihan->tahun}\nTanggal Jatuh Tempo: {$pelanggan->jatuh_tempo} {$namaBulan} {$tagihan->tahun}\n\nBayar tagihan sekarang lebih praktis dan mudah dengan menekan link dibawah ini, dengan pilihan pembayaran yang beragam (Transfer Langsung, QRIS, E-Wallet, VA).\n\n{$paymentUrl}";

    //                     // // Kirim pesan WhatsApp setelah tagihan disimpan
    //                     $this->sendWhatsAppMessage($pelanggan->whatsapp, $message);

    //                 } else {
    //                     Log::warning('Pelanggan tidak memiliki paket, melewati.', ['id_pelanggan' => $id_pelanggan]);
    //                     continue; // Skip pelanggan yang tidak memiliki paket
    //                 }
    //             } else {
    //                 Log::warning('Pelanggan tidak aktif, melewati.', ['id_pelanggan' => $id_pelanggan]);
    //             }
    //         }

    //         // Jika semua tagihan berhasil disimpan, tampilkan alert sukses
    //         Alert::success('Sukses', 'Tagihan berhasil disimpan');
    //         Log::info('Semua tagihan berhasil disimpan.');
    //     } catch (\Exception $e) {
    //         // Tangkap error dan tampilkan alert error
    //         Log::error('Error menyimpan tagihan:', ['message' => $e->getMessage(), 'trace' => $e->getTraceAsString()]);
    //         Alert::error('Error', 'Tagihan gagal disimpan. Pesan: ' . $e->getMessage());
    //     }

    //     // Redirect kembali ke halaman 'buka-tagihan'
    //     return redirect()->route('buka-tagihan');
    // }

    // private function sendWhatsAppMessage($number, $message)
    // {
    //     $client = new Client();
    //     $client->post(env('WHATSAPP_ENDPOINT'), [
    //         'query' => [
    //             'api_key' => env('WHATSAPP_API_KEY'),
    //             'sender' => env('WHATSAPP_SENDER'),
    //             'number' => $number,
    //             'message' => $message,
    //         ]
    //     ]);
    // }


    public function bukaTagihan(Request $request)
    {
        // Fetch the list of months and years
        $bulanList = Bulan::all();
        $tahunList = range(date('Y'), date('Y') + 5);

        $pelangganList = Pelanggan::where('status', 'aktif')->get();
        
        // Default ke bulan dan tahun sekarang jika tidak ada request
        $bulan = $request->input('bulan', date('m'));
        $tahun = $request->input('tahun', date('Y'));
        
        // Ambil data tagihan yang BELUM LUNAS saja (status = BL)
        $tagihanList = Tagihan::where('bulan', $bulan)
                              ->where('tahun', $tahun)
                              ->where('status', 'BL')
                              ->with('pelanggan')
                              ->get();

        return view('tagihan.buka-tagihan', compact('bulanList', 'tahunList', 'tagihanList', 'bulan', 'tahun'));
    }

    public function dataTagihan(Request $request)
    {
        $request->validate([
            'bulan' => 'required',
            'tahun' => 'required',
        ]);

        $bulan = $request->input('bulan');
        $tahun = $request->input('tahun');

        // Redirect ke buka-tagihan dengan parameter
        return redirect()->route('buka-tagihan', ['bulan' => $bulan, 'tahun' => $tahun]);
    }

    public function bayarTagihan(Request $request, $kode)
    {
        // Temukan tagihan berdasarkan kode atau id_tagihan
        $tagihan = Tagihan::find($kode);

        // Cek apakah tagihan ditemukan
        if (!$tagihan) {
            Alert::error('Error', 'Tagihan tidak ditemukan');
            return redirect()->route('buka-tagihan');
        }

        // Update status dan tanggal bayar tanpa memeriksa apakah sudah lunas
        $tagihan->status = 'LS';
        $tagihan->tgl_bayar = now();
        $tagihan->pembayaran_via = 'cash';
        $tagihan->save();

        Alert::success('Sukses', 'Pembayaran tagihan berhasil');
        
        // Redirect kembali ke buka-tagihan dengan parameter bulan dan tahun
        return redirect()->route('buka-tagihan', [
            'bulan' => $tagihan->bulan,
            'tahun' => $tagihan->tahun
        ]);
    }

    public function lunasTagihan()
    {
        
        return view('tagihan.lunas-tagihan');

    }
    
    public function rollbackTagihan($id)
    {
        // Temukan tagihan berdasarkan ID
        $tagihan = Tagihan::find($id);

        // Cek apakah tagihan ditemukan
        if (!$tagihan) {
            Alert::error('Error', 'Tagihan tidak ditemukan');
            return redirect()->route('lunas-tagihan');
        }

        // Rollback status ke Belum Lunas
        $tagihan->status = 'BL';
        $tagihan->tgl_bayar = null;
        // Reset ke default value 'cash' (kolom ENUM tidak nullable)
        $tagihan->pembayaran_via = 'cash';
        $tagihan->save();

        Alert::success('Sukses', 'Status tagihan berhasil dikembalikan ke Belum Lunas');
        return redirect()->route('lunas-tagihan');
    }

    public function cetakStruk($id)
{
    // Temukan tagihan berdasarkan ID
    $tagihan = Tagihan::find($id);

    // Pastikan tagihan ditemukan
    if (!$tagihan) {
        return redirect()->route('buka-tagihan')->with('error', 'Tagihan tidak ditemukan');
    }
    
    // Render view to HTML
    $html = View::make('tagihan.cetak-struk', compact('tagihan'))->render();
    
    // Buat objek Dompdf
    $dompdf = new Dompdf();
    
    // Set base path untuk DOMPDF
    $options = $dompdf->getOptions();
    $options->set('isRemoteEnabled', true);
    $dompdf->setOptions($options);
    
    // Load HTML content
    $dompdf->loadHtml($html);
    $dompdf->setPaper('A4', 'portrait');
    
    // Render PDF
    $dompdf->render();
    
    // Tampilkan PDF dengan memberikan nama file pada saat streaming
    return $dompdf->stream('struk_pembayaran.pdf');
}



    // public function lunas()
    // {
    //     $bulanIni = Carbon::now()->month;
    //     $tahunIni = Carbon::now()->year;

    //     $pelangganLunas = Pelanggan::where('status', 'aktif')
    //     ->whereHas('tagihan', function ($query) use ($bulanIni, $tahunIni) {
    //         $query->where('status', 'LS')
    //         ->whereMonth('created_at', $bulanIni)
    //         ->whereYear('created_at', $tahunIni);
    //     })->get();

    //     return view('tagihan.lunas', compact('pelangganLunas'));
    // }
    
    public function lunas()
    {
        $bulanIni = Carbon::now()->month;
        $tahunIni = Carbon::now()->year;
    
        $pelangganLunas = Pelanggan::where('status', 'aktif')
        ->whereHas('tagihan', function ($query) use ($bulanIni, $tahunIni) {
            $query->where('status', 'LS')
            ->where('bulan', $bulanIni) // Periksa bulan tagihan
            ->where('tahun', $tahunIni); // Periksa tahun tagihan
        })->get();
    
        return view('tagihan.lunas', compact('pelangganLunas'));
    }


    // public function belumLunas()
    // {
    //     $bulanIni = Carbon::now()->month;
    //     $tahunIni = Carbon::now()->year;
    
    //     $pelangganBelumLunas = Pelanggan::where('status', 'aktif')
    //         ->whereDoesntHave('tagihan', function ($query) use ($bulanIni, $tahunIni) {
    //             $query->where('status', 'LS')
    //                   ->whereMonth('created_at', $bulanIni)
    //                   ->whereYear('created_at', $tahunIni);
    //         })
    //         ->orWhere(function ($query) use ($bulanIni, $tahunIni) {
    //             $query->whereHas('tagihan', function ($query) use ($bulanIni, $tahunIni) {
    //                 $query->where('status', '!=', 'LS')
    //                       ->whereMonth('created_at', $bulanIni)
    //                       ->whereYear('created_at', $tahunIni);
    //             });
    //         })->get();
    
    //     return view('tagihan.belumLunas', compact('pelangganBelumLunas'));
    // }
    
        public function belumLunas()
    {
        $bulanIni = Carbon::now()->month;
        $tahunIni = Carbon::now()->year;

        $pelangganBelumLunas = Pelanggan::where('status', 'aktif')
            ->whereDoesntHave('tagihan', function ($query) use ($bulanIni, $tahunIni) {
                $query->where('status', 'LS')
                    ->where('bulan', $bulanIni) // Periksa bulan tagihan
                    ->where('tahun', $tahunIni); // Periksa tahun tagihan
            })
            ->orWhere(function ($query) use ($bulanIni, $tahunIni) {
                $query->whereHas('tagihan', function ($query) use ($bulanIni, $tahunIni) {
                    $query->where('status', '!=', 'LS')
                        ->where('bulan', $bulanIni) // Periksa bulan tagihan
                        ->where('tahun', $tahunIni); // Periksa tahun tagihan
                });
            })->get();

        return view('tagihan.belumLunas', compact('pelangganBelumLunas'));
    }

    public function deleteTagihan($id)
    {
        // Temukan tagihan berdasarkan ID
        $tagihan = Tagihan::find($id);

        // Cek apakah tagihan ditemukan
        if (!$tagihan) {
            Alert::error('Error', 'Tagihan tidak ditemukan');
            return redirect()->route('buka-tagihan');
        }

        // Simpan bulan dan tahun sebelum dihapus
        $bulan = $tagihan->bulan;
        $tahun = $tagihan->tahun;

        // Hapus tagihan
        $tagihan->delete();

        Alert::success('Sukses', 'Tagihan berhasil dihapus');
        
        // Redirect kembali ke buka-tagihan dengan parameter bulan dan tahun
        return redirect()->route('buka-tagihan', [
            'bulan' => $bulan,
            'tahun' => $tahun
        ]);
    }

}

