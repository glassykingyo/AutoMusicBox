function [scorenew,score] = AutoMusicBox(filename,savedir,varargin)
%AutoMusicBox: https://github.com/glassykingyo/AutoMusicBox for details
%Input: 
%   filename: str, dir and filename of the mp3 file
%   savedir: str, dir to output image file, end with '\'
%   option:
%   about mp3 file: 
%       TimeRange: [min, max](s), start and end of the target music
%       segment, select entire file by default
%       SoundTrack: 1 means left, 2 means right, 'all' means average of
%       both, default is 'all'
%   about STFT:
%       hannwindow: double, length of hamming window, default is 2048 
%       noverlap: double, Number of overlapped samples, default is 1024
%       nfft: double, Number of DFT points, default is 4096
%   about note sample:
%       noteWinSize: [x,y], Size of sliding window to sample note from 
%       Time-frequency graph,default is 10*3
%       downSampRange: double, The distance in semitones from the lowest 
%       sampled note to middle A (A4), default is 33 (C1);
%       upSampRange: double, The distance in semitones from the highest 
%       sampled note to middle A (A4), default is 69 (F#9);
%       ScoreTimeRange: [start, end](column idx), the part of the score to 
%       keep, only work when ifAsk==0.
%   about BPM
%       artiLag: double, manual shifting of the automatically identified 
%       beat positions, default is 0. 
%       artiScal: double, manual scaling of the intervals between 
%       automatically detected beats, default is 0.
%       beatRange: double, range of sampling centered at each detected
%       beat, must smaller than beat interval, default is 5.
%   about image output:
%       HideMiddle: if export middle image. 1 means not export, 0 means export,
%       default is 1
%       ifAsk: double, Whether to prompt for a time range after generating 
%       the full score. 1 means ask, 0 means don't, default is 1
%Output:
%   scorenew: Matrix representation of the music box score: pitch × time,
%   with 1 indicating a note is present.
%   score: Matrix representation of the full score.


% para
p = inputParser;
%file
addParameter(p, 'TimeRange', 'all');
addParameter(p, 'SoundTrack', 1);
%STFT
addParameter(p, 'hannwindow', 2048);
addParameter(p, 'noverlap' , 1024);
addParameter(p, 'nfft' , 4096);
%sample
addParameter(p, 'noteWinSize', [10,3]);
addParameter(p, 'downSampRange', 33);
addParameter(p, 'upSampRange', 69);
addParameter(p, 'ScoreTimeRange', 'all');
%BPM
addParameter(p, 'artiLag', 0);
addParameter(p, 'artiScal', 0);
addParameter(p, 'beatRange', 5);
%image output
addParameter(p, 'HideMiddle' , 1);
addParameter(p, 'ifAsk' , 1);

parse(p, varargin{:});
opts = p.Results;

% STFT
try
    [audio, fs] = audioread(filename);  % audio 是列向量或矩阵，fs 是采样率
catch
    error('Could not find the MP3 file. Filename might not exist')
end

if all(opts.SoundTrack=='all')
    audio = mean(audio,2);
elseif isscalar(opts.SoundTrack) && isa(opts.SoundTrack,'double')
    if isa(opts.TimeRange,'char') || isa(opts.TimeRange,'string')
        if all(opts.TimeRange=='all')
            audio = audio(:,opts.SoundTrack);
        else
            error('Invalid input format: TimeRange')
        end
    elseif isa(opts.TimeRange,'double')
        try
            audio = audio(floor(fs*opts.TimeRange(1)):floor(fs*opts.TimeRange(2)),opts.SoundTrack); 
        catch
            error('Time Range exceed the length of the MP3 file.')
        end
    else
        error('Invalid input format: TimeRange')
    end
else
    error('Invalid input format: SoundTrack')
end

window = hann(opts.hannwindow);
[S, F, T] = stft(audio, fs, 'Window', window, 'OverlapLength', opts.noverlap, 'FFTLength', opts.nfft);
amplitude = abs(S);  % size length(F) × length(T)

choseFidx = F>20 & F<4000;

figure
set(gcf,'Position',[ 6         325        1909         553])
imagesc(T, F(choseFidx),amplitude(choseFidx,:));
xline(440,'LineWidth',10)

% freq-note sheet
A4 = 440;
freqbox = zeros(1,opts.downSampRange+opts.upSampRange+1);
namebox = cell(1,73);
charabox = {'A','A#','B','C','C#','D','D#','E','F','F#','G','G#'}; 
cycleN = 3;
cycleI = 12;
for i = 1:opts.downSampRange
   freqbox(opts.downSampRange+1-i) =  A4/(2^(i/12));
   namebox{opts.downSampRange+1-i} = [charabox{cycleI},num2str(cycleN)];
   cycleI = cycleI-1;
   if cycleI==0
       cycleN = cycleN-1;
       cycleI = 12;
   end
end
freqbox(opts.downSampRange+1) = A4;
namebox{opts.downSampRange+1} = 'A4';
cycleN = 4;
cycleI = 2;
for i = 1:opts.upSampRange
   freqbox(opts.downSampRange+1+i) =  A4*(2^(i/12));
   namebox{opts.downSampRange+1+i} = [charabox{cycleI},num2str(cycleN)];
   cycleI = cycleI+1;
   if cycleI==13
       cycleN = cycleN+1;
       cycleI = 1;
   end
end

hold on
databefore = zeros(length(freqbox),width(amplitude));

for i = 1:length(freqbox)
    plot(0:30,freqbox(i)*ones(1,31),'color',[1,1,1],'Linewidth',0.1)
    [~, idx] = min(abs(F - freqbox(i)));
    databefore(i,:) = amplitude(idx,:);
end

if ~logical(opts.HideMiddle)
    try
        saveas(gcf,[savedir,'baseTFA.fig'])
        saveas(gcf,[savedir,'baseTFA.png'])
    catch
        error('Fail to save image file. Savedir might not exist.')
    end
end

clf
imagesc(databefore)
if ~logical(opts.HideMiddle)
    try
        saveas(gcf,[savedir,'data.fig'])
        saveas(gcf,[savedir,'data.png'])
    catch
        error('Fail to save image file. Savedir might not exist.')
    end
end

% clean data
globalmax = max(databefore,[],'all');

dataaver = zeros(size(databefore));
peakdistance = opts.noteWinSize(1);
for row = 1:height(databefore)
    temp = smooth(databefore(row,:),3)';
    if all(temp<0.1*globalmax)
        continue
    end
    dtemp = [0,diff(temp)];
    [peaks, locs] = findpeaks(dtemp, ...
        'MinPeakHeight', 0.2*max(dtemp), ...
        'MinPeakDistance', peakdistance);
    for i = 1:length(locs)
        peakzone = locs(i)-floor(peakdistance/2):locs(i)+floor(peakdistance/2);
        peakzone(peakzone<=0) = [];
        [maxnum,maxloc] = max(temp(peakzone));
        dataaver(row,locs(i)+maxloc-1) = maxnum;
    end
end

dataclean = dataaver;  
for col = 1:(size(dataaver, 2)-opts.noteWinSize(1)+1)
    for row = 1:(size(dataaver, 1)-opts.noteWinSize(2)+1)
        temp = dataclean(row:(row+opts.noteWinSize(2)-1),col:(col+opts.noteWinSize(1)-1));
        tempmax = max(temp,[],'all');
        temp(temp~=tempmax) = 0;
        dataclean(row:(row+opts.noteWinSize(2)-1),col:(col+opts.noteWinSize(1)-1)) = temp;
    end
end

clf
imagesc(dataclean)


% determined BPM
rhythmbefore = sum(dataclean,1);
[pks, locs] = findpeaks(rhythmbefore, ...
    'MinPeakHeight',0.1*globalmax,'MinPeakDistance',floor(peakdistance/2));
dists = diff(locs);
outliers = isoutlier(dists, 'quartiles');
dists(outliers) = [];
GMModel = fitgmdist(dists', 1);

if ~isa(opts.artiScal,'double')
    error('Invalid input format: artiScal')
end
beat = GMModel.mu+artiScal;

if ~isa(opts.artiLag,'double')
    error('Invalid input format: artiLag')
end

start = locs(1)+opts.artiLag;
for col = 1:ceil(width(dataclean)/beat)
    xline(start+(col-1)*beat,'Color',[1,1,1])
end

if ~logical(opts.HideMiddle)
    try
        saveas(gcf,[savedir,'dataMax.fig'])
        saveas(gcf,[savedir,'dataMax.png'])
    catch
        error('Fail to save image file. Savedir might not exist.')
    end
end

% make music score
if ~isa(opts.beatRange,'double')
    error('Invalid input format: beatRange')
elseif opts.beatRange>beat
    error('beatRange must be smaller than beat interval')
end
score = zeros(height(dataclean),ceil(width(dataclean)/beat));
for row = 1:height(dataclean)
    temp = dataclean(row,:);
    for col = 1:ceil(width(dataclean)/beat)
        windowidx = floor(start+(col-1)*beat-opts.beatRange/2):ceil(start+(col)*beat-opts.beatRange/2);
        windowidx(windowidx<=0|windowidx>width(dataclean)) = [];
        if isempty(windowidx)
            continue
        end
        score(row,col) = max(temp(windowidx));
    end
end

% remove empty track
idxnull = find(all(score==0,2));
d = diff(idxnull);
splitPoints = [0; find(d > 1); length(idxnull)];

blocks = {};
for i = 1:length(splitPoints)-1
    startIdx = splitPoints(i)+1;
    endIdx = splitPoints(i+1);
    blocks{end+1} = idxnull(startIdx:endIdx);
end

idxnull = [blocks{1}; blocks{end}];
names = namebox;
names(idxnull) = [];
score(idxnull,:) = [];

% clean 
for y = 1:height(score)
    for x = 1:width(score)-1
        temp = score(y,x:x+1);
        if (max(temp)-min(temp))/sum(temp)>0.1
            temp(temp==min(temp)) = 0;
            score(y,x:x+1) = temp;
        end
    end
end
score(score~=0) = 1;
printscore(score,names,[savedir,'scorefull'])

% score to box score
namenew = namebox(find(strcmp(namebox, 'C1')):find(strcmp(namebox, 'E4')));
H = height(score)-41;
if H > 0
    for y = 1:H
        for x = 1:width(score)
            if score(y,x)~=0 && score(y+12,x)==0
                score(y+12,x) = 1;
            end
        end
    end
    score = score(H+1:end,:);
end

if logical(opts.ifAsk)
    samprange = input('What part of the score do you want to keep? [start, end](column idx)');
    samprange = samprange(1):samprange(2);
else
    if isa(opts.ScoreTimeRange,'char') || isa(opts.ScoreTimeRange,'string')
        if all(opts.ScoreTimeRange=='all')
            samprange = 1:width(score);
        else
            error('Invalid input format: ScoreTimeRange')
        end
    elseif isa(opts.ScoreTimeRange,'double') && length(opts.ScoreTimeRange)==2
        samprange = opts.ScoreTimeRange(1):opts.ScoreTimeRange(2);
    else
        error('Invalid input format: ScoreTimeRange')
    end
end
samprange(samprange<1 | samprange>width(score)) = [];

score = score(:,samprange);

idxnull = [2,4,5,6,7,9,11,14,16,38,40];
moveeff = zeros(1,42-height(score));
for movestep = 0:(41-height(score))
    idxnullmove = idxnull-movestep;
    idxnullmove(idxnullmove<=0 | idxnullmove>height(score)) = [];
    moveeff(movestep+1) = sum(score(idxnullmove,:),'all');
end
[~,movestep] = min(moveeff);
movestep = movestep-1;

namenew(idxnull) = [];
scorenew = zeros(41,width(score));
scorenew(movestep+(1:height(score)),:) = score;

for i = 1:length(idxnull)
    y = idxnull(i);

    for x = 1:width(score)
        if scorenew(y,x)~=0
            if y+12<=41
                if scorenew(y+12,x)==0
                    scorenew(y+12,x) = 1;
                end
            else
                if scorenew(y-12,x)==0
                end
            end
        end
    end
end
scorenew(idxnull,:) = [];
printscore(scorenew,namenew,[savedir,'score'])
end

% plot function
function [] = printscore(score,newname,FN) 
clf
hold on

idx = find(cellfun(@(x) contains(x, 'C') && ~contains(x, '#'), newname));
xline(1:4:width(score),'Color',[0,0,0])
yline(idx,'Color',[0,0,0])

[rows, cols] = find(score == 1);
scatter(cols,rows,'o','filled','MarkerEdgeColor','none','MarkerFaceColor',[0,0,0],'SizeData',80)
xlim([0,width(score)+1])
ylim([1,height(score)])

ax = gca;
ax.XGrid = 'on';
ax.YGrid = 'on';
ax.GridColor = [0.5 0.5 0.5];  
ax.GridAlpha = 0.5;           

xticks(1:size(score,2));
yticks(1:height(score)); 
yticklabels(newname); 

set(gca, 'Units', 'centimeters');
box on
daspect([1, 2, 1])

saveas(gcf,[FN,'.fig'])
saveas(gcf,[FN,'.png'])

exportgraphics(gcf, [FN,'.pdf'], 'ContentType', 'vector');
end
