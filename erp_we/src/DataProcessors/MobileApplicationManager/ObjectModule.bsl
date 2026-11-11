#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the mobile app that is relevant for the specified user and computer.
//
// Parameters:
//  UserName - String - name of the mobile app user to get the mobile app for
//  MobileComputerCode - String - code of the mobile computer that the mobile app is being requested for
//  DataExchangeParameters - String - XMl string of parameters defined in the mobile app.
//   
// Returns:
//  String - a string containing a mobile application.
//
Function GetMobileApp(UserName, MobileComputerCode, DataExchangeParameters = "") Export
	
	SetPrivilegedMode(True);
	
	ExchangeNode = MobileApps.GetExchangeNodeForMobileConnection(UserName, MobileComputerCode);
	
	MobileApplication = Common.ObjectAttributeValue(ExchangeNode, "MobileApplicationVersion.MobileApplication");
	
	#If ExternalConnection Then
	If IsBlankString(MobileApplication) Then
		MessageText = NStr("vi = 'Trong cơ sở thông tin không có tệp ứng dụng di động';
							|ru = 'В информационной базе отсутствует файл мобильного приложения';
							|en = 'Mobile app file is missing in the infobase'; fa = 'Mobile app file is missing in the infobase';
							|it = 'Non esiste un file di applicazione mobile nel database informatico';
							|pl = 'W bazie danych nie ma pliku aplikacji mobilnej';
							|tr = 'Bilgi tabanında mobil uygulama dosyası yok'");
		Raise(MessageText);
	EndIf;
	#EndIf

	Return MobileApplication;
	
EndFunction

// Writes the mobile app as an encoded string
//
// Parameters:  
//  MobileAppName - String - the name of the mobile application
//  MobileApplicationVersion - String - ID of the mobile app version
//  MobileApplication - String - a string that contains the file mobile application
//  UsedMetadata - String - a string containing a list of metadata used by the mobile app, in
//                                    XML format.
// 
Procedure BurnMobileApp(MobileAppName, MobileApplicationVersion, MobileApplication, UsedMetadata) Export
	
	SetPrivilegedMode(True);
	
	If IsBlankString(MobileAppName) Then
		MessageText = NStr("vi = 'Chưa chỉ ra tên ứng dụng di động';
							|ru = 'Не указано имя мобильного приложения';
							|en = 'Mobile application name is not specified'; fa = 'Mobile application name is not specified';
							|it = 'Nome di applicazione mobile non è specificato';
							|pl = 'Nie określono nazwy aplikacji mobilnej';
							|tr = 'Mobil uygulamanın ismi belirtilmedi'");
		Raise(MessageText);
	ElsIf IsBlankString(MobileApplicationVersion) Then
		MessageText = NStr("vi = 'Chưa chỉ ra phiên bản của ứng dụng di động';
							|ru = 'Не указана версия мобильного приложения';
							|en = 'Specify mobile application version'; fa = 'Specify mobile application version';
							|it = 'La versione di applicazione mobile non è specificata';
							|pl = 'Nie określono żadnej wersji aplikacji mobilnej';
							|tr = 'Mobil uygulamanın sürümü belirtilmedi'");
        Raise(MessageText);
	EndIf;
	
	ApplicationGroup = MobileApps.GetAppGroup(MobileAppName);
	
	// If the group corresponding to the application is not in the directory, we will create it
	If ApplicationGroup.IsEmpty() Then	
		Object = Catalogs.MobileApplicationsVersions.CreateFolder();
		Object.Description = MobileAppName;
		Object.Write();
		ApplicationGroup = Object.Ref;
	EndIf;	
	
	// Let's check if this version is already in the directory
	ApplicationElement_ = MobileApps.GetAppElement(MobileAppName, MobileApplicationVersion);
	
	If ApplicationElement_.IsEmpty() Then
		Object = Catalogs.MobileApplicationsVersions.CreateItem();
		Object.Parent = ApplicationGroup;
		Object.Code = MobileApplicationVersion;
		Object.Description = MobileAppName + ", version: " + MobileApplicationVersion;
	Else	
		Object = ApplicationElement_.GetObject();
	EndIf;
	
	Object.MobileApplication = MobileApplication;
	Object.UsedMetadata = UsedMetadata;
	
	Try
		Object.Write();
	Except
		
		DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
		
		MessageText = ErrorInfo().Description;
		WriteLogEvent(NStr("vi = 'Lỗi ghi lại ứng dụng di động';
							|ru = 'Ошибка записи мобильного приложения';
							|en = 'An error occurred while saving the mobile application'; fa = 'An error occurred while saving the mobile application';
							|it = 'Errore di scrittura di applicazione mobile';
							|pl = 'Błąd zapisu aplikacji mobilnej';
							|tr = 'Mobil uygulama kaydı hatası'", DefaultLanguageCode),
								EventLogLevel.Error,
								,
								,
								MessageText);
		
		ExceptionText = NStr("vi = 'Lỗi ghi lại ứng dụng di động';
							|ru = 'Ошибка записи мобильного приложения';
							|en = 'An error occurred while saving the mobile application'; fa = 'An error occurred while saving the mobile application';
							|it = 'Errore di scrittura di applicazione mobile';
							|pl = 'Błąd zapisu aplikacji mobilnej';
							|tr = 'Mobil uygulama kaydı hatası'");
		Raise(ExceptionText);
		
	EndTry;
	
EndProcedure

// Returns data selected from the IB in accordance with the exchange scheme set for the user.
//
// Parameters:
//  UserName - String - name of the user of the mobile app that you want to get information about is
//  MobileComputerCode - String - code of the mobile computer for which data is requested
//  InitialIBInitialization - Boolean - indicates that the initial initialization of the mobile information system is being performed
//  DataExchangeParameters - String - XMl string of parameters defined in the mobile app.
//   
// Returns:
//  String - information security data in the form of an XMl string.
//
Function GetData(UserName, MobileComputerCode, Val InitialIBInitialization = False, DataExchangeParameters = "") Export
	
	SetPrivilegedMode(True);
	
	ExchangeNode = MobileApps.GetExchangeNodeForMobileConnection(UserName, MobileComputerCode);
	
	#If ExternalConnection Then
	ConnectionInitializationString =NStr("vi = 'Đối với người sử dụng %UserName% và máy tính xách tay %MobileComputerCode%';
										|ru = 'Для пользователя %UserName% и мобильного компьютера %MobileComputerCode%';
										|en = 'For user %UserName% and mobile device %MobileComputerCode%'; fa = 'For user %UserName% and mobile device %MobileComputerCode%';
										|it = 'Per l''utente %UserName% e computer portatile %MobileComputerCode%';
										|pl = 'Dla użytkownika %UserName% i komputera mobilnego %MobileComputerCode%';
										|tr = 'Kullanıcı %UserName% ve mobil bilgisayar %MobileComputerCode% için'");
	ConnectionInitializationString = StrReplace(ConnectionInitializationString, "%UserName%", UserName);
	ConnectionInitializationString = StrReplace(ConnectionInitializationString, "%MobileComputerCode%", MobileComputerCode);
	
	MobileApplicationVersion = Common.ObjectAttributeValue(ExchangeNode, "MobileApplicationVersion");
	If MobileApplicationVersion.IsEmpty() Then
		MessageText = NStr("vi = 'phiên bản đã sử dụng của đơn di động không được chỉ định';
							|ru = 'не указана используемая версия мобильного приложения';
							|en = 'used mobile application version is not specified'; fa = 'used mobile application version is not specified';
							|it = 'la versione di applicazione mobile utilizzata non è specificata';
							|pl = 'wersja aplikacji mobilnej nie jest wskazana';
							|tr = 'mobil uygulamanın kullanılan sürümü belirtilmedi'");
		Raise(ConnectionInitializationString + " " + MessageText);
	EndIf;
	#EndIf
	
	// If the initial initialization of the mobile information system is performed, it is necessary to mark all data that meets the exchange scheme
	// as changed for this exchange node.
	If InitialIBInitialization Then
		MobileApps.RecordDataChanges(ExchangeNode);
	EndIf;
	
	StructureOfDataExchangeParameters = MobileApps.DescriptionOfDataExchangeParameters(DataExchangeParameters);
	
	MobileApps.PrepareData(ExchangeNode, StructureOfDataExchangeParameters);
	
	Return MobileApps.GenerateExchangeBatch(ExchangeNode, StructureOfDataExchangeParameters, InitialIBInitialization);
	
EndFunction

// Writes data received from the mobile app to the current is
//
// Parameters:
//  UserName - String - name of the mobile app user whose data needs to be recorded
//  MobileComputerCode - String - code of the mobile computer from which the data was received
//  MobileApplicationData - String - a string containing XML-serialized data received from the mobile app
//  DataExchangeParameters - String - XMl string of parameters defined in the mobile app.
// 
Procedure WriteData(UserName, MobileComputerCode, MobileApplicationData, DataExchangeParameters = "") Export
	
	SetPrivilegedMode(True);
	
	ExchangeNode = MobileApps.GetExchangeNodeForMobileConnection(UserName, MobileComputerCode);
	
	#If ExternalConnection Then
	ConnectionInitializationString =NStr("vi = 'Đối với người sử dụng %UserName% và máy tính xách tay %MobileComputerCode%';
										|ru = 'Для пользователя %UserName% и мобильного компьютера %MobileComputerCode%';
										|en = 'For user %UserName% and mobile device %MobileComputerCode%'; fa = 'For user %UserName% and mobile device %MobileComputerCode%';
										|it = 'Per l''utente %UserName% e computer portatile %MobileComputerCode%';
										|pl = 'Dla użytkownika %UserName% i komputera mobilnego %MobileComputerCode%';
										|tr = 'Kullanıcı %UserName% ve mobil bilgisayar %MobileComputerCode% için'");
	ConnectionInitializationString = StrReplace(ConnectionInitializationString, "%UserName%", UserName);
	ConnectionInitializationString = StrReplace(ConnectionInitializationString, "%MobileComputerCode%", MobileComputerCode);
	
	MobileApplicationVersion = Common.ObjectAttributeValue(ExchangeNode, "MobileApplicationVersion");
	If MobileApplicationVersion.IsEmpty() Then
		MessageText = NStr("vi = 'phiên bản đã sử dụng của đơn di động không được chỉ định';
							|ru = 'не указана используемая версия мобильного приложения';
							|en = 'used mobile application version is not specified'; fa = 'used mobile application version is not specified';
							|it = 'la versione di applicazione mobile utilizzata non è specificata';
							|pl = 'wersja aplikacji mobilnej nie jest wskazana';
							|tr = 'mobil uygulamanın kullanılan sürümü belirtilmedi'");
		Raise(ConnectionInitializationString + " " + MessageText);
	EndIf;
	#EndIf

	Try
		MobileApps.RecordDataOfReceivedExchangePacket(ExchangeNode, MobileApplicationData, DataExchangeParameters);
	Except
		
		DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
		
		MessageText = ErrorInfo().Description;
		WriteLogEvent(NStr("vi = 'Lỗi ghi lại dữ liệu đã nhận từ ứng dụng di động';
							|ru = 'Ошибка записи данных, полученных от мобильного приложения';
							|en = 'An error occurred while saving data received from the mobile application'; fa = 'An error occurred while saving data received from the mobile application';
							|it = 'Errore durante la scrittura dei dati ricevuti dall''applicazione mobile';
							|pl = 'Błąd podczas rejestrowania danych otrzymanych z aplikacji mobilnej';
							|tr = 'Mobil uygulamadan alınan veri kaydı hatası'", DefaultLanguageCode),
									EventLogLevel.Error,
									,
									,
									MessageText);
		
		#If ExternalConnection Then
		MessageText = NStr("vi = 'Lỗi ghi lại dữ liệu';
							|ru = 'Ошибка записи данных';
							|en = 'Data saving error'; fa = 'Data saving error';
							|it = 'Errore di scrittura dei dati';
							|pl = 'Błąd zapisu danych';
							|tr = 'Veri kaydı hatası'");
		Raise(MessageText);
		#EndIf
	EndTry;
			
EndProcedure

// Performs a check and returns the result of checking whether the specified version of the mobile app exists.
//
// Parameters:
//  MobileAppName - String - the name of the mobile app to check for the existence of a version of
//  MobileApplicationVersion - String - the version of the mobile app that you want to check for.
//   
// Returns:
//   Boolean - result. True - if the version exists, False - otherwise.
//
Function VersionOfMobileAppExists(MobileAppName, MobileApplicationVersion) Export
	
	SetPrivilegedMode(True);
	
	ApplicationElement_ = MobileApps.GetAppElement(MobileAppName, MobileApplicationVersion);
	
	If ApplicationElement_.IsEmpty() Then
		Return False;
	Else
		Return True;
	EndIf;	
	
EndFunction

// Reflects the fact that the mobile client receives data in the information security system
//
// Parameters:
//  UserName - String - name of the mobile app user to register for receiving data
//  MobileComputerCode - String - code of the mobile computer to register data receipt from
//  DataExchangeParameters - String - XMl string of parameters defined in the mobile app.
//   
Procedure RegisterDataReceipt(UserName, MobileComputerCode, DataExchangeParameters = "") Export
	
	SetPrivilegedMode(True);
	
	ExchangeNode = MobileApps.GetExchangeNodeForMobileConnection(UserName, MobileComputerCode);
	
	NodeObject = ExchangeNode.GetObject();
	
	Try
		
		NodeObject.ReceivedNo = NodeObject.SentNo;
		NodeObject.Write();
		
		ExchangePlans.DeleteChangeRecords(ExchangeNode, NodeObject.SentNo);

	Except
		
		DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
		
		MessageText = ErrorInfo().Description;
		WriteLogEvent(NStr("vi = 'Lỗi khi ghi nhận tiếp nhận dữ liệu từ ứng dụng di động';
							|ru = 'Ошибка при регистрации получения данных от мобильного приложения';
							|en = 'An error occurred while registering data receipt from the mobile application'; fa = 'An error occurred while registering data receipt from the mobile application';
							|it = 'Errore durante la registrazione della ricezione di dati dall''applicazione mobile';
							|pl = 'Błąd podczas rejestracji pobierania danych od aplikacji mobilnej!';
							|tr = 'Mobil uygulamadan veri almak için kayıt oluşturulurken hata oluştu'", DefaultLanguageCode),
									EventLogLevel.Error,
									,
									,
									MessageText);
		
		#If ExternalConnection Then
		MessageText = NStr("vi = 'Lỗi khi ghi nhận việc nhận dữ liệu';
							|ru = 'Ошибка при регистрации получения данных';
							|en = 'An error occurred while registering data receipt'; fa = 'An error occurred while registering data receipt';
							|it = 'Errore durante la registrazione della ricezione dei dati';
							|pl = 'Błąd podczas rejestrowania odbioru danych';
							|tr = 'Veri almak için kayıt oluşturulurken hata oluştu'");
		Raise(MessageText);
		#EndIf
	EndTry;
	
EndProcedure

// Authenticates the mobile user
//
// Parameters:
//  UserName - String - name of the mobile app user to register for receiving data
//  MobileComputerCode - String - code of the mobile computer that is being authenticated
//  UserPassword - String - the password for the mobile user.
//   
// Returns:
//  Boolean - authentication result: True - authentication is performed, False - authentication is not performed.
//
Function Authenticate(UserName, MobileComputerCode, UserPassword) Export
	
	SetPrivilegedMode(True);	
	ExchangeNode = MobileApps.GetExchangeNodeForMobileConnection(UserName, MobileComputerCode);	
	
	Password = Common.ObjectAttributeValue(ExchangeNode, "Password");
	If ExchangeNode.IsEmpty() Or Password <> UserPassword Then
		Return False;
	Else
		Return True;
	EndIf;

EndFunction

#EndRegion

#EndIf
