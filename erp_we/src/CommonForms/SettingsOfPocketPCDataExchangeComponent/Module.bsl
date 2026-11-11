
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SetConditionalAppearance();
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateStatuses();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ConnectingComponentsOfDataExchangeWithMobileApplications" Then
		UpdateStatuses();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure InstallAddInSSL(Command)
	
	ClearMessages();
	
	Notification = New CallbackDescription("InstallAddInSSLCompletion", ThisObject);

	InstallationParameters = CommonClient.AddInInstallParameters();

	CommonClient.InstallAddInFromTemplate(Notification,
        "CommonTemplate.ComponentExchangeDataWithMobileApplications",
        InstallationParameters);

EndProcedure

&AtClient
Procedure AttachAddInSSL(Command)
	
	ClearMessages();
	
	If StandardSubsystemsClient.ClientParametersOnStart().ServiceSubsystems_ObjectsOfUTKAUP_OfSMPExchangeComponent <> Undefined Then
		MessageText = NStr("vi = 'Cấu phần trao đổi dữ liệu với ứng dụng di động đã kết nối';
							|ru = 'Компонента обмена данными с мобильными приложениями уже подключена';
							|en = 'Add-in for exchanging data with mobile applications is already attached'; fa = 'Add-in for exchanging data with mobile applications is already attached';
							|it = 'Componente scambio di dati con le applicazioni mobili già collegato';
							|pl = 'Komponent wymiany danych z aplikacjami mobilnymi jest już podłączony';
							|tr = 'Mobil uygulamalarla veri alışverişi için add-in artık bağlı'");
		CommonClientServer.MessageToUser(MessageText);
	Else
		MobileAppsClient.ConnectExternalComponentForDataExchangeWithMobileApplications();
	EndIf;
	
EndProcedure

&AtClient
Procedure DetachComponent(Command)
	
	ClearMessages();
	
	If StandardSubsystemsClient.ClientParametersOnStart().ServiceSubsystems_ObjectsOfUTKAUP_OfSMPExchangeComponent = Undefined Then
		MessageText = NStr("vi = 'Cấu phần trao đổi dữ liệu chưa kết nối';
							|ru = 'Компонента обмена данными не подключена';
							|en = 'Data exchange add-in is not attached'; fa = 'Data exchange add-in is not attached';
							|it = 'Componente di scambio di dati non collegato';
							|pl = 'Komponent wymiany danych nie został podłączony';
							|tr = 'Veri değişimi add-in bağlı değil'");
		ShowMessageBox(New CallbackDescription("DetachComponentCompletion", ThisObject, New Structure("MessageText", MessageText)), MessageText);
        Return;
	Else
		StandardSubsystemsClient.ClientParametersOnStart().ServiceSubsystems_ObjectsOfUTKAUP_OfSMPExchangeComponent.Disconnect(0);
		StandardSubsystemsClient.ClientParametersOnStart().ServiceSubsystems_ObjectsOfUTKAUP_OfSMPExchangeComponent = Undefined;
		MessageText = NStr("vi = 'Ngắt bỏ cấu phần';
							|ru = 'Отключение компоненты';
							|en = 'Detach add-in'; fa = 'Detach add-in';
							|it = 'Disattivare componente';
							|pl = 'Wyłączanie komponentu';
							|tr = 'Add-in devre dışı bırakılması'");
		ExplanationText = NStr("vi = 'Cấu phần trao đổi dữ liệu đã ngắt kết nối';
								|ru = 'Компонента обмена данными отключена';
								|en = 'Data exchange add-in is disabled'; fa = 'Data exchange add-in is disabled';
								|it = 'Componente di scambio di dati disattivato';
								|pl = 'Komponent wymiany danych został wyłączony';
								|tr = 'Veri değişimi add-in devre dışı bırakıldı'");
		ShowUserNotification(MessageText,,ExplanationText, PictureLib.Information32);
	EndIf;
	
	DisableFragmentComponent();
EndProcedure

&AtClient
Procedure DetachComponentCompletion(AdditionalParameters) Export
    
    MessageText = AdditionalParameters.MessageText;
    
    
    DisableFragmentComponent();

EndProcedure

&AtClient
Procedure DisableFragmentComponent()
    
    UpdateStatuses();

EndProcedure

&AtClient
Procedure Settings(Command)
	
	OpenForm("CommonForm.CustomSettingsOfPocketPCDataExchangeComponent",,,,,, New CallbackDescription("SettingsCompletion", ThisObject), FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure SettingsCompletion(Result, AdditionalParameters) Export
    
    UpdateStatuses();

EndProcedure

&AtClient
Procedure UpdateStatusInformation(Command)
	
	UpdateStatuses();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ConnectionStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AddInAttached");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ConnectionStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AddInAttached");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", New Color(51, 153, 102));

EndProcedure

&AtClient
Procedure UpdateStatuses()
	
	ComponentOfExchangeWithMobileApplications = StandardSubsystemsClient.ClientParametersOnStart().ServiceSubsystems_ObjectsOfUTKAUP_OfSMPExchangeComponent;
	
	If ComponentOfExchangeWithMobileApplications <> Undefined Then
		
		AddInAttached = True;
		ConnectionStatus = NStr("vi = 'Cấu phần đã kết nối';
								|ru = 'Компонента подключена';
								|en = 'Add-in is attached'; fa = 'افزونه متصل است';
								|it = 'Il componente è connesso';
								|pl = 'Komponent jest podłączony';
								|tr = 'Add-in bağlı'");
		
		TCPIPConnected = ComponentOfExchangeWithMobileApplications.TCPIPConnected;
		SOMPortIsConnected = ComponentOfExchangeWithMobileApplications.SOMPortIsConnected;
		IRDAConnected = ComponentOfExchangeWithMobileApplications.IRDAConnected;
		
		TCPIPPort = ComponentOfExchangeWithMobileApplications.TCPIPPort;
		COMPort = ComponentOfExchangeWithMobileApplications.COMPort;
		IRDAServiceName = ComponentOfExchangeWithMobileApplications.IRDAServiceName;
		
		KeepEventLog = ComponentOfExchangeWithMobileApplications.KeepEventLog;
		EventLogDirectory = ComponentOfExchangeWithMobileApplications.EventLogDirectory;
		
	Else
		
		AddInAttached = False;
		ConnectionStatus = NStr("vi = 'Không kết nối cấu phần';
								|ru = 'Компонента не подключена';
								|en = 'Add-in is not attached'; fa = 'Add-in is not attached';
								|it = 'Componente non connesso';
								|pl = 'Komponent nie jest podłączony';
								|tr = 'Add-in bağlı değil'");
		
		TCPIPConnected = False;
		SOMPortIsConnected = False;
		IRDAConnected = False;
		
		TCPIPPort = 0;
		COMPort=0;
		IRDAServiceName = "";
		
		KeepEventLog = False;
		EventLogDirectory = "";
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InstallAddInSSLCompletion(Result, AdditionalParameters) Export
	
	If Not Result.IsSet And Not IsBlankString(Result.ErrorDescription) Then 
		ShowMessageBox(, Result.ErrorDescription);
	EndIf;
	
EndProcedure

#EndRegion
