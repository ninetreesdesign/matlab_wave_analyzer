%%
% _v3 7/6/2018
%find all .wav files
% all files are in this directory
% - add increment figure (page) after each n files
% - printformat the output vars
% - export to pdf
% _v3a 7/9/2018
% - added normalize option
% - added sequential output file names
% - write to output subfolder
% - todo: work out seconds (figure bytes to samples 16bit?)
clear
close all;

location = pwd;
thepath = location;      % auto selects script path
% USER INPUT ------------------------------------------------------
%thepath = 'C:\Users\dsmith\Dropbox\resources_engr\matlab\';

thesubfolder = ''; %'zzz_temp\';
theoutfolder = '\out1\';
out_sample_rate = 44100;
rows_per_page = 4;
report_prefix = 'waves_2018_07_09';  % for pdf out
rename_prefix = 'wave_eff';
renumber_start = 100; % + i
normalize_flag = 0;
%------------------------------------------------------------------
if normalize_flag == 1
    report_prefix = strcat(report_prefix,'_N');
    rename_prefix = strcat(rename_prefix,'_N');
end

% get list of names
full_filename = fullfile(thepath,thesubfolder,'*.wav');
wav_file_list = dir(full_filename);  % this builds an array of structs
% how many files
num_files = length(wav_file_list);
num_pages = round(num_files/rows_per_page);
%%
% wav_data: read in data to matrix
% wav_attributes: use cell array to hold attributes as text strings

% name 8.3  size SR   max  min  mean date
% 1    2    3    4    5    6    7    8
wav_attrib_headings = { 'name' 'size' 'SR  ' 'max ' 'min ' 'mean' 'date' };

for k = 1:num_files
    %     wav file parameters 1=name 2=folder 3=date 4=bytes 5=isdir 6=datenum
    wav_attributes(k,1) = { wav_file_list(k).name };
    % todo: rename file %wav_attributes(k,1) = strrep({ wav_file_list(k).name },' ','_');    % convert spaces to underscores
    wav_attributes(k,2) = { wav_file_list(k).date };
    wav_attributes(k,3) = { wav_file_list(k).bytes };
    %s_char = char(wav_attributes(k,1));
    [w_data, file_sample_rate] = audioread(char(wav_attributes(k,1))); % convert filename to a character array
    wav_attributes(k,4) =  { file_sample_rate };    % store sample rate
    % option to normalize
    if normalize_flag == 1
        mx = max(w_data);
        mn = min(w_data);
        
        % wav_norm = (w_data -mn)/(mx - mn);  % scales all to 0 - 1, regardless; moves '0' to 0.5
        
        scale = abs(mx);    % find peak, if mn < -1, it will clip (ignore these cases)
        wav_norm = w_data/scale * 0.999;
        
        w_data = wav_norm ; % overwrite original var
    end
    num_secs = 2;
    Lmax = 44100 * num_secs;
    %Lmax = 44100/50;    %// zoom in to beginning
    L = length(w_data);
    if L > Lmax
        L = Lmax;
    end
    % at hi-res, only show the first 1 sec of data
    % note: this builds a *large* array
    wav_data(k,1:L) = single(w_data(1:L));  % reduce amt of data to single precision
    d = sort(wav_data(k,1:L),'descend');
    wav_attributes(k,5) = { mean(d(1:400)*1.00001) }; % avg of max of 400 highest
    d = sort(d); % ascend
    wav_attributes(k,6) = { mean(d(1:400))*0.99999}; % avg of min
    wav_attributes(k,7) = { mean(d)*1.00001};   % mean
    % (D,[k wav_attributes(k,3) wav_attributes(k,4) max(d) min(d)])
    
    % convert numbers to text strings and put in cell array to print
    %x = wav_attributes(k,1); s = sprintf('%04.2f',x);
    %wav_attrib_str(k,1) = strcat(num2str(k),s);
    wav_attrib_str(k,1) = wav_attributes(k,1);
    wav_attrib_str(k,8) = wav_attributes(k,2);  % date
    
    wav_attrib_str(k,3) = wav_attributes(k,3);
   % x = wav_attributes{k,3}/2 / file_sample_rate; % sec
  % wav_attrib_str{k,3} = strcat(num2str(sprintf('%8.1f',wav_attrib_str{k,3}/1000/2)),' ks ',num2str(sprintf(' [%6.2f sec]',x)));
   wav_attrib_str{k,3} = strcat(num2str(sprintf('%8.1f',wav_attrib_str{k,3}/1000)),' kB '); 
   
    wav_attrib_str(k,4) = wav_attributes(k,4);
    wav_attrib_str{k,4} = strcat(num2str(sprintf('%5.1f',wav_attrib_str{k,4}/1000) ),' kHz');
    
    wav_attrib_str(k,5) = wav_attributes(k,5);
    wav_attrib_str{k,5} = strcat(num2str(sprintf('%6.2f',wav_attrib_str{k,5}/1.0) ),' max');
    
    wav_attrib_str(k,6) = wav_attributes(k,6);
    wav_attrib_str{k,6} = strcat(num2str(sprintf('%6.2f',wav_attrib_str{k,6}/1.0) ),' min');
    
    wav_attrib_str(k,7) = wav_attributes(k,7);
    wav_attrib_str{k,7} = strcat(num2str(sprintf('%6.2f',wav_attrib_str{k,7}/1.0) ),' avg');
    
    % re-write as sequential filenames with same sample rate
    k_str = sprintf('%03d',k);
    fn = strcat(rename_prefix,'_',k_str,'.wav');
    wav_attrib_str(k,2) = { fn };
    out_filename = fullfile(thepath,theoutfolder,fn);
    audiowrite(out_filename,w_data,out_sample_rate);
