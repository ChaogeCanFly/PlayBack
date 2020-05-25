%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Microphones GUI V01            %
% Arkadiraf@gmail.con - 07/11/18 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%
%Notes: %

%{
/* Commands:
 * json:{"gain":0,"channel":0} // approximately 10ms to parse and send a response
 * json:{"threshOn":1000}
 * json:{"sigThresh":0.5} // range [0 - 1]
 * json:{"adcLatency":1000} // range [0 - (ADC_BUFFER_SIZE - 1)]
 * json:{"recordState":0} // debug state for sending recorded audio to PC [0,1]
 */

USB baud rate: 921600
Xbee baud rate: 115200
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Current serial callback uses global variavles as the gui object isn`t passed and the handles cannt be refreshed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = MicGUI_V01(varargin)
% MICGUI_V01 MATLAB code for MicGUI_V01.fig
%      MICGUI_V01, by itself, creates a new MICGUI_V01 or raises the existing
%      singleton*.
%
%      H = MICGUI_V01 returns the handle to a new MICGUI_V01 or the handle to
%      the existing singleton*.
%
%      MICGUI_V01('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MICGUI_V01.M with the given input arguments.
%
%      MICGUI_V01('Property','Value',...) creates a new MICGUI_V01 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MicGUI_V01_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MicGUI_V01_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MicGUI_V01

% Last Modified by GUIDE v2.5 22-Dec-2018 12:20:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @MicGUI_V01_OpeningFcn, ...
    'gui_OutputFcn',  @MicGUI_V01_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before MicGUI_V01 is made visible.
function MicGUI_V01_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MicGUI_V01 (see VARARGIN)
serialPorts = instrhwinfo('serial');
nPorts = length(serialPorts.SerialPorts);
if (nPorts>0)
    set(handles.Com_List, 'String', ...
        [{'Select Port'} ; serialPorts.SerialPorts ]);
    
    % start with first port if avilable
    set(handles.Com_List, 'Value', 2);
else
    set(handles.Com_List, 'String', ...
        {'No Ports'});
    set(handles.Com_List, 'Value', 1);
end

% declare variables to use in guide
jsonMic.mic = 0; % 0  is the golden mic - updates all mics - without ack
jsonMic.gain = 0;
jsonMic.channel = 0;
jsonMic.threshOn = 1000;
jsonMic.sigThresh = 0.5;
jsonMic.adcLatency = 1000;
jsonMic.recordState = 0;

%update handles
handles.jsonMic = jsonMic;
handles.conStatus = 0; % connection status variable

global myAppData
myAppData.RecordingState = 0;
myAppData.RecordingData = uint8('');
myAppData.PacketData = 0;
myAppData.PlotData = 0;
myAppData.IncomingBytes = 0;
myAppData.BufferIndex = 0;
% add jsonMic setting to global data.  simplifyes data transfer between
% functions which don`t update handles structure.
myAppData.jsonMic = jsonMic;
% update hangles
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes MicGUI_V01 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = MicGUI_V01_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in Connect_PushB.
function Connect_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to Connect_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmp(get(hObject,'String'),'Connect') % currently disconnected
    serPortn = get(handles.Com_List, 'Value');
    if serPortn == 1
        errordlg('Select valid COM port');
    else
        serList = get(handles.Com_List,'String');
        serPort = serList{serPortn};
        
        serConn = serial(serPort, 'TimeOut', 5, ...
            'BaudRate', str2double(get(handles.baudRateText, 'String')),...
            'BytesAvailableFcnMode','terminator',...
            'terminator','CR/LF');
        serConn.InputBufferSize = 102400;
        % try opening port
        try
            fopen(serConn);
            handles.serConn = serConn;
            
            % enable Send buttons
            handles.conStatus = 1;
            
            set(hObject, 'String','Disconnect')
        catch e
            errordlg(e.message);
        end
        % define a callback function
        % update guiddata
        guidata(hObject, handles);
        % add a callback function
        % pass the serial object to parse function, maybe there is a better approach ?
        %handles.serConn.BytesAvailableFcn = @(hObject, eventdata) Parse_Msg(hObject, eventdata, handles);
        set(handles.serConn, 'BytesAvailableFcn', {@Parse_Msg, handles }); % passing the handles to the serial object
        
        % send rest instructions
        % Reset_PushB_Callback(hObject, eventdata, handles)
    end
else
    % disable connection
    handles.conStatus=0;
    set(hObject, 'String','Connect')
    fclose(handles.serConn);
end

guidata(hObject, handles);


% --- Executes on selection change in Com_List.
function Com_List_Callback(hObject, eventdata, handles)
% hObject    handle to Com_List (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Com_List contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Com_List


% --- Executes during object creation, after setting all properties.
function Com_List_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Com_List (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Update_List_PushB.
function Update_List_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to Update_List_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% check if currently connect, if so disconect.
if strcmp(handles.Connect_PushB.String,'Disconnect') % currently conected
    set(handles.Connect_PushB, 'String','Connect')
    fclose(handles.serConn);
    
    % disable send buttons
    set(handles.Debug_PushB, 'Enable', 'Off');
    %    set(handles.Mic_Selec_BG, 'Enable', 'Off');
    
end
serialPorts = instrhwinfo('serial');
nPorts = length(serialPorts.SerialPorts);
if (nPorts>0)
    set(handles.Com_List, 'String', ...
        [{'Select Port'} ; serialPorts.SerialPorts ]);
    
    % start with first port if avilable
    set(handles.Com_List, 'Value', 2);
else
    set(handles.Com_List, 'String', ...
        {'No Ports'});
    set(handles.Com_List, 'Value', 1);
end
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);


function baudRateText_Callback(hObject, eventdata, handles)
% hObject    handle to baudRateText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of baudRateText as text
%        str2double(get(hObject,'String')) returns contents of baudRateText as a double


% --- Executes during object creation, after setting all properties.
function baudRateText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to baudRateText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% ------------------------------------------------------------------------------------------
% ------------------------------------------------------------------------------------------
% --- Parse_MSG
%function Parse_Msg(hObject, eventdata, handles,serConn) %pass the whole serial object... not sure its the best approach but works
function Parse_Msg(hObject, eventdata, handles) %pass the whole serial object... not sure its the best approach but works
global myAppData
serConn = handles.serConn;
%disp(handles.serConn);
%disp(serConn);
% try parse incoming data
try
    % check if state is for incoming binary packet A = fread(fileID,sizeA)
    %    disp(size(myAppData.RecordingData,2));
    %    disp(size(myAppData.IncomingBytes,2));
    %     if ((size(myAppData.RecordingData,2) <= myAppData.IncomingBytes) && (myAppData.RecordingState))
    %         RxText = fscanf(serConn);
    %         %disp(uint8(RxText));
    %         myAppData.RecordingData = [myAppData.RecordingData uint8(RxText)];
    %         disp(size(myAppData.RecordingData,2));
    %     else
    while (serConn.BytesAvailable)
        if  ((myAppData.RecordingState) && (myAppData.IncomingBytes))
            [RxText,bytesRead] = fread(serConn,myAppData.IncomingBytes);
            myAppData.IncomingBytes = myAppData.IncomingBytes - bytesRead;
            %disp(uint8(RxText));
            myAppData.RecordingData = [myAppData.RecordingData uint8(RxText)];
            %disp("read bytes");
            %disp(bytesRead);
            %disp(size(myAppData.RecordingData,1));
            %disp(size(myAppData.RecordingData,2));
            %disp(myAppData.IncomingBytes);
        else
            RxText = fscanf(serConn);
            %disp('msg');
            %disp(RxText);
            try
                jsonRecieved = jsondecode(RxText);
                disp('json Recieved');
                disp(jsonRecieved);
                if isfield(jsonRecieved,'Recording') %Start Recording
                    if (jsonRecieved.Recording == "Start")
                        %timeStamp
                        tic
                        myAppData.RecordingState = 1;
                        myAppData.BufferIndex = jsonRecieved.bufferIndex;
                        myAppData.IncomingBytes = jsonRecieved.Binary;
                        % reset buffer
                        myAppData.RecordingData = uint8('');
                        myAppData.PacketData = [];
                    elseif (jsonRecieved.Recording == "Packet") %another packet
                        myAppData.IncomingBytes = jsonRecieved.Binary;
                        %store previously arrived packet
                        recorded_data = myAppData.RecordingData;
                        % cast bytes into values
                        values = typecast(uint8(recorded_data(1:end)),'uint16');
                        if (max(values) > 4095) % failed transmission
                            values = values * 0;
                        end
                        myAppData.PacketData = [myAppData.PacketData values'];
                        % reset buffer
                        myAppData.RecordingData = uint8('');
                    elseif (jsonRecieved.Recording == "End")
                        %timeStamp
                        toc
                        myAppData.RecordingState = 0;
                        %store arrived packet
                        recorded_data = myAppData.RecordingData;
                        % cast bytes into values
                        values = typecast(uint8(recorded_data(1:end)),'uint16');
                        if (max(values) > 4095) % failed transmission
                            values = values * 0;
                        end
                        %this tag cost me several working hours.. damnn
                        %matrix
                        myAppData.PacketData = [myAppData.PacketData values'];
                        
%                         % update plot values (not arranged)
%                         myAppData.PlotData = [ myAppData.PlotData myAppData.PacketData];
%                         plot(handles.micRecord_axes,myAppData.PlotData);
%                         
%                         % add some zeros to seperate arrange and not
%                         % arranged data
%                         myAppData.PlotData = [ myAppData.PlotData (1:1000)*0];
%                         plot(handles.micRecord_axes,myAppData.PlotData);
                        
                        % rerrange buffer by buffer index
                        disp(myAppData.BufferIndex);
                        values_arranged = [myAppData.PacketData(myAppData.BufferIndex:end) myAppData.PacketData(1:(myAppData.BufferIndex-1))];
                        myAppData.PlotData = [ myAppData.PlotData values_arranged];
                        plot(handles.micRecord_axes,myAppData.PlotData);
                        %timeStamp
                        toc
                    end
                elseif isfield(jsonRecieved,'Ack') %Ack to sent command
                    set(handles.ComState_edit,'Backgroundcolor','g');
                    % check from what mic recived ack
                    switch (jsonRecieved.Mic)
                        case 1
                            set(handles.UpdateMic1_PushB,'Backgroundcolor','g');
                        case 2
                            set(handles.UpdateMic2_PushB,'Backgroundcolor','g');
                        case 3
                            set(handles.UpdateMic3_PushB,'Backgroundcolor','g');
                        case 4
                            set(handles.UpdateMic4_PushB,'Backgroundcolor','g');
                        case 5
                            set(handles.UpdateMic5_PushB,'Backgroundcolor','g');
                        case 10
                            set(handles.UpdateMic10_PushB,'Backgroundcolor','g');
                            
                        otherwise
                            disp('unspecified microphone value')
                            disp(jsonRecieved.Mic)
                    end
                elseif isfield(jsonRecieved,'Settings') %Recieved settings
                    set(handles.ComState_edit,'Backgroundcolor','g');
                    % check from what mic recived ack
                    switch (jsonRecieved.Settings)
                        case 1
                            set(handles.UpdateMic1_PushB,'Backgroundcolor','g');
                        case 2
                            set(handles.UpdateMic2_PushB,'Backgroundcolor','g');
                        case 3
                            set(handles.UpdateMic3_PushB,'Backgroundcolor','g');
                        case 4
                            set(handles.UpdateMic4_PushB,'Backgroundcolor','g');
                        case 5
                            set(handles.UpdateMic5_PushB,'Backgroundcolor','g');
                        case 10
                            set(handles.UpdateMic10_PushB,'Backgroundcolor','g');
                            
                        otherwise
                            disp('unspecified microphone value')
                            disp(jsonRecieved.Mic)
                    end

                    % retrive stored data
                    jsonMic = handles.jsonMic;
                    % update fields of the mic struct & update gui
                    jsonMic.mic = jsonRecieved.Settings;
                    if isfield(jsonRecieved,'gain')
                        jsonMic.gain = jsonRecieved.gain; 
                    end
                    if isfield(jsonRecieved,'channel')
                        jsonMic.channel = jsonRecieved.channel;
                    end
                    if isfield(jsonRecieved,'threshOn')
                        jsonMic.threshOn = jsonRecieved.threshOn;
                    end
                    if isfield(jsonRecieved,'sigThresh')
                        jsonMic.sigThresh = round((jsonRecieved.sigThresh-4094/2)/4095*2*100)/100;
                    end
                    if isfield(jsonRecieved,'adcLatency')
                        jsonMic.adcLatency = jsonRecieved.adcLatency;
                    end
                    if isfield(jsonRecieved,'recordState')
                        jsonMic.recordState = jsonRecieved.recordState;
                    end
                    
                    %update global variables
                    myAppData.jsonMic = jsonMic;
                    
                    %update GUI settings
                    UpdateGUI_Global(handles)
                end
                % display message
                time = clock;
                timeStr = [num2str(time(4)) ':' num2str(time(5)) ':' num2str(time(6)) ':'];
                set(handles.ReceiveBox_text, 'String',[timeStr '  ' RxText]);
            catch e
                %disp(e);
                disp('Not json: ');
                %display msg
                disp(RxText);
                time = clock;
                timeStr = [num2str(time(4)) ':' num2str(time(5)) ':' num2str(time(6)) ':'];
                set(handles.ReceiveBox_text, 'String',[timeStr '  ' 'Not json: ' RxText]);
            end
        end
    end
catch e
    disp(e);
    disp('msg not available');
end
%guidata(hObject, handles);
% Update handles structure
%guidata(hObject, handles);
% ------------------------------------------------------------------------------------------
% ------------------------------------------------------------------------------------------

% ------------------------------------------------------------------------------------------
% ------------------------------------------------------------------------------------------
% Update GUI from global variables
function UpdateGUI_Global(handles)
global myAppData
%get global variables
jsonMic = myAppData.jsonMic;

% update gui handles
set(handles.Gain_edit, 'string',num2str(2^(jsonMic.gain)));
set(handles.Gain_slider, 'value',jsonMic.gain);

if  (jsonMic.channel)
    set(handles.Channle_PushB, 'String','Filter Off');
    set(handles.Channle_PushB,'Backgroundcolor','r');
else
    set(handles.Channle_PushB, 'String','Filter On');
    set(handles.Channle_PushB,'Backgroundcolor','g');
end

set(handles.SigThresh_edit, 'string',num2str(jsonMic.sigThresh*100));
set(handles.SigThresh_slider, 'value',jsonMic.sigThresh*100);

set(handles.threshOn_edit, 'string',num2str(jsonMic.threshOn));
set(handles.threshOn_slider, 'value',(log10(jsonMic.threshOn)));

set(handles.adcLatency_edit, 'string',num2str(jsonMic.adcLatency));
set(handles.adcLatency_slider, 'value',(log10(jsonMic.adcLatency)));

if  (jsonMic.recordState)
    set(handles.recordState_PushB, 'String','Record On');
    set(handles.recordState_PushB,'Backgroundcolor','g');
else
    set(handles.recordState_PushB, 'String','Record Off');
    set(handles.recordState_PushB,'Backgroundcolor','r');
end

% disp mic gui structur
% disp('disp mic gui structure')
% disp(jsonMic)



% ------------------------------------------------------------------------------------------
% ------------------------------------------------------------------------------------------

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 'serConn')
    fclose(handles.serConn);
end
% Hint: delete(hObject) closes the figure
delete(hObject);

% --- Executes during object creation, after setting all properties.
function SendBox_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SendBox_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%==================================================================================
% Send Update to micro controller
function SendUpdate(handles)
global myAppData
while (myAppData.RecordingState)
    pause(0.5); %pause sending updates untill finished recieving bytes
    disp("waiting for message to arrive");
end

% retrieve setting from gui handles.
myAppData.jsonMic.mic = handles.jsonMic.mic;
myAppData.jsonMic.gain = get(handles.Gain_slider, 'value');
myAppData.jsonMic.sigThresh = get(handles.SigThresh_slider, 'value')/100;
myAppData.jsonMic.threshOn = str2double(get(handles.threshOn_edit, 'string'));
myAppData.jsonMic.adcLatency = str2double(get(handles.adcLatency_edit, 'string'));
if strcmp(get(handles.Channle_PushB,'String'),'Filter On') % currently disconnected
    myAppData.jsonMic.channel = 0;
else
    myAppData.jsonMic.channel = 1;
end
if strcmp(get(handles.recordState_PushB,'String'),'Record On') % currently disconnected
    myAppData.jsonMic.recordState = 1;
else
    myAppData.jsonMic.recordState = 0;
end

jsonMic = myAppData.jsonMic;

%debug msg json structure
disp('sent json structure');
disp(jsonMic);
jsontext=['json:' jsonencode(jsonMic)];
%jsontext=['json:' jsonencode(handles.jsonMSG) '\r\n'];
time = clock;
timeStr = [num2str(time(4)) ':' num2str(time(5)) ':' num2str(time(6)) ':'];
set(handles.SendBox_text, 'String',[timeStr '  ' jsontext]);
set(handles.ComState_edit,'Backgroundcolor','r');
fprintf(handles.serConn, jsontext);
% allow the mcu to process data before continues sending more staff
%pause(0.1); disabled since it has some issues with recording mode
%latencies.
return; % SendUpdate_MCU
%==================================================================================

%==================================================================================
% Get Update from micro controller
function GetUpdate(handles)
global myAppData
while (myAppData.RecordingState)
    pause(0.5); %pause sending updates untill finished recieving bytes
    disp("waiting for message to arrive");
end

%creat temp stracture to get an updated settings
jsonGetSetting.mic = 0;
jsonGetSetting.getSettings =1;

%debug msg json structure
disp('sent json structure');
disp(jsonGetSetting);
jsontext=['json:' jsonencode(jsonGetSetting)];
%jsontext=['json:' jsonencode(handles.jsonMSG) '\r\n'];
time = clock;
timeStr = [num2str(time(4)) ':' num2str(time(5)) ':' num2str(time(6)) ':'];
set(handles.SendBox_text, 'String',[timeStr '  ' jsontext]);
set(handles.ComState_edit,'Backgroundcolor','r');
fprintf(handles.serConn, jsontext);
% allow the mcu to process data before continues sending more staff
%pause(0.1); disabled since it has some issues with recording mode
%latencies.
return; % SendUpdate_MCU
%==================================================================================

% --- Executes on button press in Reset_PushB.
function Reset_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to Reset_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global myAppData;
% reset buffer
myAppData.RecordingData = uint8('');
myAppData.PacketData = [0];

%reset handles
jsonMic.mic = 0; 
jsonMic.gain = 0;
jsonMic.channel = 0;
jsonMic.threshOn = 1000;
jsonMic.sigThresh = 0.5;
jsonMic.adcLatency = 1000;
jsonMic.recordState = 0;

%update handles
handles.jsonMic = jsonMic;

% Update handles structure
guidata(hObject, handles);

%update gui handles
myAppData.jsonMic = jsonMic;
UpdateGUI_Global(handles);

if (handles.conStatus)
    % Send an update for whatever mic is connected
    SendUpdate(handles);
end
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function ComState_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ComState_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in UpdateMic1_PushB.
function UpdateMic1_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to UpdateMic1_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (handles.conStatus)
    set(handles.UpdateMic1_PushB,'Backgroundcolor','r');
    handles.jsonMic.mic = 1;
    SendUpdate(handles);
end
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in UpdateMicAll_PushB.
function UpdateMicAll_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to UpdateMicAll_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (handles.conStatus)
    handles.jsonMic.mic = 0;
    SendUpdate(handles);
end
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in UpdateMic2_PushB.
function UpdateMic2_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to UpdateMic2_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (handles.conStatus)
    set(handles.UpdateMic2_PushB,'Backgroundcolor','r');
    handles.jsonMic.mic = 2;
    SendUpdate(handles);
end
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in UpdateMic3_PushB.
function UpdateMic3_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to UpdateMic3_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (handles.conStatus)
    set(handles.UpdateMic3_PushB,'Backgroundcolor','r');
    handles.jsonMic.mic = 3;
    SendUpdate(handles);
end
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in UpdateMic4_PushB.
function UpdateMic4_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to UpdateMic4_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (handles.conStatus)
    set(handles.UpdateMic4_PushB,'Backgroundcolor','r');
    handles.jsonMic.mic = 4;
    SendUpdate(handles);
end
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in UpdateMic5_PushB.
function UpdateMic5_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to UpdateMic5_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (handles.conStatus)
    set(handles.UpdateMic5_PushB,'Backgroundcolor','r');
    handles.jsonMic.mic = 5;
    SendUpdate(handles);
end
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in UpdateMic10_PushB.
function UpdateMic10_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to UpdateMic10_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (handles.conStatus)
    set(handles.UpdateMic10_PushB,'Backgroundcolor','r');
    handles.jsonMic.mic = 10;
    if strcmp(get(handles.recordState_PushB,'String'),'Record On')
        handles.jsonMic.recordState = 1;
    end
    SendUpdate(handles);
end
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);


% --- Executes on slider movement.
function Gain_slider_Callback(hObject, eventdata, handles)
% hObject    handle to Gain_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gain = (get(hObject,'Value'));
% round gain
gain = (round(gain));
set(hObject, 'value',gain);
set(handles.Gain_edit, 'string',num2str(2^gain));
handles.jsonMic.gain = gain;
set(hObject, 'value',gain);

% Update handles structure
guidata(hObject, handles);
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function Gain_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Gain_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function Gain_edit_Callback(hObject, eventdata, handles)
% hObject    handle to Gain_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gain = str2double(get(hObject,'string'));
if (gain < 1)
    gain = 1;
elseif (gain > 128)
    gain = 128;
end
gain = 2^(round(log2(gain)));
set(hObject, 'string',num2str(gain))
set(handles.Gain_slider, 'value',(log2(gain)))
handles.jsonMic.gain = log2(gain);

% Update handles structure
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of Gain_edit as text
%        str2double(get(hObject,'String')) returns contents of Gain_edit as a double


% --- Executes during object creation, after setting all properties.
function Gain_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Gain_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function SigThresh_slider_Callback(hObject, eventdata, handles)
% hObject    handle to SigThresh_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tresh = round((get(hObject,'Value')));
set(handles.SigThresh_edit, 'string',num2str(tresh))
handles.jsonMic.sigThresh = tresh/100;

% Update handles structure
guidata(hObject, handles);
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function SigThresh_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SigThresh_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function SigThresh_edit_Callback(hObject, eventdata, handles)
% hObject    handle to SigThresh_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tresh = round(str2double(get(hObject,'string')));
if (tresh>100)
    tresh = 100;
    set(hObject, 'string',num2str(tresh))
elseif (tresh<0)
    tresh = 0;
    set(hObject, 'string',num2str(tresh))
end
set(handles.SigThresh_slider, 'value',tresh);
handles.jsonMic.sigThresh = tresh/100;

% Update handles structure
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of SigThresh_edit as text
%        str2double(get(hObject,'String')) returns contents of SigThresh_edit as a double


% --- Executes during object creation, after setting all properties.
function SigThresh_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SigThresh_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function threshOn_slider_Callback(hObject, eventdata, handles)
% hObject    handle to threshOn_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
threshOn = round(10^(get(hObject,'Value')));
set(handles.threshOn_edit, 'string',num2str(threshOn))
handles.jsonMic.threshOn = threshOn;

% Update handles structure
guidata(hObject, handles);
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function threshOn_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshOn_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function threshOn_edit_Callback(hObject, eventdata, handles)
% hObject    handle to threshOn_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
threshOn = round(str2double(get(hObject,'string')));
if (threshOn>10000)
    threshOn = 10000;
    set(hObject, 'string',num2str(threshOn))
elseif (threshOn<1)
    threshOn = 1;
    set(hObject, 'string',num2str(threshOn))
end
set(handles.threshOn_slider, 'value',(log10(threshOn)))
handles.jsonMic.threshOn = threshOn;

% Update handles structure
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of threshOn_edit as text
%        str2double(get(hObject,'String')) returns contents of threshOn_edit as a double


% --- Executes during object creation, after setting all properties.
function threshOn_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshOn_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function adcLatency_slider_Callback(hObject, eventdata, handles)
% hObject    handle to adcLatency_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
adcLatency = round(10^(get(hObject,'Value')));
set(handles.adcLatency_edit, 'string',num2str(adcLatency))
handles.jsonMic.adcLatency = adcLatency;

% Update handles structure
guidata(hObject, handles);
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function adcLatency_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to adcLatency_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function adcLatency_edit_Callback(hObject, eventdata, handles)
% hObject    handle to adcLatency_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
adcLatency = round(str2double(get(hObject,'string')));
if (adcLatency>10000)
    adcLatency = 10000;
    set(hObject, 'string',num2str(adcLatency))
elseif (adcLatency<1)
    adcLatency = 1;
    set(hObject, 'string',num2str(adcLatency))
end
set(handles.adcLatency_slider, 'value',(log10(adcLatency)))
handles.jsonMic.adcLatency = adcLatency;

% Update handles structure
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of adcLatency_edit as text
%        str2double(get(hObject,'String')) returns contents of adcLatency_edit as a double


% --- Executes during object creation, after setting all properties.
function adcLatency_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to adcLatency_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in recordState_PushB.
function recordState_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to recordState_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(hObject,'String'),'Record On') % currently disconnected
    set(hObject, 'String','Record Off')
    set(hObject,'Backgroundcolor','r');
else
    set(hObject, 'String','Record On')
    set(hObject,'Backgroundcolor','g');
end
guidata(hObject, handles);

% --- Executes on button press in Channle_PushB.
function Channle_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to Channle_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(hObject,'String'),'Filter On') % currently disconnected
    set(hObject, 'String','Filter Off')
    set(hObject,'Backgroundcolor','r');
    handles.jsonMic.channel = 1;
else
    set(hObject, 'String','Filter On')
    set(hObject,'Backgroundcolor','g');
    handles.jsonMic.channel = 0;
end
guidata(hObject, handles);


% --- Executes on button press in ResetPlot_PushB.
function ResetPlot_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to ResetPlot_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global myAppData
%update plot values
myAppData.PlotData = [0];
plot(handles.micRecord_axes,myAppData.PlotData);
guidata(hObject, handles);


% --- Executes on button press in GetSettings_PushB.
function GetSettings_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to GetSettings_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (handles.conStatus)
    % Request an update from whatever mic is connected
    GetUpdate(handles);
end
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
