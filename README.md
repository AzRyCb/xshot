<div align="center">
  <img src="/assets/banner.png">
  <p><b>v1.0.4</b></p>
  <br><br>
  <P><b>A tool to make your screenshots look better</b></p>
</div>

## Suggestion

> - Edit wm in file xshot.sh line 
> - This tools not support android 12+
> - Using the [**F-droid**](https://f-droid.org/en/packages/com.termux/) version of termux
> - Use a third party app to capture the screen. Example: [**screen master**](https://play.google.com/store/apps/details?id=pro.capture.screenshot)

## Instalation For Termux
```
pkg update && pkg upgrade
git clone https://github.com/AzRyCb/xshot
termux-setup-storage
cd xshot
pkg i imagemagick inotify-tools bc nano -y
bash install.sh
```

##RUN
```
bash xshot.sh
```
##Note
Setelah melakukan command diatas kalian tinggal pilih option sesuai selera contoh:
```
bash xshot.sh -a -d
```
yang berarti menjalankan file xshot.sh dengan option -a (otomatis)  dan -d (warna background hitam) 
