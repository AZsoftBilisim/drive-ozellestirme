#If Not WebClient Then
	
#Region Variables

&AtClient
Var TestApplication, WindowsKernel;

&AtClient
Var CacheOfCheckedWindowsForModality;

&AtClient
Var ExternalComponentForScreenshots Export;

&AtClient
Var LocationOfExternalComponentForScreenshots;

&AtClient
Var DescriptorOfMainWindowOfCurrentTestingClient;

&AtClient
Var PIDCurCurrentTestingClient;

#EndRegion

#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	If OpeningMode = "GettingScreenshots" Then
		
		InitializeDataOnClient();
		
	ElsIf ExternalComponentScreenshotsExists Then
		
		ConnectExternalComponent();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InitializeTheForm();
	
	DemoScenarios.ResetWindowLocationAndSize(ThisObject);
	
	ProcessPassedParameters();
	
EndProcedure 

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationHowToConnectComponentURLProcessing(Item, FormattedStringURL, StandardProcessing)

	If FormattedStringURL = "e1cib/list/Catalog.AddIns" Then
		
		ComponentID = "WindowsControl";
		
		HTMLDocument = Items.HTMLForCopying.Document;
		TemporaryInputField = HTMLDocument.createElement("INPUT");
		ActiveItem = HTMLDocument.activeElement;
		TemporaryInputField.value = ComponentID;
		HTMLDocument.body.appendChild(TemporaryInputField);
		TemporaryInputField.select();
		HTMLDocument.execCommand("copy");
		HTMLDocument.body.removeChild(TemporaryInputField);
		ActiveItem.focus();
		
		MessageText = StrTemplate(NStr("vi = 'Tên định danh cấu phần ""%1"" nằm trong bộ nhớ đệm.';
										|ru = 'Идентификатор компоненты ""%1"" помещен в буфер обмена.';
										|en = 'The ""%1"" add-in ID is saved to the clipboard.'; fa = 'The ""%1"" add-in ID is saved to the clipboard.';
										|it = 'Идентификатор компоненты ""%1"" помещен в буфер обмена.';
										|pl = 'The ""%1"" add-in ID is saved to the clipboard.';
										|tr = '""%1"" eklenti kimliği panoya yerleştirildi.'"), ComponentID);
		ShowUserNotification(,,MessageText,PictureLib.MediumGreenCheckBox);
		
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ConnectTestingClient()
	
	BreakTestClientConnection();
	
	If ResultOfConnectingAlreadyRunningTestClient() Then
		
		If OpeningMode = "ConnectionSettings" Then
			
			NotificationText1 = NStr("vi = 'Đã kết nối client thử nghiệm đang chạy.';
									|ru = 'Подключен уже запущенный клиент тестирования.';
									|en = 'An already running test client is connected.'; fa = 'An already running test client is connected.';
									|it = 'Подключен уже запущенный клиент тестирования.';
									|pl = 'An already running test client is connected.';
									|tr = 'Zaten çalışan bir test istemcisi bağlı.'");
			CloseAfterSuccessfulConnection();
			
		Else
			
			AddlParameters = New Structure;
			AddlParameters.Insert("ExistingSessionIsConnected", True);
			FillInPidHandleOfTestingClientWindow(TestClientLaunchData(), AddlParameters);
			
		EndIf;
		
		Return;
		
	EndIf;
	
	LaunchAndConnectTestingClient();
	
EndProcedure 

#EndRegion

#Region Private

#Region InitializeForm

&AtClient
Procedure InitializeDataOnClient()

	CacheOfCheckedWindowsForModality = New Map; 
	
	ConnectExternalComponent();

EndProcedure

&AtServer
Procedure ProcessPassedParameters()

	TestingClientPortNumber        = Parameters.TestingClientPortNumber;
	TestClientConnectionString = Parameters.TestClientConnectionString;
	TestClientStartupTimeout   = Parameters.TestClientStartupTimeout;
	OpeningMode                       = Parameters.OpeningMode; 
	IdOfOwnerSForm         = Parameters.IdOfOwnerSForm;
	DirectoryName                         = Parameters.DirectoryName;
	
	If TestingClientPortNumber = 0 Then
		TestingClientPortNumber = 48123;
	EndIf; 
	
	If Not IsBlankString(TestClientConnectionString) Then
		
		TestClientConnectionString = InfoBaseConnectionString();
		
		If IsFileInfobase Then
			
			TestClientConnectionString = Mid(TestClientConnectionString, 7, StrLen(TestClientConnectionString) - 8);
			
		EndIf;
		
	EndIf;
	
	If OpeningMode = "ConnectionSettings" Then
		
		Items.FormPages.CurrentPage = Items.ConnectionSettingsPage;
		
	ElsIf OpeningMode = "GettingScreenshots" Then
		
		Items.FormPages.CurrentPage = Items.GettingScreenshotsPage;
		
		FillInTableOfNavigationLinks(Parameters.DataForGettingScreenshots);
		
		Items.DecorationTextWaitingToReceiveScreenshots.Title = NStr("vi = 'Đang nhận ảnh chụp màn hình. Xin vui lòng đợi...';
																	|ru = 'Выполняется получение скриншотов. Пожалуйста подождите....';
																	|en = 'Receiving screenshots. Please wait…'; fa = 'Receiving screenshots. Please wait…';
																	|it = 'Выполняется получение скриншотов. Пожалуйста подождите....';
																	|pl = 'Receiving screenshots. Please wait…';
																	|tr = 'Ekran görüntüleri alınıyor. Lütfen bekleyin....'");
		
		Title = NStr("vi = 'Nhận ảnh chụp màn hình';
					|ru = 'Получение скриншотов';
					|en = 'Get screenshots'; fa = 'Get screenshots';
					|it = 'Получение скриншотов';
					|pl = 'Get screenshots';
					|tr = 'Ekran görüntülerinin alınması'");
		
	EndIf;

EndProcedure 

&AtServer
Procedure FillInTableOfNavigationLinks(NavigationLinkData) 
	
	MatchNames = New Array;
	MatchNames.Add("Commands");
	MatchNames.Add("ObjectsRefs");
	MatchNames.Add("Lists"); 
	
	For Each ArrayElement In MatchNames Do
		
		For Each DataOfNavigationLink In Parameters.DataForGettingScreenshots[ArrayElement] Do
		
			AddRowToNavigationLinkTable(DataOfNavigationLink, ArrayElement);
		
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure AddRowToNavigationLinkTable(DataOfNavigationLink, RefType)
	
	NewRow = NavigationLinks.Add(); 
	
	NewRow.URL = DataOfNavigationLink.Key;
	NewRow.ObjectReference      = DataOfNavigationLink.Value.LinkToInformationSecurityObject; 
	NewRow.HashOfLink           = DataOfNavigationLink.Value.HashOfLink;
	NewRow.RefType           = RefType;
	
	For Each ScenarioData In DataOfNavigationLink.Value.BudgetingScenarios Do
	
		NewLineScripts = NewRow.BudgetingScenarios.Add();
		NewLineScripts.Scenario            = ScenarioData.Scenario;
		NewLineScripts.LanguageCode            = ScenarioData.LanguageCode;
		NewLineScripts.RowID = ScenarioData.RowID; 
	
	EndDo;
	
EndProcedure

&AtServer
Procedure InitializeTheForm()
	
	Object.AdditionalParameters = New Structure;
	
	ColorHyperlink = StyleColors.HyperlinkColor;
	
	AddInInformation = AddInServerCall.AddInInformation(DemoScenariosClientServer.IdOfExternalComponentForGettingScreenshots());
	
	If Not AddInInformation.Exists Then
		
		Array = New Array;
		Array.Add(StrTemplate(NStr("vi = 'Kiểm tra cấu phần nhận ảnh chụp màn hình: %1';
									|ru = 'Проверка компоненты получения скриншотов: %1';
									|en = 'Check screenshot receiving add-in: %1'; fa = 'Check screenshot receiving add-in: %1';
									|it = 'Проверка компоненты получения скриншотов: %1';
									|pl = 'Check screenshot receiving add-in: %1';
									|tr = 'Ekran görüntüsü alma eklentilerinin kontrolü: %1'"), AddInInformation.ErrorDescription));
		
		Items.DecorationVersionComponents.Title = New FormattedString(Array,, StyleColors.ErrorNoteText); 
		
		Items.DecorationHowToConnectComponent.Visible = True;
		
		Width = 50;
		Height = 17;
		
	Else
		
		Items.DecorationHowToConnectComponent.Visible = False;
		ExternalComponentScreenshotsExists = True; 
		
		Width = 50;
		Height = 10;
		
	EndIf;
	
	IsFileInfobase = Common.FileInfobase();
	
	If IsFileInfobase Then
		
		Items.TestClientConnectionString.Title = NStr("vi = 'Thư mục cơ sở thông tin';
														|ru = 'Каталог информационной базы';
														|en = 'Infobase directory'; fa = 'پوشه پایگاه اطلاعات';
														|it = 'Catalogo della base informativa';
														|pl = 'Katalog bazy informacyjnej';
														|tr = 'Infobase kataloğu'");
		Items.TestClientConnectionString.InputHint = StrTemplate(NStr("vi = 'Ví dụ: %1';
																		|ru = 'Например: %1';
																		|en = 'For example: %1'; fa = 'For example: %1';
																		|it = 'Например: %1';
																		|pl = 'For example: %1';
																		|tr = 'Örneğin: %1'"), "C:\Bases\MyBase");
		
	Else
		
		Items.TestClientConnectionString.Title = NStr("vi = 'Dòng kết nối CSTT';
														|ru = 'Строка соединения ИБ';
														|en = 'Infobase connection string'; fa = 'Infobase connection string';
														|it = 'Строка соединения ИБ';
														|pl = 'Infobase connection string';
														|tr = 'Infobase bağlantı dizesi'");
		Items.TestClientConnectionString.InputHint = StrTemplate(NStr("vi = 'Ví dụ: %1';
																		|ru = 'Например: %1';
																		|en = 'For example: %1'; fa = 'For example: %1';
																		|it = 'Например: %1';
																		|pl = 'For example: %1';
																		|tr = 'Örneğin: %1'"), "Srvr=""IntServer"";Ref=""MyBase""");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region PageTree

&AtClient
Procedure DisplayProcessingProgress(DataForOutputOfProgress)
	
	DataForOutputOfProgress.Processed = DataForOutputOfProgress.Processed + 1;
	ExecutionProgress                  = (DataForOutputOfProgress.Processed / DataForOutputOfProgress.ToProcessing) * 100;
	RefreshDataRepresentation(Items.ExecutionProgress);
	
EndProcedure

&AtClient
Function NewDataToDisplayProgress()

	ProgressData = New Structure;
	ProgressData.Insert("Processed", 0);
	ProgressData.Insert("ToProcessing", 0);
	
	Return ProgressData;

EndFunction

&AtClientAtServerNoContext
Function SearchResultInTreeFormData(WhereToFind,Value,Column,SearchSubordinateItems)
	
	TreeItems = WhereToFind.GetItems();
	
	For Each TreeItem In TreeItems Do
		If TreeItem[Column] = Value Then
			Return TreeItem.GetID();
		ElsIf  SearchSubordinateItems Then
			FoundRowID1 =  SearchResultInTreeFormData(TreeItem,Value,Column,SearchSubordinateItems);
			If FoundRowID1 >=0 Then
				Return FoundRowID1;
			EndIf;
		EndIf;
		
	EndDo;
	
	Return -1;
	
EndFunction

&AtClient
Function DataOfFormBeingOpened(Var_URL)
	
	Result = New Structure;
	Result.Insert("DataOfPage", New Array);
	Result.Insert("Title",     "");
	Result.Insert("CurrentForm",  "");
	Result.Insert("Success",       True);
	
	OpeningResult = ResultOfOpeningWindowUsingNavigationLink(Var_URL);
	
	If Not OpeningResult.Success Then
		
		Result.Success = False;
		Return Result;
	
	ElsIf OpeningResult.CurrentWindow = Undefined 
		Or TypeOf(OpeningResult.CurrentWindow) <> Type("TestedClientApplicationWindow") Then
		
		OpeningResult.Success = False;
		Return Undefined;
		
	ElsIf ThisIsTitleOfModalDialogWindow(OpeningResult.CurrentWindow.Caption) Then
	
		If ThisIsFormOfError(OpeningResult.CurrentForm) Then
			
			OpeningResult.Success = False;
			Result.Success = False;
			Return Result;
			
		EndIf;
		
	Else 
		
		Result.CurrentForm = OpeningResult.CurrentForm;
		
		Result.Title = OpeningResult.CurrentForm.TitleText;
		
		SubordinateObjects = OpeningResult.CurrentForm.GetChildObjects(); 
		
		For Each SubordinateObject In SubordinateObjects Do // TestedFormGroup
			
			If TypeOf(SubordinateObject) <> Type("TestedFormGroup") Then
				
				Continue;
				
			EndIf;
			
			If SubordinateObject.Type = FormGroupType.Pages Then
				
				SubordinatePageObjects = SubordinateObject.GetChildObjects();
				
				For Each SubordinateObjectPage In SubordinatePageObjects Do 
					
					If Not SubordinateObjectPage.CurrentEnable() 
						Or Not SubordinateObjectPage.CurrentVisible() Then
						
						Continue;
						
					EndIf;
					
					PageData_ = NewPageData();
					PageData_.Title = SubordinateObjectPage.TitleText;
					PageData_.Name =       SubordinateObjectPage.Name;
					
					Result.DataOfPage.Add(PageData_);
					
				EndDo;
				
			ElsIf SubordinateObject.Type = FormGroupType.UsualGroup Then 
				
				SubordinateObjectsSecondLevel = SubordinateObject.GetChildObjects(); 
				
				For Each SubordinateObjectIsSecondLevel In SubordinateObjectsSecondLevel Do // TestedFormGroup
					
					If TypeOf(SubordinateObjectIsSecondLevel) <> Type("TestedFormGroup") Then
						
						Continue;
						
					EndIf;
					
					If SubordinateObjectIsSecondLevel.Type = FormGroupType.Pages Then
						
						SubordinatePageObjects = SubordinateObjectIsSecondLevel.GetChildObjects();
						
						For Each SubordinateObjectPage In SubordinatePageObjects Do
							
							If Not SubordinateObjectPage.CurrentVisible() 
								Or Not SubordinateObjectPage.CurrentEnable() Then
								
								Continue;
								
							EndIf;
							
							PageData_ = NewPageData();
							PageData_.Title       = SubordinateObjectPage.TitleText;
							PageData_.GroupTitle = SubordinateObject.TitleText;
							Result.DataOfPage.Add(PageData_);
							
						EndDo
						
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Result;

EndFunction 

&AtClient
Function NewPageData()

	PageData_ = New Structure;
	
	PageData_.Insert("Title",       "");
	PageData_.Insert("GroupTitle", "");
	PageData_.Insert("Name",             "");
	PageData_.Insert("Path",            "");
	
	Return PageData_;
	
EndFunction

#EndRegion

#Region TestingClientConnections

&AtClient
Function ResultOfConnectingAlreadyRunningTestClient()
	
	#If Not MobileClient Then
	
	Try
		TestApplication = New TestedApplication(,TestingClientPortNumber);
		TestApplication.Connect();
		IsConnectionEstablished = True;
		Return True;
	Except
		Return False;
	EndTry; 
	
	#EndIf
	
EndFunction

&AtClient
Procedure BreakTestClientConnection()
	
	If TestApplication = Undefined Then
		Return;
	EndIf;
	
	Try
		TestApplication.Disconnect();
	Except
		Return;
	EndTry;
	
EndProcedure

&AtClient
Procedure LaunchAndConnectTestingClient()
	
	UserSubmitted = False;
	If ValueIsFilled(TestClientConnectionString) Then
		ConnectionString = TestClientConnectionString;
		If Find(ConnectionString, " /N") > 0 Then
			UserSubmitted = True;
		EndIf;
	Else
		ConnectionString = StrReplace(InfoBaseConnectionString(),"""","""""");
	EndIf;
	
	If IsFileInfobase Then
		ConnectionString = " /F " +  """" + ConnectionString + """";
	Else 
		ConnectionString = StrReplace(ConnectionString, "Srvr=", "/S");
		ConnectionString = StrReplace(ConnectionString, """;Ref=""", "\");
	EndIf;
	
	CommandLine1 = "ENTERPRISE  "
		+ ConnectionString
		+ " /AllowExecuteScheduledJobs -Off"
		+ " /TESTCLIENT -TPort " + Format(TestingClientPortNumber, "NG=; NZ=0");
		
	If ValueIsFilled(UserName()) And Not UserSubmitted Then
		CommandLine1 = CommandLine1 + " /N """ + UserName() + """";
	EndIf;
	
	_1CStartupLine = BinDir() + "1cv8c";
	
	If Not IsLinux() Then
		_1CStartupLine = "start /max """" """ + _1CStartupLine  + """ " + CommandLine1;
		
		ExecuteFACommandWithoutShowingBlackWindow(_1CStartupLine, 0);
	Else
		CommandLine1 = _1CStartupLine + " " + CommandLine1 + " &";
		FileSystemClient.StartApplication(CommandLine1);
	EndIf;
	
	InstallConnectTestClient(); 
	
EndProcedure

#EndRegion

#Region TestingClientWindows

// The active window from the test application.
// 
// Returns:
//  TestedClientApplicationWindow -
&AtClient
Function ActiveWindowFromTestApplication()
	
	Return TestApplication.GetActiveWindow();
	
EndFunction

// The result of opening the window using the navigation link.
// 
// Parameters:
//  Var_URL - String - Navigation links
// 
// Returns:
//  Structure - The Result Of Opening The Window Using The Navigation Link:
// * CurrentWindow - Undefined, TestedClientApplicationWindow - 
// * CurrentForm - Undefined, TestedForm - 
// * Success - Boolean - 
&AtClient
Function ResultOfOpeningWindowUsingNavigationLink(Var_URL)
	
	OpeningResult = New Structure;
	OpeningResult.Insert("CurrentWindow",  Undefined);
	OpeningResult.Insert("CurrentForm", Undefined);
	OpeningResult.Insert("Success",      True);
	
	CommonClient.MessageToUser(StrTemplate(NStr("vi = 'Mở liên kết %1';
												|ru = 'Открываем ссылку %1';
												|en = 'Open the %1 link'; fa = 'Open the %1 link';
												|it = 'Открываем ссылку %1';
												|pl = 'Open the %1 link';
												|tr = '%1 bağlantısını açalım'"), Var_URL));
	
	Try
	
		CloseAllTestingClientWindows();
		
		MainWindow = MainWindowOfTest();
		CurrentWindow = ActiveWindowFromTestApplication();
		MainWindow.ExecuteCommand(Var_URL);

		WaitingForWindowChange(CurrentWindow);
		
		OpeningResult.CurrentWindow = ActiveWindowFromTestApplication();
		OpeningResult.CurrentForm = RealFormFromWindow(OpeningResult.CurrentWindow);
	
	Except
		
		OpeningResult.Success = False;
		
	EndTry;
	
	Return OpeningResult;
	
EndFunction 

// Close all windows of the testing client.
// 
// Parameters:
//  ExceptionWindow - Undefined, TestedClientApplicationWindow - 
//  FormOfWindowIsException - Undefined, TestedForm - 
//  TryingToPressOtherButtons - Boolean - 
//  AsterixSymbolIsConsideredAnotherWindow - Boolean - 
&AtClient
Procedure CloseAllTestingClientWindows(ExceptionWindow = Undefined, FormOfWindowIsException = Undefined, TryingToPressOtherButtons = True, AsterixSymbolIsConsideredAnotherWindow = True)
	
	CurrentWindow = ActiveWindowFromTestApplication();
	Counter = 0;
	While ThisIsWindowOfLongOfOperation(CurrentWindow) Do
		PerformInactivity(1);
		CurrentWindow = ActiveWindowFromTestApplication();
		Counter = Counter + 1;
		If Counter > 100 Then
			Break;
		EndIf;
	EndDo;
	
	ItTurnedOutToCloseAllModalDialogs = False;
	
	For Counter = 1 To 5 Do
		ModalDialogWasFound = False;
		CloseModalDialogIfThereIsOne(ModalDialogWasFound);
		If Not ModalDialogWasFound Then
			ItTurnedOutToCloseAllModalDialogs = True;
			Break;
		Else
			PerformInactivity(1);
		EndIf;
	EndDo;

	If Not ItTurnedOutToCloseAllModalDialogs Then
		CommonClient.MessageToUser(NStr("vi = 'Không thể đóng cửa sổ phương thức.';
										|ru = 'Не получилось закрыть модальный диалог.';
										|en = 'Cannot close the modal dialog box.'; fa = 'Cannot close the modal dialog box.';
										|it = 'Не получилось закрыть модальный диалог.';
										|pl = 'Cannot close the modal dialog box.';
										|tr = 'Kalıcı iletişim kutusu kapatılamadı.'"));
	EndIf;
	
	NumberOfAttemptsToCloseWindows = 1;
	
	For Cnt = 1 To NumberOfAttemptsToCloseWindows Do
		
		ThereWasAttemptToCloseWindows = False;
		AddlParameters = New Structure;
		AddlParameters.Insert("ThereWasAttemptToCloseWindows",           ThereWasAttemptToCloseWindows);
		AddlParameters.Insert("ExceptionWindow",                    ExceptionWindow);
		AddlParameters.Insert("FormOfWindowIsException",               FormOfWindowIsException);
		AddlParameters.Insert("AsterixSymbolIsConsideredAnotherWindow",  AsterixSymbolIsConsideredAnotherWindow);
		AddlParameters.Insert("PauseAfterClosingWindow",            1);
		CloseOpenWindows(AddlParameters);
		
		ThereWasAttemptToCloseWindows = AddlParameters.ThereWasAttemptToCloseWindows;
		If Not ThereWasAttemptToCloseWindows Then
			Break;
		EndIf;
		
	EndDo;
	
	CurrentWindow        = ActiveWindowFromTestApplication();
	ThisWindowShouldBeClosed = ThisWindowShouldBeClosed(CurrentWindow, ExceptionWindow, AsterixSymbolIsConsideredAnotherWindow);
	If ThisWindowShouldBeClosed Then

		Try
			FormWindow = CurrentWindow.FindObject(Type("TestedForm"));
			FormWindow.GotoNextItem();
		Except
			Return;
		EndTry;
		
		Try
			FormWindow.ExecuteChoiceFromList(0);
		Except 
			Return;
		EndTry;
		
		For Cnt = 1 To NumberOfAttemptsToCloseWindows Do
			
			ThereWasAttemptToCloseWindows = False;
			AddlParameters.Insert("ThereWasAttemptToCloseWindows",           ThereWasAttemptToCloseWindows);
			AddlParameters.Insert("ExceptionWindow",                    ExceptionWindow);
			AddlParameters.Insert("FormOfWindowIsException",               FormOfWindowIsException);
			AddlParameters.Insert("AsterixSymbolIsConsideredAnotherWindow",  True);
			AddlParameters.Insert("PauseAfterClosingWindow",            3);
			
			CloseOpenWindows(AddlParameters);
			
			ThereWasAttemptToCloseWindows = AddlParameters.ThereWasAttemptToCloseWindows;
			If Not ThereWasAttemptToCloseWindows Then
				Break;
			EndIf;
			
		EndDo;
	EndIf;
	
	CurWindow = ActiveWindowFromTestApplication();
	ThisWindowShouldBeClosed = ThisWindowShouldBeClosed(CurWindow, ExceptionWindow, AsterixSymbolIsConsideredAnotherWindow);
	
	If ThisWindowShouldBeClosed Then
		
				If TryingToPressOtherButtons Then
			If Not ItTurnedOutToCloseWindowThroughOtherButtons(CurWindow) Then
				Raise NStr("vi = 'Không thể đóng tất cả cửa sổ.';
							|ru = 'Не получилось закрыть все окна.';
							|en = 'Cannot close all windows.'; fa = 'Cannot close all windows.';
							|it = 'Не получилось закрыть все окна.';
							|pl = 'Cannot close all windows.';
							|tr = 'Tüm pencereler kapatılamadı.'");
			Else
				CloseAllTestingClientWindows(ExceptionWindow, FormOfWindowIsException, False);
			EndIf;
		Else	
			Raise NStr("vi = 'Không thể đóng tất cả cửa sổ.';
						|ru = 'Не получилось закрыть все окна.';
						|en = 'Cannot close all windows.'; fa = 'Cannot close all windows.';
						|it = 'Не получилось закрыть все окна.';
						|pl = 'Cannot close all windows.';
						|tr = 'Tüm pencereler kapatılamadı.'");
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseOpenWindows(AddlParameters) 
	
	ThereWasAttemptToCloseWindows = AddlParameters.ThereWasAttemptToCloseWindows;
	ExceptionWindow                    = AddlParameters.ExceptionWindow;
	FormOfWindowIsException               = AddlParameters.FormOfWindowIsException;
	AsterixSymbolIsConsideredAnotherWindow  = AddlParameters.AsterixSymbolIsConsideredAnotherWindow;
	PauseAfterClosingWindow            = AddlParameters.PauseAfterClosingWindow;
	
	Try
		ApplicationWindows = TestApplication.FindObjects(Type("TestedClientApplicationWindow"));
	Except
		Return;
	EndTry;
	
	ProblematicWindows = New Array;
	ProblematicWindows2 = New Array;
	
	For Counter = 0 To ApplicationWindows.Count()-1 Do
		WeMustContinue = False;
		
		WindowApplication = ApplicationWindows[ApplicationWindows.Count() - 1 - Counter];
	
		If WindowApplication.IsMain Then
			Continue;
		EndIf;
		
		If WindowApplication.HomePage Then
			Continue;
		EndIf;
		
		Try
			FormWindow = WindowApplication.FindObject(Type("TestedForm"));
		Except
			FormWindow = Undefined;
		EndTry;
		
		If ExceptionWindow <> Undefined And WindowApplication.Title = ExceptionWindow.Caption Then
			WeMustContinue = True;
		EndIf;
		
		If Not WeMustContinue And ExceptionWindow <> Undefined And Not AsterixSymbolIsConsideredAnotherWindow Then
			If Right(WindowApplication.Title, 1) = "*" Then
				StringToCheck = Left(WindowApplication.Title, StrLen(WindowApplication.Title) - 2);
				If StringToCheck = ExceptionWindow.Caption Then
					WeMustContinue = True;
				EndIf;
			EndIf;
		EndIf;
		
		If WeMustContinue And FormOfWindowIsException <> Undefined Then
			If FormWindow <> Undefined And FormOfWindowIsException.FormName <> FormWindow.FormName Then
				WeMustContinue = False;
			EndIf;
		EndIf;
		
		If WeMustContinue Then
			Continue;
		EndIf;
		
		If FormWindow <> Undefined Then
			Lower_FormName = Lower(FormWindow.FormName);
			If Lower_FormName = Lower("CommonForm.DoQueryBox") Then
			ElsIf Lower_FormName = Lower("DataProcessor.ApplicationUpdateResult.Form.DeferredUpdateNotCompleted") Then
				MessageText = NStr("vi = 'Chưa thực hiện thủ tục xử lý dữ liệu bổ sung.';
									|ru = 'Не выполнены дополнительные процедуры обработки данных.';
									|en = 'Additional data processing skipped'; fa = 'Additional data processing skipped';
									|it = 'Не выполнены дополнительные процедуры обработки данных.';
									|pl = 'Additional data processing skipped';
									|tr = 'Ek veri işleme prosedürleri uygulanmadı.'");
				Raise MessageText;
			ElsIf Lower_FormName = Lower("DataProcessor.ApplicationUpdateResult.Form.IBUpdateProgressIndicator") Then
				MessageText = NStr("vi = 'Đã tìm thấy cửa sổ cập nhật cấu hình.';
									|ru = 'Обнаружено окно обновления конфигурации.';
									|en = 'A configuration update window is found.'; fa = 'A configuration update window is found.';
									|it = 'Обнаружено окно обновления конфигурации.';
									|pl = 'A configuration update window is found.';
									|tr = 'Konfigürasyon güncellemesi penceresi tespit edildi.'");
				Raise MessageText;
			ElsIf Lower_FormName = Lower("DataProcessor.ApplicationUpdateResult.Form.FailedUpdateMessage") Then
				MessageText = NStr("vi = 'Đã tìm thấy cửa sổ thông báo cập nhật cấu hình thất bại.';
									|ru = 'Обнаружено окно c сообщением о неудачном обновлением конфигурации.';
									|en = 'A window with a message about an unsuccessful configuration update is found.'; fa = 'A window with a message about an unsuccessful configuration update is found.';
									|it = 'Обнаружено окно c сообщением о неудачном обновлением конфигурации.';
									|pl = 'A window with a message about an unsuccessful configuration update is found.';
									|tr = 'Başarısız konfigürasyon güncellemesi hakkında mesaj içeren pencere tespit edildi.'");
				Raise MessageText;
			ElsIf Lower_FormName = Lower("DataProcessor.ApplicationUpdateResult.Form.FailedUpdateMessage") Then
				ContinueButton = FormWindow.FindObject(Type("TestedFormButton"),,"ContinueWorkingWithCurrentVersion");
				Try
					ThereWasAttemptToCloseWindows = True;
					ContinueButton.Click();
					PerformInactivity(1);
				Except
					MessageText = NStr("vi = 'Đã tìm thấy cửa sổ chuyển sang phiên bản mới của chương trình 1C:Enterprise.';
										|ru = 'Обнаружено окно перехода на новую версию программы 1С:Предприятие.';
										|en = 'A window for migrating to a new 1C:Enterprise version is found.'; fa = 'A window for migrating to a new 1C:Enterprise version is found.';
										|it = 'Обнаружено окно перехода на новую версию программы 1С:Предприятие.';
										|pl = 'A window for migrating to a new 1C:Enterprise version is found.';
										|tr = '1C:Enterprise programının yeni sürümüne geçiş penceresi tespit edildi.'");
					Raise MessageText;
				EndTry;
			ElsIf Lower_FormName = Lower("CommonForm.RegionalSettings") Then 
				OKButton = FormWindow.FindObject(Type("TestedFormButton"),,"OK");
				Try
					ThereWasAttemptToCloseWindows = True;
					OKButton.Click();
				Except
					MessageText = NStr("vi = 'Không thể nhấn <Đồng ý> trong cửa sổ tùy chỉnh theo khu vực.';
										|ru = 'Не удалось нажать <ОК> в окне региональных настроек.';
										|en = 'Cannot click <OK> in the regional settings window.'; fa = 'Cannot click <OK> in the regional settings window.';
										|it = 'Не удалось нажать <ОК> в окне региональных настроек.';
										|pl = 'Cannot click <OK> in the regional settings window.';
										|tr = 'Bölgesel ayarlar penceresinde <Tamam> tuşuna tıklanamadı.'");
					Raise MessageText;
				EndTry;
				If FormWindow.WaitForClosing() Then
					Continue;
				Else
					MessageText = NStr("vi = 'Không thể đợi đóng cửa sổ tùy chỉnh theo khu vực';
										|ru = 'Не удалось дождаться закрытия окна региональных настроек';
										|en = 'Cannot wait for the regional settings window to close'; fa = 'Cannot wait for the regional settings window to close';
										|it = 'Не удалось дождаться закрытия окна региональных настроек';
										|pl = 'Cannot wait for the regional settings window to close';
										|tr = 'Bölgesel ayarlar penceresinin kapanması beklenemedi'");
					Raise MessageText;
				EndIf;
			EndIf; 
		EndIf; 
		
		Try
			
			ThereWasAttemptToCloseWindows = True;
			WindowApplication.Close();
			
		Except
			ProblematicWindows.Add(WindowApplication);
			MessageText = NStr("vi = 'Không thể đóng cửa sổ %1';
								|ru = 'Не удалось закрыть окно %1';
								|en = 'Cannot close the %1 window'; fa = 'Cannot close the %1 window';
								|it = 'Не удалось закрыть окно %1';
								|pl = 'Cannot close the %1 window';
								|tr = '%1 penceresi kapatılamadı'");
			MessageText = StrReplace(MessageText,"%1",WindowApplication.Title); 
		EndTry;
		
		PerformInactivity(PauseAfterClosingWindow); 
		
		CloseModalDialogIfThereIsOne();
		
	EndDo;
	
	WindowApplication = Undefined;
	//let's try to close the problematic windows again
	For Each WindowApplication In ProblematicWindows Do
		Try
			ThereWasAttemptToCloseWindows = True;
			WindowApplication.Close();
		Except
			ProblematicWindows2.Add(WindowApplication); 
			MessageText = NStr("vi = 'Không thể đóng lại cửa sổ %1';
								|ru = 'Не удалось закрыть повторно окно %1';
								|en = 'Cannot close the %1 window again'; fa = 'Cannot close the %1 window again';
								|it = 'Не удалось закрыть повторно окно %1';
								|pl = 'Cannot close the %1 window again';
								|tr = '%1 penceresi tekrar kapatılamadı'");
			MessageText = StrReplace(MessageText,"%1",WindowApplication.Title); 
		EndTry;
		
		PerformInactivity(PauseAfterClosingWindow);
		CloseModalDialogIfThereIsOne();//the dialog could appear when the window is closed.
	EndDo;
	
	WindowApplication = Undefined;
	//let's try to close the problematic windows again
	For Each WindowApplication In ProblematicWindows2 Do
		Try
			FoundCancelButton = False;
			CancelButton = WindowApplication.FindObject(Type("TestedFormButton"),"Cancel*");	
			If CancelButton <> Undefined Then
				Try
					ThereWasAttemptToCloseWindows = True;
					CancelButton.Click();
					FoundCancelButton = True;
				Except 
					FoundCancelButton = False;
				EndTry;
			EndIf;
			
			If Not FoundCancelButton Then
				ThereWasAttemptToCloseWindows = True;
				WindowApplication.Close();
			EndIf;
		Except
			MessageText = NStr("vi = 'Không thể đóng lại cửa sổ %1';
								|ru = 'Не удалось закрыть повторно окно %1';
								|en = 'Cannot close the %1 window again'; fa = 'Cannot close the %1 window again';
								|it = 'Не удалось закрыть повторно окно %1';
								|pl = 'Cannot close the %1 window again';
								|tr = '%1 penceresi tekrar kapatılamadı'");
			MessageText = StrReplace(MessageText,"%1",WindowApplication.Title); 
		EndTry;
		
		PerformInactivity(PauseAfterClosingWindow);
		CloseModalDialogIfThereIsOne();//the dialog could appear when the window is closed.
	EndDo;
	
	If ThereWasAttemptToCloseWindows Then
		Try
			CurWindow = ActiveWindowFromTestApplication();
			WeNeedToCallSleep = True;
			If ExceptionWindow <> Undefined And CurWindow.Caption = ExceptionWindow.Caption Then
				WeNeedToCallSleep = False;
			EndIf;
			
			If WeNeedToCallSleep Then
				PerformInactivity(PauseAfterClosingWindow);
			EndIf;
		Except
			WeNeedToCallSleep = False;
		EndTry;
	EndIf;
	
	AddlParameters.Insert("ThereWasAttemptToCloseWindows", ThereWasAttemptToCloseWindows);
	
EndProcedure

&AtClient
Function ItTurnedOutToCloseWindowThroughOtherButtons(CurWindow)
	
	CancelButtons = New Array;
	If CancelButtons.Count() = 0 Then
		AddArrayFromAnotherArray(CancelButtons, CurWindow.FindObjects(Type("TestedFormButton"),"Cancel"));
	EndIf;
	If CancelButtons.Count() = 0 Then
		AddArrayFromAnotherArray(CancelButtons, CurWindow.FindObjects(Type("TestedFormButton"),"Cancel calculation"));
	EndIf;
	If CancelButtons.Count() = 0 Then
		AddArrayFromAnotherArray(CancelButtons, CurWindow.FindObjects(Type("TestedFormButton"),"Cancel*"));
	EndIf;
	If CancelButtons.Count() = 0 Then
		AddArrayFromAnotherArray(CancelButtons, CurWindow.FindObjects(Type("TestedFormButton"),"Yes"));
	EndIf;
	If CancelButtons.Count() = 0 Then
		AddArrayFromAnotherArray(CancelButtons, CurWindow.FindObjects(Type("TestedFormButton"),"None"));
	EndIf;
	If CancelButtons.Count() = 0 Then
		AddArrayFromAnotherArray(CancelButtons, CurWindow.FindObjects(Type("TestedFormButton"),"Remind later_"));
	EndIf;
	If CancelButtons.Count() = 0 Then
		AddArrayFromAnotherArray(CancelButtons, CurWindow.FindObjects(Type("TestedFormButton"),"Show later_"));
	EndIf;
	
	ButtonWasPressed = False;
	For Each CurButton In CancelButtons Do
		Try
			CurButton.Click();
			ButtonWasPressed = True;
			Break;
		Except
			Continue;
		EndTry;
	EndDo;
	
	PerformInactivity(2);
	
	CurWindow = TestApplication.FindObject(Type("TestedClientApplicationWindow"), CurWindow.Caption);
	If CurWindow = Undefined Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

&AtClient
Procedure CloseModalDialogIfThereIsOne(ModalDialogWasFound = False)
	
	CurWindow = ActiveWindowFromTestApplication();
	Counter = 0;
	While ThisIsWindowOfLongOfOperation(CurWindow) Do
		PerformInactivity(1);
		CurWindow = ActiveWindowFromTestApplication();
		Counter = Counter + 1;
		If Counter > 100 Then
			Break;
		EndIf;
	EndDo;
	
	ModalDialogWasFound = False;
	DesiredWindow = Undefined;
	
	ApplicationWindows = TestApplication.FindObjects(Type("TestedClientApplicationWindow"));
	For Each ApplicationWindow In ApplicationWindows Do
		If ThisIsModalDialog(ApplicationWindow) Then
			DesiredWindow = ApplicationWindow; // TestedClientApplicationWindow
			Break;
		EndIf;
	EndDo;
	
	If DesiredWindow = Undefined Then
		Return;
	EndIf; 
	
	ModalDialogWasFound = True;
	
	Try
		DialogElements = DesiredWindow.FindObjects();
	Except
		Return;
	EndTry;
	
	DialogButtons = New Array;
	DialogFields = New Array;
	
	For Each Itm In DialogElements Do
		If TypeOf(Itm) = Type("TestedFormButton") Or TypeOf(Itm) = Type("TestedCommandInterfaceButton") Then
			DialogButtons.Add(Itm);
		ElsIf TypeOf(Itm) = Type("TestedFormGroup") Then
			Continue;
		ElsIf TypeOf(Itm) = Type("TestedForm") Then
			Continue;
		Else	
			DialogFields.Add(Itm);
		EndIf;
	EndDo;
	
	DialogFieldCounter = 0;
	For Each CurField In DialogFields Do // TestedFormField
		
		DialogFieldCounter = DialogFieldCounter + 1;
		TitleText = CurField.TitleText;
		
		If Not ValueIsFilled(TitleText) Then
			Continue;
		EndIf;
		
	EndDo;
	
	Try
		ArrayOfCancelButtons = DesiredWindow.FindObjects(Type("TestedFormButton"),"Cancel*");
	Except
		ArrayOfCancelButtons = New Array;
	EndTry;
	
	For Each Button In ArrayOfCancelButtons Do
		
		Try
			Button.Click();
			Return;
		Except
		EndTry;
		
	EndDo;

	Try
		ArrayOfButtons = DesiredWindow.FindObjects(Type("TestedFormButton"));
	Except
		ArrayOfButtons = New Array;
	EndTry;
	
	For Each Button In ArrayOfButtons Do
		If Lower(Button.TitleText) = "none" Then
			
			Try
				Button.Click();
			Except
				Continue;
			EndTry;
			
			Return;
		ElsIf Lower(Button.TitleText) = "no" Then
			Try
				Button.Click();
			Except
				Continue;
			EndTry;
			
			Return;
		ElsIf Lower(Button.TitleText) = "cancel" Then
			Try
				Button.Click();
			Except 
				Continue;
			EndTry;
			
			Return;
		ElsIf Upper(Button.TitleText) = "OK" Then
			Try
				Button.Click();
			Except
				Continue;
			EndTry;
			
			Return;
		ElsIf Lower(Button.TitleText) = "close" Then
			Try
				Button.Click();
			Except
				Continue;
			EndTry;
			
			Return;

		ElsIf Find(Lower(Button.TitleText), "cancel") > 0 Then
			Try
				Button.Click();
			Except
				Continue;
			EndTry;
			
			Return;

		EndIf;
	EndDo;
	
EndProcedure

// Wait for the window to change.
// 
// Parameters:
//  OldWindow - TestedClientApplicationWindow - The Old Window
//
&AtClient
Procedure WaitingForWindowChange(OldWindow)
	
	ThereWasWindowChange = False;
	
	For Cnt = 1 To 60 Do
		ActiveWindow = TestApplication.GetActiveWindow(); // TestedClientApplicationWindow
		If ActiveWindow.Caption <> OldWindow.Caption Then
			ThereWasWindowChange = True;
			Break;
		EndIf;
		
		PerformInactivity(1);
		
	EndDo;
	
	If Not ThereWasWindowChange Then
		Raise NStr("vi = 'Không thể đợi thay thế cửa sổ.';
					|ru = 'Не получилось дождаться смены окна.';
					|en = 'Cannot wait for the window to change.'; fa = 'Cannot wait for the window to change.';
					|it = 'Не получилось дождаться смены окна.';
					|pl = 'Cannot wait for the window to change.';
					|tr = 'Pencerenin değiştirilmesi beklenemedi'");
	EndIf;
	
EndProcedure


// Gets the real Form from the tested client application window
// 
// Parameters:
//  CurWindow - TestedClientApplicationWindow - Cur window
// 
// Returns: 
//  TestedForm - test Form
//  
&AtClient
Function RealFormFromWindow(CurWindow)
	
	CurrentForm = FormFromWindow(CurWindow);
	
	If CurrentForm = Undefined Or ThisIsFormOfLongTermOfOperation(CurrentForm) Then
		
		For Cnt = 1 To 5 Do
			
			Try
				
				CurWindow = ActiveWindowFromTestApplication();
				CurrentForm = FormFromWindow(CurWindow);
				If CurrentForm <> Undefined And Not ThisIsFormOfLongTermOfOperation(CurrentForm) Then
					Break;
				EndIf;
				If CurWindow.IsMain Then
					Return CurrentForm;
				EndIf;
			Except
				Continue;
			EndTry;
			
			PerformInactivity(1);
			
		EndDo;
	EndIf;
	
	Return CurrentForm;
	
EndFunction

// Retrieves the Form from the client application window under test
// 
// Parameters:
//  CurrentWindow - TestedClientApplicationWindow - Cur window
// 
// Returns: 
//  TestedForm - test Form
//  
&AtClient
Function FormFromWindow(CurrentWindow)
	
	Return CurrentWindow.FindObject(Type("TestedForm"));
	
EndFunction

#Region DeterminingTypeOfWindow

&AtClient
Function ThisIsWindowOfLongOfOperation(CurWindow)
	
	Try
		If CurWindow.Caption = NStr("vi = 'Xin vui lòng đợi...';
									|ru = 'Пожалуйста, подождите...';
									|en = 'Please wait…'; fa = 'لطفاً صبر کنید…';
									|it = 'Attendere prego...';
									|pl = 'Proszę czekać...';
									|tr = 'Lütfen bekleyin...'") Then
			Return True;
		EndIf;
		
		CrntForm = CurWindow.FindObject(Type("TestedForm"));
		
		If CrntForm <> Undefined And ThisIsFormOfLongTermOfOperation(CrntForm) Then
			Return True;
		EndIf;
		
		Return False;
		
	Except
		
		Return False;
		
	EndTry;
	
EndFunction

&AtClient
Function ThisIsFormOfLongTermOfOperation(CrntForm)
	
	If CrntForm.FormName = "CommonForm.TimeConsumingOperation" Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

&AtClient
Function MainWindowOfTest()
	
	MainWindowOfTest = Undefined;
	ClientWindowsOfApplicationUnderTest = TestApplication.GetChildObjects();
	For Each WindowUnderTest In ClientWindowsOfApplicationUnderTest Do
		If WindowUnderTest.IsMain Then
			MainWindowOfTest = WindowUnderTest;
			Break;
		EndIf;
	EndDo;
	
	Return MainWindowOfTest;
	
EndFunction

// Determines whether the Cur window is a modal Form
// 
// Parameters:
//  ApplicationWindow - TestedClientApplicationWindow - Cur window
// 
// Returns: 
//  Boolean - test Form
//  
&AtClient
Function ThisIsModalDialog(ApplicationWindow) Export
	
	If CacheOfCheckedWindowsForModality[ApplicationWindow.Caption] = False Then
		Return False;
	EndIf;
	
	If ThisIsTitleOfModalDialogWindow(ApplicationWindow.Caption) Then
		Return True;
	EndIf;
	
	If ApplicationWindow.IsMain Then
		Return False;
	EndIf;
	
	Try
		FormWindow = ApplicationWindow.FindObject(Type("TestedForm"));
	Except
		Return False;
	EndTry;
	
	If FormWindow = Undefined Then
		If ValueIsFilled(ApplicationWindow.Caption) Then
			CacheOfCheckedWindowsForModality.Insert(ApplicationWindow.Caption, False);
		EndIf;
		Return False;
	EndIf;
	
	If Left(Lower(FormWindow.TitleText), 9) = Lower("Properties:") And FormWindow.FormName = "" Then
		// This is the "Form Setup Form"
		If ValueIsFilled(ApplicationWindow.Caption) Then
			CacheOfCheckedWindowsForModality.Insert(ApplicationWindow.Caption, False);
		EndIf;
		Return False;
	EndIf;
	
	If FormWindow.FormName = "" Then
		Return True;
	EndIf;
	If FormWindow.FormName = "MessageBox" Then
		Return True;
	EndIf;
	
	If Lower(Right(FormWindow.FormName,13)) = Lower(".CancelDialog") Then
		Return True;
	EndIf;
	
	If ValueIsFilled(ApplicationWindow.Caption) Then
		CacheOfCheckedWindowsForModality.Insert(ApplicationWindow.Caption, False);
	EndIf;
	
	Return False;
	
EndFunction 

#EndRegion

#EndRegion

&AtClientAtServerNoContext
Function IsLinux()
	
	Value = False;
	SysInfo = New SystemInfo;
	If SysInfo.PlatformType = PlatformType.Linux_x86 
		Or SysInfo.PlatformType = PlatformType.Linux_x86_64
		Or SysInfo.PlatformType = PlatformType.MacOS_x86
		Or SysInfo.PlatformType = PlatformType.MacOS_x86_64 Then 
		Value = True;
	EndIf;
	
	Return Value;
	
EndFunction

&AtClient
Function ExecuteFACommandWithoutShowingBlackWindow(Val CommandText, WaitForEnd = -1)
	
	CommandText = StrReplace(CommandText, "%", "%%");
		
	If IsLinux() Then
		
		FileSystemClient.StartApplication(CommandText);
		Return 0;
		
	EndIf;
	
	NameOfTemporaryCommandFile = GetTempFileName("bat");
	
	// these two lines are needed to write a file without a BOM - the beginning
	TextWriter = New TextWriter(NameOfTemporaryCommandFile, TextEncoding.ANSI, , False); 
	TextWriter.Close();
	// these two lines are needed to write a file without a BOM - ending
	
	TextWriter = New TextWriter(NameOfTemporaryCommandFile, TextEncoding.UTF8, , True); 
	TextWriter.WriteLine("chcp 65001"); 
	TextWriter.WriteLine(CommandText); 
	TextWriter.Close();
	
	If WindowsKernel = Undefined Then
		WindowsKernel = WindowsKernel();
		// Next, the Jadrovindous variable will be cached so as not to create a ComObject every time
	EndIf; 
	Rez = WindowsKernel.Run("""" + NameOfTemporaryCommandFile + """", 0, WaitForEnd);
	
	If WaitForEnd = -1 Then
		Try
			DeleteFiles(NameOfTemporaryCommandFile);
		Except
		EndTry;
	EndIf;
	
	Return Rez;
	
EndFunction

&AtClient
Procedure InstallConnectTestClient()
	
	MaxDate_ = CommonClient.SessionDate() + TestClientStartupTimeout;
	While True Do
		
		If CommonClient.SessionDate() > MaxDate_ Then
			
			ErrorText = StrTemplate(NStr("vi = 'Không thể kết nối Client thử nghiệm. Ngắt thời gian chờ <%1>';
										|ru = 'Не получилось подключить Тестовый клиент. Прерывание по таймауту <%1>';
										|en = 'Cannot connect the test client. <%1> timeout interruption'; fa = 'Cannot connect the test client. <%1> timeout interruption';
										|it = 'Не получилось подключить Тестовый клиент. Прерывание по таймауту <%1>';
										|pl = 'Cannot connect the test client. <%1> timeout interruption';
										|tr = 'Test istemcisi bağlanamadı. Zaman aşımı kesintisi <%1>'"), TestClientStartupTimeout);
			
			Raise ErrorText;
			
		EndIf; 
		
		IsConnectionEstablished = False;
		Try
			TestApplication.Connect();
			MainWindowOfTest = MainWindowOfTest();
			IsConnectionEstablished = True;
		Except
		EndTry;
		
		If IsConnectionEstablished Then
			If OpeningMode = "ConnectionSettings" Then
				NotificationText1 = NStr("vi = 'Đã thiết lập kết nối.';
										|ru = 'Подключение установлено.';
										|en = 'The connection is established.'; fa = 'The connection is established.';
										|it = 'Подключение установлено.';
										|pl = 'The connection is established.';
										|tr = 'Bağlantı kuruldu.'");
				CloseAfterSuccessfulConnection();
			EndIf;
			Return;
		EndIf;
		
		PerformInactivity(1);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure PerformInactivity(NumberOfSeconds)
	
	If TestApplication <> Undefined Then
		
		Try
			TestApplication.FindObject(Type("TestedClientApplicationWindow"), 
			String(New UUID),, NumberOfSeconds);
			Return;
		Except
			
		EndTry;
		
	EndIf;
	
	Try
		If IsLinux() Then
			Command = "ping -i " + Format(NumberOfSeconds, "NG=; NZ=0") + " 127.0.0.1 -c 2 > /dev/null";
			FileSystemClient.StartApplication(Command);
		Else
			Command = "ping 127.0.0.1 -n " + Format(NumberOfSeconds + 1, "NG=; NZ=0"); 
			ExecuteFACommandWithoutShowingBlackWindow(Command);
		EndIf;
	Except
		CommonClient.MessageToUser(StrTemplate(("Sleep:%1"), ErrorDescription()));
	EndTry;
	
EndProcedure

&AtClient
Function WindowsKernel()
	
	#If Not MobileClient Then
	
		If WindowsKernel = Undefined Then
			Try
				WindowsKernel = New COMObject("WScript.Shell");
			Except 
				Raise StrTemplate(NStr("vi = 'Không thể kết nối đối tượng COM %1';
										|ru = 'Не удалось подключить COM объект %1';
										|en = 'Cannot attach the %1 COM object'; fa = 'Cannot attach the %1 COM object';
										|it = 'Не удалось подключить COM объект %1';
										|pl = 'Cannot attach the %1 COM object';
										|tr = '%1 COM nesnesine bağlanılamadı'"), "<WScript.Shell>");
			EndTry;
		EndIf;
		
		Return WindowsKernel;
	
	#EndIf
	
EndFunction 

&AtClient
Function ThisWindowShouldBeClosed(CurWindow, ExceptionWindow, AsterixSymbolIsConsideredAnotherWindow)
	
	ThisWindowShouldBeClosed = False;
	
	Try
		If Not (CurWindow.HomePage Or CurWindow.IsMain) Then
			If ExceptionWindow = Undefined 
				Or (ExceptionWindow <> Undefined And CurWindow.Caption <> ExceptionWindow.Caption) Then
				
					ThisWindowShouldBeClosed = True;
					
					If ExceptionWindow <> Undefined And Not AsterixSymbolIsConsideredAnotherWindow Then
						If Right(CurWindow.Caption, 1) = "*" Then
							StringToCheck = Left(CurWindow.Caption, StrLen(CurWindow.Caption) - 2);
							If StringToCheck = ExceptionWindow.Caption Then
								ThisWindowShouldBeClosed = False;
							EndIf;
						EndIf;
					EndIf;
			EndIf;
		EndIf;
	Except
		Return ThisWindowShouldBeClosed;
	EndTry;
	
	Return ThisWindowShouldBeClosed;
	
EndFunction

&AtClient
Procedure AddArrayFromAnotherArray(Recipient, Source)
	
	For Each Itm In Source Do
		If Recipient.Find(Itm) = Undefined Then
			Recipient.Add(Itm);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Function ThisIsTitleOfModalDialogWindow(WindowTitle)
	
	If WindowTitle = "1From1:Enterprise"
		Or WindowTitle = "1C:Enterprise"  Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

&AtClient
Function ThisIsFormOfError(TestedForm)
	
	Return TestedForm.FormName = "ErrorWindow";
	
EndFunction

&AtClient
Procedure CloseAfterSuccessfulConnection()
	
	Close(ReturnStructure());
	
EndProcedure 

&AtClient
Function ReturnStructure()

	ReturnStructure = New Structure;
	ReturnStructure.Insert("TestingClientPortNumber",        TestingClientPortNumber);
	ReturnStructure.Insert("TestClientConnectionString", TestClientConnectionString);
	ReturnStructure.Insert("TestClientStartupTimeout",   TestClientStartupTimeout);
	ReturnStructure.Insert("IsConnectionEstablished",               IsConnectionEstablished);
	ReturnStructure.Insert("NotificationText1",                     NotificationText1);
	
	Return ReturnStructure;

EndFunction

#Region GettingScreenshots

&AtClient
Procedure GetScreenshotsOfObjects()
	
	FolderNameScreenshots = DirectoryName  
	                       + DemoScenariosClientServer.NameOfUploadFolderScreenshots() 
	                       + GetPathSeparator();
	
	If Not DemoScenariosClientServer.FolderOnDiskExists(FolderNameScreenshots) Then
		CreateDirectory(FolderNameScreenshots);
	EndIf;
	
	ProgressData = ProgressDataGettingScreenshots();
	
	For Each TableRow In NavigationLinks Do
		
		GetScreenshotsFromNavigationLinksLine(TableRow, Undefined, ProgressData);
		
	EndDo;
	
	Close(ScreenshotDataToBeReturned());
	
EndProcedure

&AtClient
Function ProgressDataGettingScreenshots()
	
	ProgressData = NewDataToDisplayProgress();
	
	ProgressData.ToProcessing = NavigationLinks.Count();
	
	Return ProgressData;
	
EndFunction

&AtServer
Function ScreenshotDataToBeReturned()
	
	ScreenshotDataToBeReturned = New Structure;
	
	ScreenshotDataToBeReturned.Insert("Success", True);
	ScreenshotDataToBeReturned.Insert("AddressScreenshotData", PutToTempStorage(FormAttributeToValue("NavigationLinks"), IdOfOwnerSForm));
	
	Return ScreenshotDataToBeReturned;
	
EndFunction

&AtClient
Procedure GetScreenshotsFromNavigationLinksLine(TableRow, OpenFormData, ProgressData)
	
	If TableRow.RefType = "ObjectsRefs" 
		And  Not ValueIsFilled(TableRow.ObjectReference) Then
		
		TableRow.Errors.Add(NStr("vi = 'Không thể xác định các đối tượng được mở ra theo liên kết dẫn hướng';
								|ru = 'Не удалось определить открываемые объект по навигационной ссылке';
								|en = 'Cannot identify the object to open by URL'; fa = 'Cannot identify the object to open by URL';
								|it = 'Не удалось определить открываемые объект по навигационной ссылке';
								|pl = 'Cannot identify the object to open by URL';
								|tr = 'URL tarafından açılan nesne tanımlanamadı'"));
		Return;
		
	EndIf;
	
	OpenFormData = DataOfFormBeingOpened(TableRow.URL);
	If Not OpenFormData.Success Then
		TableRow.Errors.Add(NStr("vi = 'Không thể mở biểu mẫu theo liên kết dẫn hướng';
								|ru = 'Не удалось открыть форму по навигационной ссылке';
								|en = 'Cannot open the form using URL'; fa = 'Cannot open the form using URL';
								|it = 'Не удалось открыть форму по навигационной ссылке';
								|pl = 'Cannot open the form using URL';
								|tr = 'URL tarafından form açılamadı'"));
		Return;
	EndIf;
	
	If TableRow.RefType = "ObjectsRefs" Then
		Pause = 1;
	Else
		Pause = 4;
	EndIf;
	
	If OpenFormData.DataOfPage.Count() > 0  Then
		
		For Each PageData_ In OpenFormData.DataOfPage Do
			
			ScreenshotID = ScreenshotID(TableRow);
			
			AddResultingScreenshotToTable(ResultOfGettingScreenshot(OpenFormData, PageData_.Name, ScreenshotID, Pause), TableRow);
			
		EndDo;
		
	Else
		
		ScreenshotID = ScreenshotID(TableRow);
		
		AddResultingScreenshotToTable(ResultOfGettingScreenshot(OpenFormData, "", ScreenshotID, Pause), TableRow);
		
	EndIf;
	
	DisplayProcessingProgress(ProgressData);
	
EndProcedure 

&AtClient
Function ScreenshotID(TableRow)  
	
	Return StrTemplate("%1_%2", TableRow.HashOfLink, String(TableRow.Screenshots.Count() + 1));
	
EndFunction

&AtClient
Procedure AddResultingScreenshotToTable(ResultOfGettingScreenshot, TableRow)
	
	If ResultOfGettingScreenshot.Success Then 
		
		NewRow = TableRow.Screenshots.Add();
		NewRow.BinaryData          = ResultOfGettingScreenshot.BinaryData;
		NewRow.FileName                = ResultOfGettingScreenshot.FileName;
		NewRow.ScreenshotID  = ResultOfGettingScreenshot.ScreenshotID; 
		
	EndIf;
	
EndProcedure

&AtClient
Function ResultOfGettingScreenshot(OpenFormData, PageName, ScreenshotID, Pause)
	
	GetResult1 = New Structure;
	GetResult1.Insert("BinaryData",          Undefined);
	GetResult1.Insert("Success",                 False);
	GetResult1.Insert("FileName",                "");
	GetResult1.Insert("ScreenshotID",  "");
	
	If Not IsBlankString(PageName) Then
		
		PageToDisplay = OpenFormData.CurrentForm.FindObject(Type("TestedFormGroup"),, PageName);
		
		If PageToDisplay <> Undefined
			And PageToDisplay.CurrentVisible()
			And PageToDisplay.CurrentEnable() Then
			
			PageToDisplay.Activate();
			PerformInactivity(Pause);
			
			TakeScreenshotOfComponent(GetResult1);
			
		EndIf;
		
	Else
		
		TakeScreenshotOfComponent(GetResult1);
		
	EndIf;
	
	If GetResult1.Success Then
		
		ScreenshotFileName = FolderNameScreenshots + ScreenshotID + ".png";
		GetResult1.BinaryData.Write(ScreenshotFileName);
		GetResult1.FileName                = ScreenshotFileName;
		GetResult1.ScreenshotID  = ScreenshotID;
		
	EndIf;
	
	Return GetResult1;
	
EndFunction

#EndRegion

#Region WorkingWithExternalComponentForTakingScreenshots

&AtClient
Procedure ConnectExternalComponent(AdditionalParameters = Undefined)
	
	NameOfExternalModule = DemoScenariosClientServer.IdOfExternalComponentForGettingScreenshots(); 
	
	ConnectionParameters = AddInsClient.ConnectionParameters();
	ConnectionParameters.Isolated           = False;
	ConnectionParameters.AutoUpdate = False;
	ConnectionParameters.SuggestToImport    = False;
	
	Notification = New CallbackDescription(
	                 "ComponentForConnectingScreenshotsAfterConnecting", ThisObject, AdditionalParameters);
	
	AddInsClient.AttachAddInSSL(Notification, NameOfExternalModule, , ConnectionParameters);
	
EndProcedure

&AtClient
Procedure ComponentForConnectingScreenshotsAfterConnecting(Result, AdditionalParameters) Export
	
	If Result.Attached Then
		
		TextPrefix = NStr("vi = 'Phiên bản cấu hình nhận ảnh chụp màn hình';
							|ru = 'Версия компоненты получения скриншотов';
							|en = 'Screenshot add-in version'; fa = 'Screenshot add-in version';
							|it = 'Версия компоненты получения скриншотов';
							|pl = 'Screenshot add-in version';
							|tr = 'Ekran görüntüsü alma eklentisinin sürümü'") + ": ";
		VersionComponents = StrReplace(Result.Attachable_Module.Version, Char(0), "");
		AddressOfHyperlink = "https://github.com/lintest/VanessaExt/releases";
		
		TextOfConnectedComponent = "%1 <a style= 'Color: HyperlinkColor ' href=""%2"">%3</a>.";
		
		TextVersionComponents = StringFunctionsClient.FormattedString(TextOfConnectedComponent, TextPrefix, AddressOfHyperlink, VersionComponents); 
		
		Items.DecorationVersionComponents.Title = TextVersionComponents; 
		
		ExternalComponentForScreenshots = Result.Attachable_Module;
		
		If OpeningMode = "GettingScreenshots" Then
			
			ConnectTestingClient();
			
			If IsConnectionEstablished Then
			
				AttachIdleHandler("GetScreenshotsOfObjects", 1, True);
			
			EndIf;
			
		EndIf;
		
	Else
		
		MessageText = StrTemplate(NStr("vi = 'Không thể kết nối cấu phần nhận ảnh chụp màn hình do nguyên nhân: %1';
										|ru = 'Не удалось подключить компоненту получению скриншотов по причине: %1';
										|en = 'Cannot attach the screenshot add-in due to: %1'; fa = 'Cannot attach the screenshot add-in due to: %1';
										|it = 'Не удалось подключить компоненту получению скриншотов по причине: %1';
										|pl = 'Cannot attach the screenshot add-in due to: %1';
										|tr = 'Ekran görüntüsü alma eklentisine şu nedenden dolayı bağlanılamadı: %1'"), Result.ErrorDescription);
		CommonClient.MessageToUser(MessageText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TakeScreenshotOfComponent(GetResult1)
	
	BinaryData = ExternalComponentForScreenshots.CaptureProcess(PIDCurCurrentTestingClient);
	
	GetResult1.Insert("BinaryData", Undefined);
	GetResult1.Insert("Success",        False);
	GetResult1.Insert("FileName",       "");
	
	If BinaryData <> Undefined Then
		
		GetResult1.BinaryData = BinaryData;
		GetResult1.Success        = True;
	
	EndIf;

EndProcedure

&AtClient
Procedure FillInPidHandleOfTestingClientWindow(TestClientLaunchData, AddlParameters = Undefined)
	
	If AddlParameters = Undefined Then
		AddlParameters = New Structure;
	EndIf; 
	
	AddlParameters.Insert("TestClientLaunchData",TestClientLaunchData);
	CallbackDescription = New CallbackDescription("TestingClientReceived", ThisObject, AddlParameters);
	ExternalComponentForScreenshots.BeginCallingFindTestClient(CallbackDescription ,TestClientLaunchData.TestClientLaunchPort);
	
EndProcedure

&AtClient
Procedure TestingClientReceived(CallResult, CallParameters, AdditionalParameters) Export 
	
	StructureOfProcessProperties = ReadJSONString(CallResult);
	If StructureOfProcessProperties <> Undefined Then
		DescriptorOfMainWindowOfCurrentTestingClient = StructureOfProcessProperties.Window;
		PIDCurCurrentTestingClient                     = StructureOfProcessProperties.ProcessId;
	EndIf;
	
	TestClientLaunchData = AdditionalParameters.TestClientLaunchData;
	TestClientLaunchData.PIDTestingClient = PIDCurCurrentTestingClient;

	If DescriptorOfMainWindowOfCurrentTestingClient <> Undefined Then
		Notification = New CallbackDescription("EmptyNotificationHandler", ThisObject, 1);
		ExternalComponentForScreenshots.BeginCallingActivateWindow(Notification, DescriptorOfMainWindowOfCurrentTestingClient);
	EndIf;
	
EndProcedure

&AtClient
Procedure EmptyNotificationHandler(Result, AdditionalParameters, AdditionalData) Export
	
	Return;
	
EndProcedure 

&AtClient
Function TestClientLaunchData()
	
	TestClientLaunchData = New Structure;
	TestClientLaunchData.Insert("TestClientLaunchPort", TestingClientPortNumber);
	TestClientLaunchData.Insert("PIDTestingClient", Undefined);
	
	Return TestClientLaunchData;
	
EndFunction

&AtClient
Function ReadJSONString(JSONText)
	
	If IsBlankString(JSONText) Then
		Return Undefined;
	EndIf;

	FieldsDates = New Array;
	FieldsDates.Add("CreationDate");
	FieldsDates.Add("date");
		
	JSONReader = New JSONReader();
	JSONReader.SetString(JSONText);
	Return ReadJSON(JSONReader, , FieldsDates);
	
EndFunction

#EndRegion

#EndRegion 

#EndIf
