
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	ImportApplicationFromFile();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
// Loads the application from the specified file.
//
Procedure ImportApplicationFromFile()
	
	#If Not WebClient Then
		
		DialogMode = FileDialogMode.Open;	
		FileDialog = New FileDialog(DialogMode);		
		FileDialog.Title = NStr("vi = 'Chọn tệp để kết nhập';
								|ru = 'Выберите файл для загрузки';
								|en = 'Select a file to import'; fa = 'Select a file to import';
								|it = 'Selezionare un file per l''esportazione';
								|pl = 'Wybierz plik do pobrania';
								|tr = 'Harici dosya seç'");
		FileDialog.Filter = "xml";
		FileDialog.CheckFileExistence = True;
		
		ApplicationName = Undefined;
		VersionNumber = Undefined;
		Application = Undefined;
		UsedMetadata = Undefined;
		
		If FileDialog.Choose() Then
			
			FileName = FileDialog.FullFileName;		
			
			XMLReader = New XMLReader();
			XMLReader.OpenFile(FileName);
			
			Try
				
				If XMLReader.Read() Then
					If XMLReader.NodeType = XMLNodeType.StartElement Then
						If XMLReader.Name <> "MobileApplicationVersionData" Then
							MessageText = NStr("vi = 'Lỗi đọc dữ liệu từ tệp';
												|ru = 'Ошибка чтения данных из файла';
												|en = 'Error reading data from file'; fa = 'Error reading data from file';
												|it = 'Errore di lettura dei dati dal file';
												|pl = 'Błąd odczytu danych z pliku';
												|tr = 'Dosyadan veri okunma sırasında hata'");
							CommonClientServer.MessageToUser(MessageText);
							Return;
						EndIf;	
					EndIf;
				Else
					MessageText = NStr("vi = 'Lỗi đọc dữ liệu từ tệp';
										|ru = 'Ошибка чтения данных из файла';
										|en = 'Error reading data from file'; fa = 'Error reading data from file';
										|it = 'Errore di lettura dei dati dal file';
										|pl = 'Błąd odczytu danych z pliku';
										|tr = 'Dosyadan veri okunma sırasında hata'");
					CommonClientServer.MessageToUser(MessageText);
					Return;
				EndIf;	
				
				CurrentItemName = Undefined;
				
				While XMLReader.Read() Do
					
					If XMLReader.NodeType = XMLNodeType.StartElement Then
						CurrentItemName = XMLReader.Name;
					ElsIf XMLReader.NodeType = XMLNodeType.Text Then
						
						If CurrentItemName = "ApplicationName" Then
							ApplicationName = XMLReader.Value;
						ElsIf CurrentItemName = "Version" Then
							VersionNumber = XMLReader.Value;
						ElsIf CurrentItemName = "Application" Then
							Application = XMLReader.Value;
						ElsIf CurrentItemName = "Metadata" Then
							UsedMetadata = XMLReader.Value;
						EndIf;
						
					EndIf;
					
				EndDo;
				
				If ApplicationName = Undefined Or VersionNumber = Undefined 
					Or Application = Undefined Or UsedMetadata = Undefined Then
					
					MessageText = NStr("vi = 'Tệp có dữ liệu sai';
										|ru = 'Файл содержит некорректные данные';
										|en = 'File contains invalid data'; fa = 'File contains invalid data';
										|it = 'Il file contiene dati incorretti';
										|pl = 'Plik zawiera niepoprawne dane';
										|tr = 'Dosya yanlış veriler içeriyor'");
					CommonClientServer.MessageToUser(MessageText);
					Return;
					
				EndIf;
				
			Except
				
				MessageText = NStr("vi = 'Lỗi đọc dữ liệu từ tệp';
									|ru = 'Ошибка чтения данных из файла';
									|en = 'Error reading data from file'; fa = 'Error reading data from file';
									|it = 'Errore di lettura dei dati dal file';
									|pl = 'Błąd odczytu danych z pliku';
									|tr = 'Dosyadan veri okunma sırasında hata'");
				CommonClientServer.MessageToUser(MessageText);
				
			EndTry;
			
			XMLReader.Close();
			
			ApplicationStructure = ApplicationDescriptionServer(ApplicationName, VersionNumber);
			
			If ApplicationStructure.Version <> Undefined Then
				
				QueryText = NStr("vi = 'Phiên bản được kết nhập đã tồn tại (%ApplicationName%, phiên bản %VersionNumber% ). Thay thế?';
								|ru = 'Загружаемая версия уже существует (%ApplicationName%, версия %VersionNumber% ). Заменить?';
								|en = 'The version being imported already exists (%ApplicationName%, version %VersionNumber% ). Do you want to overwrite it?'; fa = 'The version being imported already exists (%ApplicationName%, version %VersionNumber% ). Do you want to overwrite it?';
								|it = 'La versione che si sta tentando di caricare esiste già (%ApplicationName%, versione %VersionNumber%). Sostituirla?';
								|pl = 'Pobierana wersja już istnieje (%ApplicationName%, wersja %VersionNumber% ). Zastąpić?';
								|tr = 'İndirilen sürüm artık mevcut (%ApplicationName%, sürüm %VersionNumber% ). Değiştir?'");
				QueryText = StrReplace(QueryText, "%ApplicationName%", ApplicationName);
				QueryText = StrReplace(QueryText, "%VersionNumber%", TrimR(VersionNumber));
				
				ParametersStructure = New Structure;
				ParametersStructure.Insert("ApplicationName", ApplicationName);
				ParametersStructure.Insert("VersionNumber", VersionNumber);
				ParametersStructure.Insert("Application", Application);
				ParametersStructure.Insert("UsedMetadata", UsedMetadata);
				ParametersStructure.Insert("ApplicationStructure", ApplicationStructure);
				
				CallbackDescription = New CallbackDescription("ImportApplicationFromFileCompletion", ThisObject, ParametersStructure);
				ShowQueryBox(CallbackDescription, QueryText,QuestionDialogMode.YesNo);
				
			Else
				ProcessApplicationEntry(ApplicationName, VersionNumber, Application, UsedMetadata, ApplicationStructure);
			EndIf;
			
		EndIf;
		
	#EndIf
	
EndProcedure

&AtClient
// Completes the download of the application from the specified file.
//
// Parameters:
//  The result of the question is the result of the answer to the question.
//  Additional parameters - A structure with additional parameters.
//
Procedure ImportApplicationFromFileCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	
	If UserAnswer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ProcessApplicationEntry(AdditionalParameters.ApplicationName,
							   AdditionalParameters.VersionNumber,
							   AdditionalParameters.Application,
							   AdditionalParameters.UsedMetadata,
							   AdditionalParameters.ApplicationStructure);
	
EndProcedure

&AtClient
Procedure ProcessApplicationEntry(ApplicationName, VersionNumber, Application, UsedMetadata, ApplicationStructure)
	
	WriteAppServer(ApplicationName, VersionNumber, Application, UsedMetadata, ApplicationStructure);
	
	NotifyChanged(Type("CatalogRef.MobileApplicationsVersions"));
	
	MessageText = NStr("vi = 'Ứng dụng đã kết nhập';
						|ru = 'Приложение загружено';
						|en = 'Application is imported'; fa = 'Application is imported';
						|it = 'Applicazione caricata';
						|pl = 'Aplikacja została pobrana';
						|tr = 'Uygulama indirildi'");
	ShowUserNotification("",,MessageText);
	
EndProcedure

&AtServer
Function ApplicationDescriptionServer(ApplicationName, VersionNumber)
	
	Return MobileApps.ApplicationDescription(ApplicationName, VersionNumber);

EndFunction

&AtServer
Procedure WriteAppServer(ApplicationName, VersionNumber, Application, UsedMetadata, ApplicationStructure)
	
	MobileApps.WriteApp(ApplicationName, VersionNumber, Application, UsedMetadata, ApplicationStructure);

EndProcedure

#EndRegion
