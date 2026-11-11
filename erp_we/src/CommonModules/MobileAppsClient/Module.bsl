#Region Public

// Connects an external MAppDataExch component to exchange data with mobile applications.
//
Procedure ConnectExternalComponentForDataExchangeWithMobileApplications() Export

	Notification = New CallbackDescription("AttachAddInSSLCompletion", ThisObject);
	
	ConnectionParameters = CommonClient.AddInAttachmentParameters();
	
	CommonClient.AttachAddInFromTemplate(Notification, 
		"MAppDataExchange",
	    "CommonTemplate.ComponentExchangeDataWithMobileApplications",
	    ConnectionParameters);

EndProcedure

Procedure AttachAddInSSLCompletion(Result, AdditionalParameters) Export
	
	If Result.Attached Then
		
		Message = NStr("vi = 'Các thành phần được kết nối.';
						|ru = 'Компонента подключена.';
						|en = 'Add-in is attached.'; fa = 'Add-in is attached.';
						|it = 'Il componente è collegato.';
						|pl = 'Komponent jest podłączony';
						|tr = 'Add-in bağlı.'");
		Picture = PictureLib.Information32;
	
		Try
			ApplicationParameters.Insert("StandardSubsystems.ObjectsOfTMCAERP.SMPExchangeComponent", Result.Attachable_Module);
			SetUserSettingsWhenWorkingWithDataExchangeComponent();
		Except
			ApplicationParameters.Insert("StandardSubsystems.ObjectsOfTMCAERP.SMPExchangeComponent", Undefined);
			Message = NStr("vi = 'khi kết nối thiết bị xảy ra lỗi';
							|ru = 'при подключении возникли ошибки.';
							|en = 'errors occurred when connecting.'; fa = 'errors occurred when connecting.';
							|it = 'Sono stati rilevati degli errori quando si collega.';
							|pl = 'Podczas podłączania wystąpiły błędy.';
							|tr = 'bağlanırken hatalar oluştu.'");
			Picture = PictureLib.Error32;
		EndTry;
	Else
		ApplicationParameters.Insert("StandardSubsystems.ObjectsOfTMCAERP.SMPExchangeComponent", Undefined);
		Message = NStr("vi = 'khi kết nối thiết bị xảy ra lỗi';
						|ru = 'при подключении возникли ошибки.';
						|en = 'errors occurred when connecting.'; fa = 'errors occurred when connecting.';
						|it = 'Sono stati rilevati degli errori quando si collega.';
						|pl = 'Podczas podłączania wystąpiły błędy.';
						|tr = 'bağlanırken hatalar oluştu.'");
		Picture = PictureLib.Error32;
	EndIf;
	
	MessageTitle = NStr("vi = 'Kết nối cấu phần:';
						|ru = 'Подключение компоненты:';
						|en = 'Attach component:'; fa = 'Attach component:';
						|it = 'Collegamento componenti:';
						|pl = 'Podłączenie komponentu:';
						|tr = 'Bağlantı add-in:'");
	ShowUserNotification(MessageTitle,,Message, Picture);
	
	Notify("ConnectingComponentsOfDataExchangeWithMobileApplications");

EndProcedure

// Processes an external event received from the mobile app
//
// Parameters:
//  Source - String - string describing the source
//  Event - String - string that identifies a specific event
//	Data - String - data received as part of the event.
//
Procedure ProcessExternalEventFromMobileApp(Source, Event, Data) Export
	
	EventSourceStructure = DescriptionOfEventSource(Source);
	
	ComponentOfExchangeWithMobileApplications = StandardSubsystemsClient.ClientParametersOnStart().ServiceSubsystems_ObjectsOfUTKAUP_OfSMPExchangeComponent;
	
	MobileComputerCode = EventSourceStructure.MobileComputerCode;
	MobileDatabaseID = EventSourceStructure.MobileDatabaseID;
	UserName = EventSourceStructure.UserName;
	UserPassword = EventSourceStructure.UserPassword;
	
	DataExchangeParameters = Data;
	
	// First, it checks whether the settings for the specified device and user are defined.
	If Not MobileApplicationsServerCall.AuthenticationCompleted(UserName, MobileComputerCode, UserPassword) Then
		MessageText = NStr("vi = 'Đối với người sử dụng chưa xác định tùy chỉnh trong hệ thống';
							|ru = 'Для пользователя не определены настройки в системе';
							|en = 'Settings are not defined in the application for the user'; fa = 'Settings are not defined in the application for the user';
							|it = 'Le impostazioni di sistema non sono definite per l''utente';
							|pl = 'Dla użytkownika nie są określone ustawienia w systemie';
							|tr = 'Sistemde kullanıcı için tanımlanmış herhangi bir ayar bulunmamaktadır'");
		Try
			ComponentOfExchangeWithMobileApplications.InformClientAboutError(MobileComputerCode, MessageText);
			Return;
		Except
			EventName = NStr("vi = 'Lỗi khi gọi ra phương thức cấu phần trao đổi dữ liệu';
							|ru = 'Ошибка при вызове метода компоненты обмена данными';
							|en = 'An error occurred while calling data exchange component method'; fa = 'An error occurred while calling data exchange component method';
							|it = 'Errore durante la chiamata del metodo della componente di scambio dati';
							|pl = 'Błąd podczas wezwania metody komponentu  wymiany danych';
							|tr = 'Veri alışverişi add-in yöntemi çağrılırken hata oluştu'");
			EventLogClient.AddMessageForEventLog(EventName,"Error",DetailErrorDescription(ErrorInfo()),,True);
			Return;
		EndTry;
	EndIf;
	
	If Event = "GetApplication" Then
		
		StringApplication = MobileApplicationsServerCall.GetApplication(UserName, MobileComputerCode, DataExchangeParameters);
		Try
			ComponentOfExchangeWithMobileApplications.InstallApp_(MobileComputerCode, StringApplication);
		Except
			EventName = NStr("vi = 'Lỗi khi gọi ra phương thức cấu phần trao đổi dữ liệu';
							|ru = 'Ошибка при вызове метода компоненты обмена данными';
							|en = 'An error occurred while calling data exchange component method'; fa = 'An error occurred while calling data exchange component method';
							|it = 'Errore durante la chiamata del metodo della componente di scambio dati';
							|pl = 'Błąd podczas wezwania metody komponentu  wymiany danych';
							|tr = 'Veri alışverişi add-in yöntemi çağrılırken hata oluştu'");
			EventLogClient.AddMessageForEventLog(EventName,"Error",DetailErrorDescription(ErrorInfo()),,True);
			Return;
		EndTry;
			
	ElsIf Event = "GetData" Then
		
		Try
			InitialIBInitialization = ComponentOfExchangeWithMobileApplications.GetInitialInitializationMode(MobileComputerCode);
		Except
			EventName = NStr("vi = 'Lỗi khi gọi ra phương thức cấu phần trao đổi dữ liệu';
							|ru = 'Ошибка при вызове метода компоненты обмена данными';
							|en = 'An error occurred while calling data exchange component method'; fa = 'An error occurred while calling data exchange component method';
							|it = 'Errore durante la chiamata del metodo della componente di scambio dati';
							|pl = 'Błąd podczas wezwania metody komponentu  wymiany danych';
							|tr = 'Veri alışverişi add-in yöntemi çağrılırken hata oluştu'");
			EventLogClient.AddMessageForEventLog(EventName,"Error",DetailErrorDescription(ErrorInfo()),,True);
			Return;
		EndTry;
		
		DataToExchange = MobileApplicationsServerCall.GetData(UserName, MobileComputerCode, InitialIBInitialization, DataExchangeParameters);
		
		Try
			ComponentOfExchangeWithMobileApplications.SendDataToClient(MobileComputerCode, DataToExchange);
		Except
			EventName = NStr("vi = 'Lỗi khi gọi ra phương thức cấu phần trao đổi dữ liệu';
							|ru = 'Ошибка при вызове метода компоненты обмена данными';
							|en = 'An error occurred while calling data exchange component method'; fa = 'An error occurred while calling data exchange component method';
							|it = 'Errore durante la chiamata del metodo della componente di scambio dati';
							|pl = 'Błąd podczas wezwania metody komponentu  wymiany danych';
							|tr = 'Veri alışverişi add-in yöntemi çağrılırken hata oluştu'");
			EventLogClient.AddMessageForEventLog(EventName,"Error",DetailErrorDescription(ErrorInfo()),,True);
			Return;
		EndTry;
		
	ElsIf Event = "WriteData" Then
		
		Try
			MobileApplicationData = ComponentOfExchangeWithMobileApplications.GetClientData(MobileComputerCode);
		Except
			EventName = NStr("vi = 'Lỗi khi gọi ra phương thức cấu phần trao đổi dữ liệu';
							|ru = 'Ошибка при вызове метода компоненты обмена данными';
							|en = 'An error occurred while calling data exchange component method'; fa = 'An error occurred while calling data exchange component method';
							|it = 'Errore durante la chiamata del metodo della componente di scambio dati';
							|pl = 'Błąd podczas wezwania metody komponentu  wymiany danych';
							|tr = 'Veri alışverişi add-in yöntemi çağrılırken hata oluştu'");
			EventLogClient.AddMessageForEventLog(EventName,"Error",DetailErrorDescription(ErrorInfo()),,True);
			Return;
		EndTry;
		
		Try
			MobileApplicationsServerCall.WriteData(UserName, MobileComputerCode, MobileApplicationData, DataExchangeParameters);
		Except
			MessageText = ErrorInfo().Description;
			Try
				ComponentOfExchangeWithMobileApplications.InformClientAboutError(MobileComputerCode, MessageText);
				Return;
			Except
				EventName = NStr("vi = 'Lỗi khi gọi ra phương thức cấu phần trao đổi dữ liệu';
								|ru = 'Ошибка при вызове метода компоненты обмена данными';
								|en = 'An error occurred while calling data exchange component method'; fa = 'An error occurred while calling data exchange component method';
								|it = 'Errore durante la chiamata del metodo della componente di scambio dati';
								|pl = 'Błąd podczas wezwania metody komponentu  wymiany danych';
								|tr = 'Veri alışverişi add-in yöntemi çağrılırken hata oluştu'");
				EventLogClient.AddMessageForEventLog(EventName,"Error",DetailErrorDescription(ErrorInfo()),,True);			
				Return;
			EndTry;
			EventName = NStr("vi = 'Lỗi khi ghi dữ liệu đã nhận từ ứng dụng di động';
							|ru = 'Ошибка при записи данных, полученных от мобильного приложения';
							|en = 'An error occurred while writing the data received from the mobile application'; fa = 'An error occurred while writing the data received from the mobile application';
							|it = 'Errore durante la scrittura dei dati ricevuti dall''applicazione mobile';
							|pl = 'Błąd podczas zapisu danych, otrzymanych od aplikacji mobilnej!';
							|tr = 'Mobil uygulamadan alınan veriler kaydedilirken hata oluştu'");
			EventLogClient.AddMessageForEventLog(EventName,"Error",DetailErrorDescription(ErrorInfo()),,True);
		EndTry;
		
	ElsIf Event = "ConfirmSessionTermination" Then
		
		Try
			MobileApplicationsServerCall.RegisterDataReceipt(UserName, MobileComputerCode, DataExchangeParameters);
		Except
			EventName = NStr("vi = 'Lỗi khi ghi nhận tiếp nhận dữ liệu từ ứng dụng di động';
							|ru = 'Ошибка при регистрации получения данных от мобильного приложения';
							|en = 'An error occurred while registering data receipt from the mobile application'; fa = 'An error occurred while registering data receipt from the mobile application';
							|it = 'Errore durante la registrazione della ricezione di dati dall''applicazione mobile';
							|pl = 'Błąd podczas rejestracji pobierania danych od aplikacji mobilnej!';
							|tr = 'Mobil uygulamadan veri almak için kayıt oluşturulurken hata oluştu'");
			EventLogClient.AddMessageForEventLog(EventName,"Error",DetailErrorDescription(ErrorInfo()),,True);
			Return;
		EndTry;
		
	EndIf;
	
EndProcedure

// Performs the necessary actions related to mobile applications at system startup.
//
Procedure OnStart() Export
	
	If StandardSubsystemsClient.ClientParametersOnStart().ConnectDataExchangeComponentOnTheApplicationStart Then
		ConnectExternalComponentForDataExchangeWithMobileApplications();
	EndIf;
	
EndProcedure

// It is performed before the interactive End of the user's work with the data area or in local mode.
//
Procedure BeforeExit() Export
	
EndProcedure

// Sets the settings defined for the current user in the data exchange component.
//
Procedure SetUserSettingsWhenWorkingWithDataExchangeComponent() Export
	
	SettingsList = MobileApplicationsServerCall.GetUserSettingsForDataExchangeComponent();
	
	ComponentOfExchangeWithMobileApplications = StandardSubsystemsClient.ClientParametersOnStart().ServiceSubsystems_ObjectsOfUTKAUP_OfSMPExchangeComponent;
	
	UseTCPIP = False;
	UseIRDA = False;
	UseSOMPort = False;
	
	TCPIPPort = 2002;
	IRDAServiceName = "S1C8";
	COMPort = 1;
	
	KeepEventLog = False;
	EventLogDirectory = "";
	
	For Each Setting In SettingsList Do
		If Setting.Presentation = "UseTCPIP" Then
			UseTCPIP = Setting.Value;
		ElsIf Setting.Presentation = "UseIRDA" Then
			UseIRDA = Setting.Value;
		ElsIf Setting.Presentation = "UseSOMPort" Then
			UseSOMPort = Setting.Value;
		ElsIf Setting.Presentation = "TCPIPPort" Then
			TCPIPPort = Setting.Value;
		ElsIf Setting.Presentation = "IRDAServiceName" Then
			IRDAServiceName = Setting.Value;
		ElsIf Setting.Presentation = "COMPort" Then
			COMPort = Setting.Value;
		ElsIf Setting.Presentation = "KeepEventLog" Then
			KeepEventLog = Setting.Value;
		ElsIf Setting.Presentation = "EventLogDirectory" Then
			EventLogDirectory = Setting.Value;
		EndIf;
	EndDo;
	
	ComponentOfExchangeWithMobileApplications = ApplicationParameters["StandardSubsystems.ObjectsOfTMCAERP.ComponentOfExchangeWithMobileApplications"];
	
	If UseTCPIP Then
		ComponentOfExchangeWithMobileApplications.ConnectTCPIP(TCPIPPort);
	EndIf;
	
	If UseIRDA Then
		ComponentOfExchangeWithMobileApplications.ConnectIRDA(IRDAServiceName);
	EndIf;
	
	If UseSOMPort Then
		ComponentOfExchangeWithMobileApplications.ConnectCOMPort(COMPort);
	EndIf;
	
	If KeepEventLog Then
		ComponentOfExchangeWithMobileApplications.EventLogDirectory = EventLogDirectory;
		ComponentOfExchangeWithMobileApplications.KeepEventLog = KeepEventLog;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Generates and returns a structure containing information about the exchange initiator
//
// Parameters:
//  Source - String - a delimited string containing information about the source.
//
// Returns:
//  Structure - A structure containing information about the exchange initiator.
//
Function DescriptionOfEventSource(Source)
	
	SourceStructure_ = New Structure();
	SourceStructure_.Insert("MobileComputerCode", StrReplace(StrGetLine(Source,2), Chars.LF, ""));
	SourceStructure_.Insert("MobileDatabaseID", StrReplace(StrGetLine(Source,3), Chars.LF, ""));
	SourceStructure_.Insert("UserName", StrReplace(StrGetLine(Source,4), Chars.LF, ""));
	SourceStructure_.Insert("UserPassword", StrReplace(StrGetLine(Source,5), Chars.LF, ""));
		
	Return SourceStructure_;
	
EndFunction

#EndRegion
