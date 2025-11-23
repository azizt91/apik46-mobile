<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Paket;
use App\Models\Pelanggan;
use App\Models\Dashboard;
use RealRashid\SweetAlert\Facades\Alert;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Hash;

use Carbon\Carbon;


class PelangganController extends Controller
{

	public function index()
	{
        $pelanggan = Pelanggan::with('paket')->paginate(1000);
        return view('pelanggan.index', compact('pelanggan'));

	}

	public function aktif()
	{
		$pelanggan = Pelanggan::where('status', 'aktif')->get();
		return view('pelanggan.aktif', compact('pelanggan'));
	}

	public function nonaktif()
	{
		$pelanggan = Pelanggan::where('status', 'nonaktif')->get();
		return view('pelanggan.nonaktif', compact('pelanggan'));
	}

	public function tambah()
	{
		$paket = Paket::get();
		$status = ['aktif', 'nonaktif'];
		return view('pelanggan.form', compact('paket', 'status'));
	}

	public function simpan(Request $request)
	{

		$pass_acak = Str::random(8);

		$data = [
			'id_pelanggan' => $request->id_pelanggan,
			'nama' => $request->nama,
			'alamat' => $request->alamat,
			'whatsapp' => $request->whatsapp,
			'email' => $request->email,
			'password' => $pass_acak,
			'password_hash' => Hash::make($pass_acak),
			'level' => 'User',
			'id_paket' => $request->id_paket,
			'ip_address' => $request->ip_address,
			'status' => $request->status,

		];

		Pelanggan::create($data);
		Alert::toast('Data berhasil disimpan','success');
		return redirect()->route('pelanggan');
	}

	public function edit($id)
	{
		$pelanggan = Pelanggan::find($id);
		$paket = Paket::get();
		$status = ['aktif', 'nonaktif'];
		return view('pelanggan.form', compact('pelanggan', 'paket', 'status'));
	}

	public function update($id, Request $request)
	{
		$data = [
			'id_pelanggan' => $request->id_pelanggan,
			'nama' => $request->nama,
			'alamat' => $request->alamat,
			'whatsapp' => $request->whatsapp,
			'email' => $request->email,
			'id_paket' => $request->id_paket,
			'ip_address' => $request->ip_address,
			'status' => $request->status,
		];

		Pelanggan::find($id)->update($data);
		Alert::toast('Data berhasil diedit', 'success');
		return redirect()->route('pelanggan');
	}


// 	public function hapus($id_pelanggan)
// 	{

// 		$pelanggan = Pelanggan::find($id_pelanggan);

// 		if ($pelanggan) {
// 			$pelanggan->delete();
// 			Alert::toast('Data Berhasil Dihapus','success');
// 		} else {
// 			Alert::toast('Data Berhasil Dihapus','success');
// 		}

// 		return redirect()->route('pelanggan');
// 	}

    public function hapus($id)
    {
        $pelanggan = Pelanggan::find($id);
    
        if ($pelanggan) {
            // Hapus data yang terkait di tabel tagihan
            foreach ($pelanggan->tagihan as $tagihan) {
                $tagihan->delete();
            }
    
            // Hapus data pelanggan
            $pelanggan->delete();
            Alert::toast('Data Berhasil Dihapus','success');
        } else {
            Alert::toast('Data tidak ditemukan','error');
    }

    return redirect()->route('pelanggan');
}



	public function showDashboard()
	{
		$jumlah_pelanggan = Pelanggan::count();
		return view('dashboard', compact('jumlah_pelanggan'));
	}

	public function show($id)
	{
		$pelanggan = Pelanggan::findOrFail($id);
		$tagihanBelumLunas = $pelanggan->tagihan()->where('status', 'BL')->get();

		return view('pelanggan.detail', compact('pelanggan', 'tagihanBelumLunas'));
	}

	public function profile($id)
	{
		$pelanggan = Pelanggan::findOrFail($id);
		return view ('pelanggan.profile', compact('pelanggan'));
	}



}




    


