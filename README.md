<div align="center">
  <img src="/assets/banner.png">
  <p><b>v1.0.4</b></p>
  <br><br>
  <P><b>A tool to make your screenshots look better</b></p>
</div>

## Suggestion
> - Edit wm in file xshot.sh line 
> - Can be used on Android 12+ but not yet perfected
> - Using the [**F-droid**](https://f-droid.org/en/packages/com.termux/) version of termux
> - Use a third party app to capture the screen. Example: [**screen master**](https://play.google.com/store/apps/details?id=pro.capture.screenshot)

## Instalation For Termux
```
pkg install && pkg update
pkg install git
pkg install imagemagick -y
pkg install inotify-tools
pkg install bc
pkg install nano 
termux-setup-storage
git clone https://github.com/AzRyCb/xshot
cd xshot
bash install.sh
```

## RUN
```
bash xshot.sh
```
## Note
Setelah melakukan command diatas kalian tinggal pilih option sesuai selera contoh:
```
bash xshot.sh -a -d
```
yang berarti menjalankan file xshot.sh dengan option -a (otomatis)  dan -d (warna background hitam) 

jika saat memulai proses 'waiting new file' lalu exit proses coba lakukan restart termux atau pastikan package inotify-tools benar2 telah terinstall
dengan memakai command
```
pkg install inotify-tools
```
