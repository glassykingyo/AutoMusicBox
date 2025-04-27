# Automusicbox
从八音盒或纯钢琴音乐mp3中扒谱，自动生成30音八音盒乐谱。  
Turn music box or piano MP3s into melodies that can be played on a 30-note music box.  
matlab2019版本及以上，依赖signal processing toolbox。  
## 使用样例   
```matlab
AutoMusicBox('D:\yourpath\cobweb.mp3','D:\yourpath\cobweb\','HideMiddle',0,'noteWinSize',[5,5]);
```
其中cobweb.mp3为截取自https://b23.tv/2tSmNyF 的一段纯八音盒音乐，原曲为Sasakure.UK的蜘蛛糸モノポリー。  
由于歌曲节奏较快，于是将noteWinSize参数的时间轴缩小（10→5）。由于低音部分较低且音高接近的音符较多，将noteWinSize的频率轴增大（3→5）。   

运行中途，生成如下图片。这是得到的完整乐谱。   
![scorefull](https://github.com/user-attachments/assets/1c9c9d56-3b73-4e76-8174-dc9ab084728c)
并在命令行弹出待输入问句： 
```matlab
What part of the score do you want to keep? [start, end](column idx)  
```
输入[1,104]，表示只需要1-104列的音符。
最终得到可直接复刻到纸带上使用的乐谱（png与pdf）：   
![score](https://github.com/user-attachments/assets/f1521807-d95a-4a6d-9411-b41df988ccf1)
## 中途输出图片
音符识别可能出错，尤其是在扒谱BPM不同的曲子时，往往需要调整参数。最好在初次识别时设置'HideMiddle'=0，输出处理中途的时频图，与生成的谱面对照。
### baseTFA.png： 
![baseTFA](https://github.com/user-attachments/assets/87bfa716-9687-4c44-80e4-b89e6e569802)
时间-频率-振幅。横向白线代表采样为音符的频率。  
可观察音符分布诸如低音高音比例、大致BPM、音符间互相影响的程度，来决定noteWinSize、up/downSampRange、TimeRange等采样参数及STFT参数。  
### data.png：  
![data](https://github.com/user-attachments/assets/419a3b3b-e7ad-434f-a125-b1a548f05558)
时间-音符-振幅。自baseTFA选取划白色横线的行。
每一行都将当作独立的音符来分析，应在这一步确定noteWinSize的纵向大小以避免音符间相互影响。
### dataMax.png： 
![dataMax](https://github.com/user-attachments/assets/2cff173c-11a4-4f47-8b0b-2030abb45f20)
时间-音符-振幅。data.png运行过noteWin滑窗（每窗内仅保留最大值）后的结果。白色纵向线表示节拍位置。
仅在节拍位置附近的音会被采纳。