end


%% make plots
% create a page with each file documented with summary data, wav data & fft

% graph dimensions
n_rows = rows_per_page; % num_files;
n_cols = 3;
pos_g1 = 2;     % this is the current position for first graph in subplot


pos_x = 0.1;
pos_y = 0.5;
%figure printing
close all;  % close all figure windows
ymax = 1.2; ymin = -ymax;   % range for data graphs

pos_g1 = 2;
pg = 1;
j = 1;  % use for page index
for k = 1:num_files
    % separate into multiple figures (pages)
    % plot of data: rows: text, data graph, analysis graph
    
    figure_number = 0 + pg;
    hF = figure(figure_number);
    set(hF, 'color', [1 1 1]);
    %hF.PaperUnits = 'inches';
    set(hF, 'position', [100+pg*20, 100, 800, 900])  % create new figure with specified size
    i_str = sprintf('file[%02d]: ',k);
    
    % for debug  ss = sprintf('i:%02d: j:%d   %d %d   %02d %02d %02d  "%s"',k,j,n_rows,n_cols,pos_g1-1,pos_g1,pos_g1+1, char(wav_attrib_str(k,1)) ); disp(ss);
    
    % COL 1: place file description text in leftmost column
    subplot(n_rows, n_cols, pos_g1-1);
    set(gca, 'visible', 'off');      % get current axes
    text(pos_x, pos_y, wav_attrib_str(k,:), 'FontName','Arial Narrow', 'FontSize',10, 'Interpreter', 'none');   % turn off Latex parsing '_'
    
    % COL 2
       L = length(wav_data(k,:));
    if L > Lmax
        L = Lmax;
    end
    
    subplot(n_rows, n_cols, pos_g1);
    plot(1:L, wav_data(k,1:L));
    axis([0 L ymin ymax ]);    % graph x limit to ...
    title( char(wav_attrib_str(k,1)) ,'FontSize',10, 'Interpreter', 'none' ); % title(num2str(pos_g1));
    %     [up,lo] = envelope(wav_data(1:L,i));%,2000,'analytic');  % 300+ is very smoothed Hilbert filter
    %     hold on;     %     plot(1:L,up,'-',1:L,lo,'--')    %     hold off;
    
    % COL 3
    T = 1/file_sample_rate;             % Sampling period
    L = file_sample_rate;
    Y = fft(wav_data(k,1:L),4*L); % 4*L for better fft res? ds
    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = file_sample_rate*(0:(L/2))/L;
    upper_freq = 500;
    subplot(n_rows, n_cols, pos_g1+1);
    plot(f,P1 , 'Color',[230/255,92/255,0/255] );
    title('Spectrum' ,'FontSize',10, 'Interpreter', 'none');
    xlabel('f (Hz)');
    % ylabel('|P1(f)|');
    axis([0 upper_freq 0.01-0.001 1.0]); %inf]);  % values to 400Hz, log scaling  to 1:100 max amplitude
    set(gca, 'YScale', 'log');
    grid on;
    
    j = j + 1;
    if j == rows_per_page + 1
        pg = pg + 1;    % increment page num
        pos_g1 = 2;     % reset first graph loc in subplot grid
        j = 1;          % reset rows counter
    else
        pos_g1 = j * n_cols -1; % 2 5 8 11...
    end
    
end

%%
% Save to pdf
scale=1;
paperunits='inches';
fileheight = 11;    %inches
filewidth=8.5;      %inches
filetype='pdf';
res=300;    %resolution
size=[filewidth fileheight]*scale;
set(gcf,'paperunits',paperunits,'paperposition',[0.02 0.02 size]);
set(gcf, 'PaperSize', size);

for k = 1 : num_pages
    str = sprintf('%s_%02d',report_prefix,k);
    fn = char(str);     % char() converts a string Scalar to string Vector
    out_filename = fullfile(thepath,theoutfolder,fn);
    
    saveas(gcf,out_filename,filetype);   % automatically adds extension
end

% todo: join pdfs
% command = 'gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=out.pdf in1.pdf in2.pdf';
% [status,cmdout] = system(command)

