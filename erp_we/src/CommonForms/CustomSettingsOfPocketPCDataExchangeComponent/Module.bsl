
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	RestoreSettings();
	
	If Not ValueIsFilled(TCPIPPort) Then
		TCPIPPort = 2003;
	EndIf;
	
	If Not ValueIsFilled(COMPort) Then
		COMPort = 1;
	EndIf;
	
	If Not ValueIsFilled(IRDAServiceName) Then
		IRDAServiceName = "S1C8";
	EndIf;
	
	InfoString = NStr("vi = 'Tùy chỉnh có hiệu lực đối với người sử dụng %CurrentUser%';
						|ru = 'Настройки действуют для пользователя %CurrentUser%';
						|en = 'Settings are valid for user %CurrentUser%'; fa = 'Settings are valid for user %CurrentUser%';
						|it = 'Le impostazioni sono valide per l''utente %CurrentUser%';
						|pl = 'Ustawienia obowiązują dla użytkownika %CurrentUser%';
						|tr = 'Ayarlar %CurrentUser% kullanıcısı için geçerlidir'");
	InformationAboutTheSettingsOwnership = 
		StrReplace(InfoString, "%CurrentUser%", Users.CurrentUser());
	
	SetItemsAvailability();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure KeepEventLogOnChange(Item)
	
	Items.EventLogDirectory.Enabled = KeepEventLog;
	
EndProcedure

&AtClient
Procedure UseTCPIPOnChange(Item)
	
	Items.TCPIPPort.Enabled = UseTCPIP;
	
EndProcedure

&AtClient
Procedure UseIRDAOnChange(Item)
	
	Items.IRDAServiceName.Enabled = UseIRDA;
	
EndProcedure

&AtClient
Procedure UseSOMPortOnChange(Item)
	
	Items.COMPort.Enabled = UseSOMPort;
	
EndProcedure

&AtClient
Procedure EventLogDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FileDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	FileDialog.Directory = EventLogDirectory;
	
	CallbackDescription = New CallbackDescription(
		"EventLogDirectoryDirectorySelection",
		ThisObject);
	
	FileDialog.Show(CallbackDescription);
	
EndProcedure

&AtClient
Procedure EventLogDirectoryDirectorySelection(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	EventLogDirectory = SelectedFiles[0];
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)
	
	If StandardSubsystemsClient.ClientParametersOnStart().ServiceSubsystems_ObjectsOfUTKAUP_OfSMPExchangeComponent <> Undefined Then
		
		MessageText = NStr("vi = 'Đã kết nối cấu phần trao đổi. Đặt tham số mới đối với cấu phần đã kết nối?';
							|ru = 'Компонента обмена подключена. Установить новые параметры для подключенной компоненты?';
							|en = 'Exchange add-in is attached. Set new parameters for the attached add-in?'; fa = 'Exchange add-in is attached. Set new parameters for the attached add-in?';
							|it = 'Componente dello scambio connesso. Impostare nuovi parametri per la connessione del componente?';
							|pl = 'Komponent wymiany jest podłączony. Ustawić nowe parametry do podłączonego komponentu?';
							|tr = 'Veri değişimi add-in bağlı. Bağlı add-in için yeni parametreler ayarla?'");
		Response = Undefined;

		ShowQueryBox(New CallbackDescription("SaveCompletion", ThisObject), MessageText, QuestionDialogMode.YesNo);
        Return;
		
	EndIf;
	
	SaveFragment();
EndProcedure

&AtClient
Procedure SaveCompletion(QuestionResult, AdditionalParameters) Export
    
    ComponentOfExchangeWithMobileApplications = StandardSubsystemsClient.ClientParametersOnStart().ServiceSubsystems_ObjectsOfUTKAUP_OfSMPExchangeComponent;
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.Yes Then
        
        ComponentOfExchangeWithMobileApplications.KeepEventLog = KeepEventLog;
        ComponentOfExchangeWithMobileApplications.EventLogDirectory = EventLogDirectory;
        
        If UseTCPIP Then
            ComponentOfExchangeWithMobileApplications.ConnectTCPIP(TCPIPPort);
        Else
            ComponentOfExchangeWithMobileApplications.Disconnect(1);	
        EndIf;
        
        If UseIRDA Then
            ComponentOfExchangeWithMobileApplications.ConnectIRDA(IRDAServiceName);
        Else
            ComponentOfExchangeWithMobileApplications.Disconnect(3);	
        EndIf;
        
        If UseSOMPort Then
            ComponentOfExchangeWithMobileApplications.ConnectCOMPort(COMPort);
        Else
            ComponentOfExchangeWithMobileApplications.Disconnect(4);
        EndIf;
        
    EndIf;
    
    SaveFragment();

EndProcedure

&AtClient
Procedure SaveFragment()
    
    ShouldSaveSettings();
    Close();

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ShouldSaveSettings()
	
	Common.CommonSettingsStorageSave("UserSettingsForDataExchangeComponent", "KeepEventLog", KeepEventLog);
	Common.CommonSettingsStorageSave("UserSettingsForDataExchangeComponent","EventLogDirectory", EventLogDirectory);
	Common.CommonSettingsStorageSave("UserSettingsForDataExchangeComponent","UseTCPIP", UseTCPIP);
	Common.CommonSettingsStorageSave("UserSettingsForDataExchangeComponent","UseIRDA", UseIRDA);
	Common.CommonSettingsStorageSave("UserSettingsForDataExchangeComponent","UseSOMPort", UseSOMPort);
	Common.CommonSettingsStorageSave("UserSettingsForDataExchangeComponent","TCPIPPort", TCPIPPort);
	Common.CommonSettingsStorageSave("UserSettingsForDataExchangeComponent","IRDAServiceName", IRDAServiceName);
	Common.CommonSettingsStorageSave("UserSettingsForDataExchangeComponent","COMPort", COMPort);
	Common.CommonSettingsStorageSave("UserSettingsForDataExchangeComponent",
										"ConnectDataExchangeComponentOnTheApplicationStart", ConnectDataExchangeComponentOnTheApplicationStart);
	
EndProcedure

&AtServer
Procedure RestoreSettings()
	
	SetSettingValue("KeepEventLog", KeepEventLog);
	SetSettingValue("EventLogDirectory", EventLogDirectory);
	SetSettingValue("UseTCPIP", UseTCPIP);
	SetSettingValue("UseIRDA", UseIRDA);
	SetSettingValue("UseSOMPort", UseSOMPort);
	SetSettingValue("TCPIPPort", TCPIPPort);
	SetSettingValue("IRDAServiceName", IRDAServiceName);
	SetSettingValue("COMPort", COMPort);
	SetSettingValue("ConnectDataExchangeComponentOnTheApplicationStart", ConnectDataExchangeComponentOnTheApplicationStart);
	
EndProcedure

&AtServer
Procedure SetSettingValue(SettingName, Setting)
	
	SettingValueFromStorage = Common.CommonSettingsStorageLoad("UserSettingsForDataExchangeComponent", SettingName);
	If SettingValueFromStorage <> Undefined Then
		Setting = SettingValueFromStorage;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetItemsAvailability()
	
	Items.TCPIPPort.Enabled = UseTCPIP;
	Items.IRDAServiceName.Enabled = UseIRDA;
	Items.COMPort.Enabled = UseSOMPort;
	Items.EventLogDirectory.Enabled = KeepEventLog;
	
EndProcedure

#EndRegion
