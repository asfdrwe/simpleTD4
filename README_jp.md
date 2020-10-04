# simpleTD4 
Verilogで実装したシンプルな4bit CPU TD4の実装です。 
[Sipeed Tang Nano] (https://tangnano.sipeed.com/en/) でも動作します。
[TD4\_details\_jp.md](TD4_details_jp.md) でコードの解説をしています。

## ライセンス
  ```
Copyright (c) 2020 asfdrwe <asfdrwe@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy 
of this software and associated documentation files (the "Software"), to deal 
in the Software without restriction, including without limitation the rights 
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
IN THE SOFTWARE.
  ```

## 必要なもの
### PCでシミュレーションする場合
- [iverlog](http://iverilog.icarus.com/)
	- [iverlog Windows版](http://bleyer.org/icarus/)
- [gtkwave](http://gtkwave.sourceforge.net/) (なくてもいい)  

Linuxで動作確認しています。iverlogもgtkwaveもLinuxなら大抵のディストリビューションでバイナリが用意されていると思います。

### FPGAを使う場合
- [Sipeed Tang Nano] (https://tangnano.sipeed.com/en/)  
(以下なくてもいい)
	- [ブレッドボード] (https://akizukidenshi.com/catalog/g/gP-05294/)
	- [抵抗内蔵５ｍｍ赤色ＬＥＤ] (https://akizukidenshi.com/catalog/g/gI-06245/) 4個
	- [タクトスイッチ] (https://akizukidenshi.com/catalog/g/gP-03647/) 4個
	- [圧電スピーカー] (https://akizukidenshi.com/catalog/g/gP-04118/) 1個
	- [スルホール用テストワイヤ] (https://akizukidenshi.com/catalog/g/gC-09830/) 10本
	- [ジャンプワイヤ] (https://akizukidenshi.com/catalog/g/gC-05371/) 5本  
	ハンダ付けなしでも動作確認できるようにスルホール用テストワイヤを活用しています。もちろん普通にピンヘッダをハンダ付けしても動きます。

## PCでのシミュレーション
### 論理合成
   ```
iverlog -o TD4 TD4.v TD4_test.v
   ```

### シミュレーション実行
   ```
./TD4
   ```

gtkwaveで信号状態の確認もできます。./TD4実行後に
   ```
gtkwave TD4.vcd
   ```

### ROM.binの書き方
ROM.binを差し替えることで動作が変わります。
1行8bitの2進数で記述してください。\_は区切りで無視されます。 // 以下はコメントです。 ROMLED.bin、ROMRAMEM.bin、ROMINOUT.binを参考にしてください。

## Tang Nanoでの実行
[Sipeed Tang Nanoで遊んでみる (Linux版)] (https://qiita.com/ciniml/items/bb9723673c91d8374b63) や
 [SiPeed Tang Nanoの環境構築(Windows編)] (https://qiita.com/tomorrow56/items/7e3508ef43d3d11fefab) 
 を参考に環境設定を行ってTang Nanoの動作確認をしてください。nano\_simpleならば
Open Projectからnano\_simple/TD4_nano1.gprjを開き、
Processから Synthesize => Place & Route => Program Deviceで書き込みしてください。
Synthesizeできない場合はTD4.vを開いて適当に改行を入れて保存してからSynthesizeしてください。

### ROM.binの書き方
Tang Nano向けでは、\_や//　があるとうまく動かない可能性があるので1行8bitの2進数だけで記述してください。

## ファイル
- TD4.v  
iverilog用のVerilogで実装したTD4本体です。
- TD4_test.v  
iverilog用のTD4のテストベンチです。

- ROM.bin
TD4が読み込むプログラムです。
ROMLED.bin、ROMRAMEM.bin、ROMINOUT.binのファイル名を変えるか自作のコードをROM.binにしてください。
- ROMLED.bin  
TD4のLED点滅プログラム(外部出力)です。  
0011, 0110, 1100, 1000, 1000, 1100, 0110, 0011, 0001の順に繰り返します。
- ROMRAMEM.bin  
TD4のラーメンタイマープログラムです。  
0111のあと少し経つと0110になりそのあと0000と0100を繰り返し最後1000になります。
1サイクル1秒にすれば3分後1000になるはずです。
- ROMINOUT.bin  
TD4の入力と出力のテストプログラムです。
入力内容をBレジスタに入れBレジスタの内容を出力します。

- README\_jp.md  
この文書です。
- TD4\_details\_jp.md  
simpleTD4の実装の解説です。
- README.md
英語版の文書です。

- TD4withComment.v  
コメント付きのsimpleTD4の実装です。


### FPGA用
- nano\_simple  
Tang Nanoのみで動作します。USB端子を右とした場合、上のボタンがリセット、
TD4の出力ポートのうち下位3bitをTang Nano内蔵LEDの青、緑、赤に割り振り、
TD4の入力ポートの最下位ビットが下のボタンです。
それ以外は、出力ポートの最上位は38番(左下)、入力ポートの残りは下位から40番41番42番(左下の3番目から5番目)です。

	Tang Nanoのピンアサインは [Tang Nano](https://tangnano.sipeed.com/en/) の 
[Pinout Diagram](https://tangnano.sipeed.com/assets/tang_nano_pinout_v1.0.0_w5676_h4000_large.png) を参照してください。

- nano\_breadboard  
ブレッドボードと組み合わせて動作します。USB端子を右とした場合、上のボタンがリセット、
TD4の出力ポートが上位から38番39番40番41番(左下1番目から4番目)、最上位ビットの
ブザー出力が23番(右上のスイッチから5番目)、TDの入力ポートが上位から
20番21番22番24番(右上のスイッチから10番目から7番目)です。  
![雑な配線例] (images/tangnano.png) 。

- nano\_uart
PCにUSB UART経由でTD4の内部状態を出力しながら動作します。
ピンアサインはnano\_simpleと同じです。
出力形式は  
pc opcode reg_a,reg_b,reg_out,reg_in cflag|load_a,load_b,load_out,load_pc|nextcflag|alu_out  

	Tang NanoはUARTの信号線と書き込み用の信号線が重複しています。  
	Linuxではftdi\_sioが動いていると書き込みができず、ftdi\_sioが動いていないとUARTでの通信ができないので、rmmodとmodprobeをうまく使ってください。cuコマンドを使う場合/dev/ttyUSB0としてTang Nanoが認識されているなら
  ```
cu -l /dev/ttyUSB0 -s 57600
  ```

Windowsの場合は
[Tang NanoでuartのIPコアを動かした件](https://qiita.com/yoshiki9636/items/cabcd0c62ea97472b51c)
が参考になると思います。なおこのページのコードをnano_uartの実装の参考にしています。


