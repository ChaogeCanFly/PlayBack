%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ReSpeaker GUI                  %
% Arkadiraf@gmail.con - 16/04/18 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%
%Notes: %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Current serial callback uses global variavles as the gui object isn`t passed and the handles cannt be refreshed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = SwitchGUI_V02(varargin)
% SWITCHGUI_V02 MATLAB code for SwitchGUI_V02.fig
%      SWITCHGUI_V02, by itself, creates a new SWITCHGUI_V02 or raises the existing
%      singleton*.
%
%      H = SWITCHGUI_V02 returns the handle to a new SWITCHGUI_V02 or the handle to
%      the existing singleton*.
%
%      SWITCHGUI_V02('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SWITCHGUI_V02.M with the given input arguments.
%
%      SWITCHGUI_V02('Property','Value',...) creates a new SWITCHGUI_V02 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SwitchGUI_V02_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SwitchGUI_V02_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SwitchGUI_V02

% Last Modified by GUIDE v2.5 08-Jun-2019 13:03:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @SwitchGUI_V02_OpeningFcn, ...
    'gui_OutputFcn',  @SwitchGUI_V02_OutputFcn, ...
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


% --- Executes just before SwitchGUI_V02 is made visible.
function SwitchGUI_V02_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SwitchGUI_V02 (see VARARGIN)
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

% disable all send buttons
set(handles.Debug_PushB, 'Enable', 'Off');
set(handles.Mode_PushB, 'Enable', 'Off');
% declare variables to use in guide
jsonSwitch.name = 'switch'; % Switch / DSP
jsonSwitch.mic = 0;
jsonSwitch.spk = [0 0 0 0 0];
jsonSwitch.LoopFreq = 0;
jsonSwitch.debug = 0;

% jsonDSP modes
jsonDSP.name = 'dsp';
jsonDSP.mode = 'off';

% jsonDSP Parameters
jsonDSP_Param.name = 'dspParam';
jsonDSP_Param.gain = round(str2double(get(handles.GainValue_edit,'string'))*1000); %issue in parsing doubles when the number is round
jsonDSP_Param.trigTresh = round(str2double(get(handles.TrigTresh_edit,'string')));
jsonDSP_Param.trigPass = round(str2double(get(handles.TrigPass_edit,'string')));
jsonDSP_Param.trigPause = round(str2double(get(handles.TrigPause_edit,'string')));

%jsonDSP filter Variables
jsonDSP_Filter.name = 'dspFilter';
jsonDSP_Filter.Sections = 1;
jsonDSP_Filter.SOSMat = round([1.0000   -2.0000    1.0000    1.0000   -1.9556    0.9565]*10000);
jsonDSP_Filter.Gscale = round(0.978*10000);

%jsonDSP play sound Variables
jsonDSP_Play.name = 'dspPlay';
jsonDSP_Play.file = 1;
jsonDSP_Play.gain = 1000;

%update handles
handles.jsonDSP_Param = jsonDSP_Param;
handles.jsonDSP_Filter = jsonDSP_Filter;
handles.jsonDSP_Play = jsonDSP_Play;
handles.jsonSwitch = jsonSwitch;
handles.jsonDSP = jsonDSP;
handles.conStatus = 0; % connection status variable

% global variables - Temporary solution for uart parser not accepting
% guidata hanles properly
% variable to store number of mic event
global myAppData
myAppData.micEvent.Num = 0;
myAppData.micEvent.Source = 0;
myAppData.micEvent.Time = 0;


% update hangles
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SwitchGUI_V02 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SwitchGUI_V02_OutputFcn(hObject, eventdata, handles)
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
        
        serConn = serial(serPort, 'TimeOut', 1, ...
            'BaudRate', str2num(get(handles.baudRateText, 'String')),...
            'BytesAvailableFcnMode','terminator',...
            'terminator','CR/LF');
        % try opening port
        try
            fopen(serConn);
            handles.serConn = serConn;
            
            % enable Send buttons
            handles.conStatus = 1;
            % enable Tx text field and Rx button
            set(handles.Debug_PushB, 'Enable', 'On');
            set(handles.Mode_PushB, 'Enable', 'On');
            
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
        Reset_PushB_Callback(hObject, eventdata, handles)
    end
else
    % disable all send buttons
    handles.conStatus=0;
    set(handles.Debug_PushB, 'Enable', 'Off');
    set(handles.Mode_PushB, 'Enable', 'Off');
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
serConn = handles.serConn;
%disp(handles.serConn);
%disp(serConn);
global myAppData
% try parse incoming data
try
    % print last recieved msg to SendBox_text
    RxText = fscanf(serConn);
    %disp('Recieved RxText');
    %disp(RxText);
    % if in debbuging mode, put message into debbug block
    if (strcmp(get(handles.Debug_PushB,'String'),'Debug On'))
        time = clock;
        timeStr = [num2str(time(4)) ':' num2str(time(5)) ':' num2str(time(6)) ':'];
        set(handles.DebugBox_text, 'String',[timeStr '  ' RxText]);
    end
    %try decode msg
    try
        jsonRecieved = jsondecode(RxText);
        %disp('json Recieved');
        %disp(jsonRecieved);
        % check what type of message recived:
        % chek if there is an Ack message
        if isfield(jsonRecieved,'event')
            %check which event recieved
            if strcmp(jsonRecieved.event,'micInt')
                % update data in global shared data
                myAppData.micEvent.Num = myAppData.micEvent.Num + 1;
                %set(handles.MicEventTable,'Data',[1,1]);
                myAppData.micEvent.Source(myAppData.micEvent.Num) = jsonRecieved.mic;
                myAppData.micEvent.Time(myAppData.micEvent.Num) = jsonRecieved.time;
                table=flipud([myAppData.micEvent.Source' myAppData.micEvent.Time']);
                tableSize=size(table,1);
                if (tableSize>19)
                    handles.MicEventTable.Data=table(1:19,:);
                else
                    handles.MicEventTable.Data=table;
                end
                % update mic events table
                % get frequency update
            elseif strcmp(jsonRecieved.event,'dspFreq')
                % update frequency block
                frequency  = round(jsonRecieved.Freq / 1000);
                if strcmp(get(handles.LoopFreq_PushB,'String'),'On') % update text block
                    set(handles.LoopFreq_edit, 'string', num2str(frequency));
                end
                % get microphone speaker update
            elseif strcmp(jsonRecieved.event,'switch')
                
                %disp('json Recieved');
                %disp(jsonRecieved);
                %Update Speakers / Mic Radio buttons based on the switch selection
                %disp(jsonRecieved.mic)
                % update radio button
                switch (jsonRecieved.mic)
                    case 0
                        set(handles.Mic0_RB, 'Value', 1);
                    case 1
                        set(handles.Mic1_RB, 'Value', 1);
                    case 2
                        set(handles.Mic2_RB, 'Value', 1);
                    case 3
                        set(handles.Mic3_RB, 'Value', 1);
                    case 4
                        set(handles.Mic4_RB, 'Value', 1);
                    case 5
                        set(handles.Mic5_RB, 'Value', 1);
                    otherwise
                        disp('unspecified microphone value')
                        disp(jsonRecieved.mic)
                end
                % update speaker selection
                set(handles.spk1_CB, 'Value', jsonRecieved.spk(1));
                set(handles.spk2_CB, 'Value', jsonRecieved.spk(2));
                set(handles.spk3_CB, 'Value', jsonRecieved.spk(3));
                set(handles.spk4_CB, 'Value', jsonRecieved.spk(4));
                set(handles.spk5_CB, 'Value', jsonRecieved.spk(5));
                % spk1_CB
                % Mic1_RB
                % speaker_BG
                % Mic_Selec_BG
            else
                % display message of unlisted event
                disp('json Recieved');
                disp(jsonRecieved);
                % not listed event
                time = clock;
                timeStr = [num2str(time(4)) ':' num2str(time(5)) ':' num2str(time(6)) ':'];
                set(handles.DebugBox_text, 'String',[timeStr '  ' RxText]);
            end
            %not event %Ack message to settings , if needed add parse here
        elseif isfield(jsonRecieved,'Ack')
            set(handles.ComState_edit,'Backgroundcolor','g');
            % display message of the json message
            disp('json Recieved');
            disp(jsonRecieved);
            % not an event
            time = clock;
            timeStr = [num2str(time(4)) ':' num2str(time(5)) ':' num2str(time(6)) ':'];
            set(handles.ReceiveBox_text, 'String',[timeStr '  ' RxText]);
        else % unknown messages - debbuging messages
            % display message of the json message
            disp('json Recieved');
            disp(jsonRecieved);
            % not an event
            time = clock;
            timeStr = [num2str(time(4)) ':' num2str(time(5)) ':' num2str(time(6)) ':'];
            set(handles.DebugBox_text, 'String',[timeStr '  ' RxText]);
        end %end not a known message
    catch e
        %disp(e);
        disp('Not json: ');
        %display msg
        disp(RxText);
        time = clock;
        timeStr = [num2str(time(4)) ':' num2str(time(5)) ':' num2str(time(6)) ':'];
        set(handles.DebugBox_text, 'String',[timeStr '  ' 'Not json: ' RxText]);
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

% --- Executes when selected object is changed in Mic_Selec_BG.
function Mic_Selec_BG_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in Mic_Selec_BG
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch get(eventdata.NewValue, 'Tag') % Get Tag of selected object.
    case 'Mic1_RB'
        micSelect = 1;
    case 'Mic2_RB'
        micSelect = 2;
    case 'Mic3_RB'
        micSelect = 3;
    case 'Mic4_RB'
        micSelect = 4;
    case 'Mic5_RB'
        micSelect = 5;
    otherwise
        %Code for when there is no match, no microphone selected.
        micSelect = 0;
end

% debbug msg to matlab
%txtInfo=sprintf('Mic %d Selected',micSelect);
%disp(txtInfo);
%set(handles.SendBox_text, 'String',txtInfo);

% update json stracture
handles.jsonSwitch.mic = micSelect;
handles.jsonSwitch.name = 'switch';
set(handles.Mode_PushB, 'String','Manual');
%disp(handles.jsonMSG.mic);

%send msg to mcu
if (handles.conStatus)
    SendUpdate_Switch_MCU(handles);
end
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in spk1_CB.
function spk1_CB_Callback(hObject, eventdata, handles)
% hObject    handle to spk1_CB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% update json stracture
handles.jsonSwitch.spk(1)=get(hObject,'Value');
handles.jsonSwitch.name = 'switch';
set(handles.Mode_PushB, 'String','Manual');
%disp(handles.jsonMSG.spk);
%send msg to mcu
if (handles.conStatus)
    SendUpdate_Switch_MCU(handles);
end
% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in spk2_CB.
function spk2_CB_Callback(hObject, eventdata, handles)
% hObject    handle to spk2_CB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% update json stracture
handles.jsonSwitch.spk(2)=get(hObject,'Value');
handles.jsonSwitch.name = 'switch';
set(handles.Mode_PushB, 'String','Manual');
%disp(handles.jsonMSG.spk);
%send msg to mcu
if (handles.conStatus)
    SendUpdate_Switch_MCU(handles);
end
% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in spk3_CB.
function spk3_CB_Callback(hObject, eventdata, handles)
% hObject    handle to spk3_CB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% update json stracture
handles.jsonSwitch.spk(3)=get(hObject,'Value');
handles.jsonSwitch.name = 'switch';
set(handles.Mode_PushB, 'String','Manual');
%disp(handles.jsonMSG.spk);
%send msg to mcu
if (handles.conStatus)
    SendUpdate_Switch_MCU(handles);
end
% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in spk4_CB.
function spk4_CB_Callback(hObject, eventdata, handles)
% hObject    handle to spk4_CB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% update json stracture
handles.jsonSwitch.spk(4)=get(hObject,'Value');
handles.jsonSwitch.name = 'switch';
set(handles.Mode_PushB, 'String','Manual');
%disp(handles.jsonMSG.spk);
%send msg to mcu
if (handles.conStatus)
    SendUpdate_Switch_MCU(handles);
end
% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in spk5_CB.
function spk5_CB_Callback(hObject, eventdata, handles)
% hObject    handle to spk5_CB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% update json stracture
handles.jsonSwitch.spk(5)=get(hObject,'Value');
handles.jsonSwitch.name = 'switch';
set(handles.Mode_PushB, 'String','Manual');
%disp(handles.jsonMSG.spk);
%send msg to mcu
if (handles.conStatus)
    SendUpdate_Switch_MCU(handles);
end
% Update handles structure
guidata(hObject, handles);



%==================================================================================
% Send Update to micro controller
function SendUpdate_Switch_MCU(handles)
%debug msg json structure
disp('sent json structure');
disp(handles.jsonSwitch);
jsontext=['json:' jsonencode(handles.jsonSwitch)];
%jsontext=['json:' jsonencode(handles.jsonMSG) '\r\n'];
fprintf(handles.serConn, jsontext);
time = clock;
timeStr = [num2str(time(4)) ':' num2str(time(5)) ':' num2str(time(6)) ':'];
set(handles.SendBox_text, 'String',[timeStr '  ' jsontext]);
set(handles.ComState_edit,'Backgroundcolor','r');
pause(0.1); % allow the mcu to process data before continues sending more staff
return; % SendUpdate_MCU
%==================================================================================
%==================================================================================
% Send Update to micro controller
function SendUpdate_DSP_MCU(handles)
%debug msg json structure
disp('sent json structure');
disp(handles.jsonDSP);
jsontext=['json:' jsonencode(handles.jsonDSP)];
%jsontext=['json:' jsonencode(handles.jsonMSG) '\r\n'];
fprintf(handles.serConn, jsontext);
time = clock;
timeStr = [num2str(time(4)) ':' num2str(time(5)) ':' num2str(time(6)) ':'];
set(handles.SendBox_text, 'String',[timeStr '  ' jsontext]);
set(handles.ComState_edit,'Backgroundcolor','r');
pause(0.1); % allow the mcu to process data before continues sending more staff
return; % SendUpdate_MCU
%==================================================================================
%==================================================================================
% Send Update to micro controller
function SendUpdate_DSP_Param_MCU(handles)
%debug msg json structure
disp('sent json structure');
disp(handles.jsonDSP_Param);
jsontext=['json:' jsonencode(handles.jsonDSP_Param)];
%jsontext=['json:' jsonencode(handles.jsonMSG) '\r\n'];
fprintf(handles.serConn, jsontext);
time = clock;
timeStr = [num2str(time(4)) ':' num2str(time(5)) ':' num2str(time(6)) ':'];
set(handles.SendBox_text, 'String',[timeStr '  ' jsontext]);
set(handles.ComState_edit,'Backgroundcolor','r');
pause(0.1); % allow the mcu to process data before continues sending more staff
return; % send update dsp Parameters
%==================================================================================
%==================================================================================
% Send Update to micro controller
function SendUpdate_DSP_Filter_MCU(handles)
%debug msg json structure
disp('sent json structure');
disp(handles.jsonDSP_Filter);
jsontext=['json:' jsonencode(handles.jsonDSP_Filter)];
%jsontext=['json:' jsonencode(handles.jsonMSG) '\r\n'];
fprintf(handles.serConn, jsontext);
time = clock;
timeStr = [num2str(time(4)) ':' num2str(time(5)) ':' num2str(time(6)) ':'];
set(handles.SendBox_text, 'String',[timeStr '  ' jsontext]);
set(handles.ComState_edit,'Backgroundcolor','r');
pause(0.1); % allow the mcu to process data before continues sending more staff
return; %send update DSP Filtrer
%==================================================================================

% Send Update to micro controller
function SendUpdate_DSP_Play_MCU(handles)
%debug msg json structure
disp('sent json structure');
disp(handles.jsonDSP_Play);
jsontext=['json:' jsonencode(handles.jsonDSP_Play)];
%jsontext=['json:' jsonencode(handles.jsonMSG) '\r\n'];
fprintf(handles.serConn, jsontext);
time = clock;
timeStr = [num2str(time(4)) ':' num2str(time(5)) ':' num2str(time(6)) ':'];
set(handles.SendBox_text, 'String',[timeStr '  ' jsontext]);
set(handles.ComState_edit,'Backgroundcolor','r');
pause(0.1); % allow the mcu to process data before continues sending more staff
return; %send update DSP Filtrer
%==================================================================================



% --- Executes when selected object is changed in Mode_Selec_BG.
function Mode_Selec_BG_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in Mode_Selec_BG
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch get(eventdata.NewValue, 'Tag') % Get Tag of selected object.
    case 'off_RB'
        handles.jsonDSP.mode = 'off';
    case 'passthrough_RB'
        handles.jsonDSP.mode = 'passthrough';
    case 'highpass_RB'
        handles.jsonDSP.mode = 'highpass';
    case 'hpf_trig_RB'
        handles.jsonDSP.mode = 'hpf_trig';
    case 'gain_trig_RB'
        handles.jsonDSP.mode = 'gain_trig';
    case 'delay_trig_RB'
        handles.jsonDSP.mode = 'delay_trig';
    case 'fir_trig_RB'
        handles.jsonDSP.mode = 'fir_trig';
    otherwise
        %Code for when there is no match
        handles.jsonDSP.mode = 'off';
end
%send msg to mcu
if (handles.conStatus)
    SendUpdate_DSP_MCU(handles);
end
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in Mode_PushB.
function Mode_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to Mode_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (handles.conStatus)
    if strcmp(get(hObject,'String'),'Manual') % Change to auto mode
        set(hObject, 'String','Auto');
        % update switch json structure
        handles.jsonSwitch.name = 'auto'; % Switch / DSP
        handles.jsonSwitch.mic = 0;
        handles.jsonSwitch.spk = [0 0 0 0 0];
        SendUpdate_Switch_MCU(handles);
    else %% change to manual mode
        % declare variables to use in guide
        set(hObject, 'String','Manual')
        % update switch json structure
        handles.jsonSwitch.name = 'switch'; % Switch / DSP
        handles.jsonSwitch.mic = 0;
        handles.jsonSwitch.spk = [0 0 0 0 0];
        SendUpdate_Switch_MCU(handles);
    end
end
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in Debug_PushB.
function Debug_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to Debug_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (handles.conStatus)
    if strcmp(get(hObject,'String'),'Debug Off') % Change to auto mode
        set(hObject, 'String','Debug On');
        % update switch json structure
        handles.jsonSwitch.debug = 1;
        SendUpdate_Switch_MCU(handles);
    else %% change to manual mode
        % declare variables to use in guide
        set(hObject, 'String','Debug Off')
        % update switch json structure
        handles.jsonSwitch.debug = 0;
        SendUpdate_Switch_MCU(handles);
    end
end
% handles.micEventNum = handles.micEventNum+1;
%           %set(handles.MicEventTable,'Data',[1,1]);
%           handles.MicEventTable.Data={1,1};
% Update handles structure
%           a= handles.micEvent.Num + 1;
%           handles.micEvent.Num = a;
%           disp(a);
guidata(hObject, handles);


% --- Executes on button press in SaveLog_PushB.
function SaveLog_PushB_Callback(hObject, eventdata, handles)
global myAppData;
% get data in global shared data
table=[myAppData.micEvent.Source' myAppData.micEvent.Time'];
logFileName=get(handles.FileName_Edit,'String');
save(logFileName,'table');


% hObject    handle to SaveLog_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function FileName_Edit_Callback(hObject, eventdata, handles)
% hObject    handle to FileName_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FileName_Edit as text
%        str2double(get(hObject,'String')) returns contents of FileName_Edit as a double


% --- Executes during object creation, after setting all properties.
function FileName_Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FileName_Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function MicEventTable_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MicEventTable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in Reset_PushB.
function Reset_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to Reset_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global myAppData
myAppData.micEvent.Num = 0;
myAppData.micEvent.Source = 0;
myAppData.micEvent.Time = 0;

% update json stracture
handles.jsonSwitch.mic = 0;
handles.jsonSwitch.spk(1) = 0;
handles.jsonSwitch.spk(2) = 0;
handles.jsonSwitch.spk(3) = 0;
handles.jsonSwitch.spk(4) = 0;
handles.jsonSwitch.spk(5) = 0;
handles.jsonSwitch.name = 'switch';
set(handles.Mode_PushB, 'String','Manual');
%disp(handles.jsonMSG.mic);
handles.jsonDSP.mode = 'off';
% Update handles
handles.MicEventTable.Data={};
set(handles.Mic0_RB, 'Value', 1);
set(handles.off_RB, 'Value', 1);
% update speaker selection
set(handles.spk1_CB, 'Value', 0);
set(handles.spk2_CB, 'Value', 0);
set(handles.spk3_CB, 'Value', 0);
set(handles.spk4_CB, 'Value', 0);
set(handles.spk5_CB, 'Value', 0);

set(handles.spk5_CB, 'Value', 0);
% Update handles structure
guidata(hObject, handles);
%send msg to mcu
if (handles.conStatus)
    SendUpdate_Switch_MCU(handles);
    SendUpdate_DSP_MCU(handles);
end

% --- Executes on button press in UpdateParam_PushB.
function UpdateParam_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to UpdateParam_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.jsonDSP_Param.gain      = round(str2double(get(handles.GainValue_edit,'string'))*1000); %issue in parsing doubles when the number is round
handles.jsonDSP_Param.trigTresh = round(str2double(get(handles.TrigTresh_edit,'string')));
handles.jsonDSP_Param.trigPass  = round(str2double(get(handles.TrigPass_edit,'string')));
handles.jsonDSP_Param.trigPause = round(str2double(get(handles.TrigPause_edit,'string')));
% Update handles structure
guidata(hObject, handles);
%send msg to mcu
if (handles.conStatus)
    SendUpdate_DSP_Param_MCU(handles);
end



% --- Executes on slider movement.
function Gain_slider_Callback(hObject, eventdata, handles)
% hObject    handle to Gain_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gain = 10^(get(hObject,'Value'));
set(handles.GainValue_edit, 'string',num2str(gain))

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



function GainValue_edit_Callback(hObject, eventdata, handles)
% hObject    handle to GainValue_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gain = str2double(get(hObject,'string'));
if (gain>10)
    gain = 10;
    set(hObject, 'string',num2str(gain))
elseif (gain<0.1)
    gain = 0.1;
    set(hObject, 'string',num2str(gain))
end
set(handles.Gain_slider, 'value',(log10(gain)))

% Update handles structure
guidata(hObject, handles);

% Hints: get(hObject,'String') returns contents of GainValue_edit as text
%        str2double(get(hObject,'String')) returns contents of GainValue_edit as a double


% --- Executes on slider movement.
function TrigTresh_slider_Callback(hObject, eventdata, handles)
% hObject    handle to TrigTresh_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tresh = round((get(hObject,'Value')));
set(handles.TrigTresh_edit, 'string',num2str(tresh))

% Update handles structure
guidata(hObject, handles);
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function TrigTresh_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TrigTresh_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function TrigTresh_edit_Callback(hObject, eventdata, handles)
% hObject    handle to TrigTresh_edit (see GCBO)
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
set(handles.TrigTresh_slider, 'value',tresh);

% Update handles structure
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of TrigTresh_edit as text
%        str2double(get(hObject,'String')) returns contents of TrigTresh_edit as a double


% --- Executes during object creation, after setting all properties.
function TrigTresh_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TrigTresh_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function TrigPass_slider_Callback(hObject, eventdata, handles)
% hObject    handle to TrigPass_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
pass = round(10^(get(hObject,'Value')));
set(handles.TrigPass_edit, 'string',num2str(pass))

% Update handles structure
guidata(hObject, handles);
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function TrigPass_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TrigPass_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function TrigPass_edit_Callback(hObject, eventdata, handles)
% hObject    handle to TrigPass_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
pass = round(str2double(get(hObject,'string')));
if (pass>100000)
    pass = 100000;
    set(hObject, 'string',num2str(pass))
elseif (pass<1)
    pass = 1;
    set(hObject, 'string',num2str(pass))
end
set(handles.TrigPass_slider, 'value',(log10(pass)))
% Update handles structure
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of TrigPass_edit as text
%        str2double(get(hObject,'String')) returns contents of TrigPass_edit as a double


% --- Executes during object creation, after setting all properties.
function TrigPass_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TrigPass_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function TrigPause_slider_Callback(hObject, eventdata, handles)
% hObject    handle to TrigPause_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
pause = round(10^(get(hObject,'Value')));
set(handles.TrigPause_edit, 'string',num2str(pause))

% Update handles structure
guidata(hObject, handles);
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function TrigPause_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TrigPause_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function TrigPause_edit_Callback(hObject, eventdata, handles)
% hObject    handle to TrigPause_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
pause = round(str2double(get(hObject,'string')));
if (pause>1000)
    pause = 1000;
    set(hObject, 'string',num2str(pause))
elseif (pause<1)
    pause = 1;
    set(hObject, 'string',num2str(pause))
end
set(handles.TrigPause_slider, 'value',(log10(pause)))

% Update handles structure
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of TrigPause_edit as text
%        str2double(get(hObject,'String')) returns contents of TrigPause_edit as a double


% --- Executes during object creation, after setting all properties.
function TrigPause_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TrigPause_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in GetSettings_PushB.
function GetSettings_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to GetSettings_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Open settings
[file,path] = uigetfile('*.mat');
if isequal(file,0) || isequal(path,0)
    disp('User clicked Cancel.');
else
    load(fullfile(path,file));
    disp(jsonSwitch);
    disp(jsonDSP);
    disp(jsonDSP_Param);
    disp(jsonDSP_Filter);
    % jsonSwitch
    handles.jsonSwitch = jsonSwitch;
    % jsonDSP modes
    handles.jsonDSP = jsonDSP;
    % jsonDSP Parameters
    handles.jsonDSP_Param = jsonDSP_Param;
    %jsonDSP filter Variables
    handles.jsonDSP_Filter = jsonDSP_Filter;
    
    % add gui update settings based on the retrieved data
    
    % add update mcu based on the retrieved data
    
end
guidata(hObject, handles);



function LoopFreq_edit_Callback(hObject, eventdata, handles)
% hObject    handle to LoopFreq_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
frequency = round(str2double(get(hObject,'string')));
if (frequency>10000)
    frequency = 10000;
    set(hObject, 'string',num2str(frequency))
elseif (frequency<10)
    frequency = 10;
    set(hObject, 'string',num2str(frequency))
end
% Update handles structure
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of LoopFreq_edit as text
%        str2double(get(hObject,'String')) returns contents of LoopFreq_edit as a double


% --- Executes during object creation, after setting all properties.
function LoopFreq_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LoopFreq_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in LoopFreq_PushB.
function LoopFreq_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to LoopFreq_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% toggle text on button press
if strcmp(get(hObject,'String'),'On') % Change to off
    set(hObject, 'String','Off');
    handles.jsonSwitch.LoopFreq = 0;
else %% change to On
    set(hObject, 'String','On');
    handles.jsonSwitch.LoopFreq = 1;
end
% Update handles structure
guidata(hObject, handles);
%send msg to mcu
if (handles.conStatus)
    SendUpdate_Switch_MCU(handles);
end



function filterOrder_edit_Callback(hObject, eventdata, handles)
% hObject    handle to filterOrder_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fOrder = round(str2double(get(hObject,'string')));
if (fOrder>10)
    fOrder = 10;
elseif (fOrder<1)
    fOrder = 1;
end
% update block with rounded number
set(hObject, 'string',num2str(fOrder))
% Update handles structure
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of filterOrder_edit as text
%        str2double(get(hObject,'String')) returns contents of filterOrder_edit as a double


% --- Executes during object creation, after setting all properties.
function filterOrder_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filterOrder_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function filterCutFreq_edit_Callback(hObject, eventdata, handles)
% hObject    handle to filterCutFreq_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fc = str2double(get(hObject,'string'));
if (fc>100)
    fc = 100;
    set(hObject, 'string',num2str(fc))
elseif (fc<0.1)
    fc = 0.1;
    set(hObject, 'string',num2str(fc))
end
% Update handles structure
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of filterCutFreq_edit as text
%        str2double(get(hObject,'String')) returns contents of filterCutFreq_edit as a double


% --- Executes during object creation, after setting all properties.
function filterCutFreq_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filterCutFreq_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in designFilter_PushB.
function designFilter_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to designFilter_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Fs = str2double(get(handles.LoopFreq_edit,'string'))*1000;% Sample rate
fc = str2double(get(handles.filterCutFreq_edit,'string'))*1000;% cut off freq
Wn = (2/Fs)*fc;
FilterOrder=round(str2double(get(handles.filterOrder_edit,'string'))); % filter order
[z,p,k] = butter(FilterOrder,Wn,'HIGH');
%[z,p,k]=ellip(FilterOrder,RipplePass,RippleStop,Wn,'HIGH');
% Convert to Coeficients matrix
[SOS,G] = zp2sos(z,p,k);
% Plot The filter response:
hBqF=dsp.BiquadFilter('Structure','Direct form I', ...
    'SOSMatrix',SOS,'ScaleValues',G);
%displayFilter
fvtool(hBqF,'Fs',Fs);

handles.jsonDSP_Filter.Sections = size(SOS,1);
ASOS = SOS'; % convert matrix to vector array (row by row)
SOSMatVect = ASOS(:)';
SOSMatVect = round(SOSMatVect*10000); %pass variable as an int x.xxxx
handles.jsonDSP_Filter.SOSMat = SOSMatVect;
handles.jsonDSP_Filter.Gscale = round(G*10000);

disp(' Filter Coefficients ');
disp(handles.jsonDSP_Filter.Sections);
disp(SOS);
disp(handles.jsonDSP_Filter.Gscale);

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in updateFilter_PushB.
function updateFilter_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to updateFilter_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (handles.conStatus)
    SendUpdate_DSP_Filter_MCU(handles);
end
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


% --- Executes on button press in SaveSettings_PushB.
function SaveSettings_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to SaveSettings_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get all settings
% jsonSwitch
jsonSwitch = handles.jsonSwitch;
% jsonDSP modes
jsonDSP = handles.jsonDSP;
% jsonDSP Parameters
jsonDSP_Param = handles.jsonDSP_Param;
%jsonDSP filter Variables
jsonDSP_Filter = handles.jsonDSP_Filter;

%save settings
[file,path] = uiputfile('*.mat');
if isequal(file,0) || isequal(path,0)
    disp('User clicked Cancel.');
else
    save(fullfile(path,file),'jsonSwitch','jsonDSP','jsonDSP_Param','jsonDSP_Filter');
end
guidata(hObject, handles);


% --- Executes on button press in PlaySound_PushB.
function PlaySound_PushB_Callback(hObject, eventdata, handles)
% hObject    handle to PlaySound_PushB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (handles.conStatus)
    SendUpdate_DSP_Play_MCU(handles);
end
% Update handles structure
guidata(hObject, handles);
