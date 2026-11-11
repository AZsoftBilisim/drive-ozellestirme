#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InitializeFormData();
	
	AvailabilityControl(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ApplicationIsRunningAsTestManager = ApplicationIsRunningAsTestManager();
	
	InitializeFormDataOnClient();
	
	GenerateInformationAboutTestingClientSettings();
	
	AvailabilityControl(ThisObject);
	InstallAssistantNavigator();
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	SelectionOfComposerHasBeenChanged = Settings.Get("ComposerSelectionHasBeenChanged");
	If SelectionOfComposerHasBeenChanged <> Undefined 
		And  SelectionOfComposerHasBeenChanged Then
		
		Settings.Insert("DataSelectionAndLayoutSettings", New ValueStorage(SettingsComposer.Settings));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	Settings.Delete("ComposerSelectionHasBeenChanged");
	
	SavedSelectionSettings = Settings.Get("DataSelectionAndLayoutSettings");
	If TypeOf(SavedSelectionSettings) = Type("ValueStorage") Then
		
		Filter_Settings = SavedSelectionSettings.Get();
		
		SettingsComposer.LoadSettings(Filter_Settings);
		SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability); 
		
	EndIf;
	
	Settings.Delete("DataSelectionAndLayoutSettings");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers 

&AtClient
Procedure AssistantNavigatorDecorationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	ClearMessages();
	
	StandardProcessing = False;
	
	Cancel = False;
	
	CheckAbilityToNavigateThroughPages("Next", Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	If FormattedStringURL = "GoToHomePage" Then
		
		GoToAssistantPage("UploadStartingPage");
		
	ElsIf FormattedStringURL = "GoToSelectionPage" Then 
		
		GoToAssistantPage("PageUploadSelection");
		
	ElsIf FormattedStringURL = "GoToSelectionResultsPage" Then
		
		GoToAssistantPage("WhatWillBeUploadedPage"); 
		
	EndIf;
	
EndProcedure

#Region UploadStartingPage 

&AtClient
Procedure MethodOfUploadingWithoutReplacingLinksOnChange(Item)
	
	AvailabilityControl(ThisObject);
	DefineNextButtonTitle();
	InstallAssistantNavigator();
	
EndProcedure

&AtClient
Procedure MethodOfUploadingReplacingLinksOnChange(Item)
	
	AvailabilityControl(ThisObject);
	DefineNextButtonTitle();
	InstallAssistantNavigator();
	
EndProcedure

&AtClient
Procedure DecorationInformationAboutTestingClientSettingsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "GoToTestingClientSettings" Then
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("TestingClientPortNumber",        TestingClientPortNumber);
		OpeningParameters.Insert("TestClientConnectionString", TestClientConnectionString);
		OpeningParameters.Insert("TestClientStartupTimeout",   TestClientStartupTimeout);
		OpeningParameters.Insert("OpeningMode",                       "ConnectionSettings");
		
		NotificationAfterClosingTestClientSettings = New CallbackDescription("AfterClosingTestClientSetup",ThisObject);
		
		OpenForm("DataProcessor.ProcessDetailsExport.Form.OperationWithTestClient", OpeningParameters, ThisObject, ,,, NotificationAfterClosingTestClientSettings, 
		             FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SceneryRequiresTestManagerURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "RestartApplicationWithTestManagerKey" Then
		
		Exit(True, True, "/TESTMANAGER");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FullUploadOnChange(Item)
	
	DefineNextButtonTitle();
	InstallAssistantNavigator();
	
EndProcedure

&AtClient
Procedure PartialUnloadingOnChange(Item)
	
	DefineNextButtonTitle();
	InstallAssistantNavigator();
	
EndProcedure

&AtClient
Procedure FileDirectoryUploadStartSelection(Item, ChoiceData, StandardProcessing)
	
	DemoScenariosClient.ProcessingStartOfFileSelection(ThisObject, 
	                                                          FileDialogMode.ChooseDirectory, 
	                                                          "DumpDirectory",
	                                                          True, 
	                                                          Undefined);
	
EndProcedure

&AtClient
Procedure DumpDirectoryOnChange(Item)
	
	AvailabilityControl(ThisObject);
	
EndProcedure

#EndRegion

#Region PageUnloaded

&AtClient
Procedure DecorationResultsOfUnloadingURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "GoToUploadDirectory" Then
		
		If Not DemoScenariosClientServer.FolderOnDiskExists(NameOfActualUploadDirectory(DumpDirectory)) Then
			Return;
		EndIf;
		
		FileSystemClient.OpenExplorer(NameOfActualUploadDirectory(DumpDirectory));
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersSettingsComposerSettingsFilter

&AtClient
Procedure SettingsComposerSettingsFilterOnChange(Item)
	
	ComposerSelectionHasBeenChanged           = True;
	ReceiptIsRequiredWhatWeAreUnloading     = True;
	ObtainingTreeOfScreenshotsIsRequired = True;
	UnloadingIsRequired                  = True;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersScriptsToUpload

&AtClient
Procedure ScriptsToUploadSelection(Item, RowSelected, Field, StandardProcessing)
	
	RowData = ScriptsToUpload.FindByID(RowSelected);
	If RowData = Undefined Then
		Return;
	EndIf;
	
	ShowValue(, RowData.Scenario);
	
EndProcedure 

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)
	
	NavigateThroughPages(Command);
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	NavigateThroughPages( Command);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

#Region InitializingFormData

&AtServer
Procedure InitializeFormData()
	
	InitializeDescriptionSelectionComposer(Undefined); 
	
	Items.PagesUploadAssistant.CurrentPage = Items.UploadStartingPage;
	Items.PagesFooter.CurrentPage           = Items.ClickNextPage;
	
	DeliveryInformation = DemoScenarios.PresentationCurVersionOfConfiguration();
	
	ReceiptIsRequiredWhatWeAreUnloading = True;
	UnloadingIsRequired              = True;
	
EndProcedure 

&AtClient
Procedure InitializeFormDataOnClient()
	
	If TestClientStartupTimeout = 0 Then
		 TestClientStartupTimeout = 300;
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeDescriptionSelectionComposer(CompositionSetup)
	
	CompositionSchema = DataProcessors.ProcessDetailsExport.GetTemplate("ProcessDetailsFilter");
	SchemaURL = PutToTempStorage(CompositionSchema,UUID);
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL));
	
	If CompositionSetup = Undefined Then
		SettingsComposer.LoadSettings(CompositionSchema.DefaultSettings);
	Else
		SettingsComposer.LoadSettings(CompositionSetup);
		SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	EndIf;
	
EndProcedure

&AtClient
Function ApplicationIsRunningAsTestManager()
	
	TypeOfApplicationUnderTest = Undefined;
	
	Try
		TypeOfApplicationUnderTest = Type("TestedApplication");
	Except
		Return False;
	EndTry;
	
	Return TypeOfApplicationUnderTest <> Undefined;
	
EndFunction

#EndRegion

#Region TestingClientSettings

&AtClient
Procedure GenerateInformationAboutTestingClientSettings()
	
	CommandText = "GoToTestingClientSettings";
	
	If TestingClientIsConnected Then
		
		DetailsText = StringFunctionsClient.FormattedString("<a href=""%1"">%2</a>",
		                                                       CommandText,
		                                                       NStr("vi = 'Đã kết nối client thử nghiệm';
																	|ru = 'Клиент тестирования подключен';
																	|en = 'Test client is connected'; fa = 'کلاینت آزمایشی متصل است';
																	|it = 'Клиент тестирования подключен';
																	|pl = 'Test client is connected';
																	|tr = 'Test istemcisi bağlandı'"));
		
	Else
		
		DetailsText = StringFunctionsClient.FormattedString("<a href=""%1"">%2</a>",
		                                                       CommandText,
		                                                       NStr("vi = 'Cần tùy chỉnh và kết nối client thử nghiệm';
																	|ru = 'Требуется настроить и подключить клиент тестирования';
																	|en = 'Configure and connect the test client'; fa = 'Configure and connect the test client';
																	|it = 'Требуется настроить и подключить клиент тестирования';
																	|pl = 'Configure and connect the test client';
																	|tr = 'Test istemcisinin ayarlanması ve bağlanması gerekmektedir'"));
		
	EndIf;
	
	Items.DecorationInformationAboutTestingClientSettings.Title = DetailsText;
	
EndProcedure 

&AtClient
Procedure AfterClosingTestClientSetup(Result, AdditionalParameters) Export

	If Result = Undefined
		Or Result = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	TestingClientPortNumber        = Result.TestingClientPortNumber;
	TestClientConnectionString = Result.TestClientConnectionString;
	TestClientStartupTimeout   = Result.TestClientStartupTimeout;
	TestingClientIsConnected         = Result.IsConnectionEstablished;
	
	If Not IsBlankString(Result.NotificationText1) Then 
		
		NotificationTitle = NStr("vi = 'Client thử nghiệm';
								|ru = 'Клиент тестирования';
								|en = 'Test client'; fa = 'کلاینت آزمایشی';
								|it = 'Клиент тестирования';
								|pl = 'Test client';
								|tr = 'Test istemcisi'");
		ShowUserNotification(NotificationTitle, , Result.NotificationText1);
		
	EndIf;
	
	GenerateInformationAboutTestingClientSettings()

EndProcedure

#EndRegion

#Region FormItemsManagement

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)
	
	ManagingAvailabilityOfTestingClientSettings(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ManagingAvailabilityOfTestingClientSettings(Form)

	Items = Form.Items;
	
	If Form.ExportMethod = 1 Then
		
		Items.TestClientConnectionPages.Visible = True;
		
		If Form.ApplicationIsRunningAsTestManager Then
			
			Items.TestClientConnectionPages.CurrentPage = Items.TestingClientSettingsPage;
			
		Else
			
			Items.TestClientConnectionPages.CurrentPage = Items.PageRequiresTestManager;
			
		EndIf;
		
	Else
		
		Items.TestClientConnectionPages.Visible = False;
		
	EndIf;

EndProcedure

&AtClient
Procedure InstallAssistantNavigator()
	
	StartPageLine    = DemoScenariosClientServer.TitleOfNavigatorPartOfAssistant(NStr("vi = 'Tùy chỉnh kết xuất';
																						|ru = 'Настройка выгрузки';
																						|en = 'Export setup'; fa = 'تنظیم خروج اطلاعات';
																						|it = 'Impostazione upload';
																						|pl = 'Ustawianie eksportowania';
																						|tr = 'Dışa aktarım ayarları'"), 
	                                                               "GoToHomePage",
	                                                               True,
	                                                               Items.PagesUploadAssistant.CurrentPage = Items.UploadStartingPage);
	
	StringSelection_                = DemoScenariosClientServer.TitleOfNavigatorPartOfAssistant(NStr("vi = 'Lọc';
																									|ru = 'Отбор';
																									|en = 'Filter'; fa = 'فیلتر';
																									|it = 'Отбор';
																									|pl = 'Filter';
																									|tr = 'Filtre'"), 
	                                                               "GoToSelectionPage",
	                                                               FullOrPartialUnloading = 1,
	                                                               Items.PagesUploadAssistant.CurrentPage = Items.PageUploadSelection);
	
	StringSelectionResult     = DemoScenariosClientServer.TitleOfNavigatorPartOfAssistant(NStr("vi = 'Kết quả lọc';
																								|ru = 'Результат отбора';
																								|en = 'Filter result'; fa = 'Filter result';
																								|it = 'Результат отбора';
																								|pl = 'Filter result';
																								|tr = 'Filtre sonucu'"), 
	                                                               "GoToSelectionResultsPage",
	                                                               ReceiptIsRequiredWhatWeAreUnloading = False,
	                                                               Items.PagesUploadAssistant.CurrentPage = Items.WhatWillBeUploadedPage);
	
	ResultLineOfUpload     = DemoScenariosClientServer.TitleOfNavigatorPartOfAssistant(NStr("vi = 'Kết quả kết xuất';
																							|ru = 'Результат выгрузки';
																							|en = 'Export result'; fa = 'Export result';
																							|it = 'Результат выгрузки';
																							|pl = 'Export result';
																							|tr = 'Dışa aktarma sonucu'"), 
	                                                               "GoToUploadResultPage",
	                                                               UnloadingIsRequired = False,
	                                                               Items.PagesUploadAssistant.CurrentPage = Items.WhatWillBeUploadedPage);
	
	LineBetweenPages = " -> ";
	
	ArrayFormattedString = New Array;
	ArrayFormattedString.Add(StartPageLine);
	
	If  FullOrPartialUnloading = 1 Then
		
		ArrayFormattedString.Add(LineBetweenPages);
		ArrayFormattedString.Add(StringSelection_);
		ArrayFormattedString.Add(LineBetweenPages);
		ArrayFormattedString.Add(StringSelectionResult);
		
	EndIf;
	
	ArrayFormattedString.Add(LineBetweenPages);
	ArrayFormattedString.Add(ResultLineOfUpload);
	
	Items.AssistantNavigatorDecoration.Title = New FormattedString(ArrayFormattedString);
	
EndProcedure

&AtClient
Procedure DefineNextButtonTitle()
	
	If Items.PagesUploadAssistant.CurrentPage = Items.UploadStartingPage Then
		
		If ExportMethod = 0 
			And FullOrPartialUnloading = 0 Then
			
			Items.Next.Title = NStr("vi = 'Kết xuất';
									|ru = 'Выгрузить';
									|en = 'Export'; fa = 'خروج اطلاعات';
									|it = 'Выгрузить';
									|pl = 'Export';
									|tr = 'Dışa aktar'");
			
		Else
			
			Items.Next.Title = NStr("vi = 'Tiếp theo >>';
									|ru = 'Далее >>';
									|en = 'Next >>'; fa = 'بعدی >>';
									|it = 'Avanti >>';
									|pl = 'Dalej >>';
									|tr = 'İleri >>'");
			
		EndIf;
		
	ElsIf Items.PagesUploadAssistant.CurrentPage = Items.WhatWillBeUploadedPage Then 
		
		If ExportMethod = 0 Then
			
			Items.FurtherBackFurther.Title = NStr("vi = 'Kết xuất';
													|ru = 'Выгрузить';
													|en = 'Export'; fa = 'خروج اطلاعات';
													|it = 'Выгрузить';
													|pl = 'Export';
													|tr = 'Dışa aktar'");
			
		Else
			
			Items.FurtherBackFurther.Title = NStr("vi = 'Tiếp theo >>';
													|ru = 'Далее >>';
													|en = 'Next >>'; fa = 'بعدی >>';
													|it = 'Avanti >>';
													|pl = 'Dalej >>';
													|tr = 'İleri >>'");
			
		EndIf; 
		
	Else
		
		Items.FurtherBackFurther.Title = NStr("vi = 'Tiếp theo >>';
												|ru = 'Далее >>';
												|en = 'Next >>'; fa = 'بعدی >>';
												|it = 'Avanti >>';
												|pl = 'Dalej >>';
												|tr = 'İleri >>'");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DefineDefaultBasementButton()

	If Items.PagesFooter.CurrentPage = Items.ClickNextPage Then
		
		Items.Next.DefaultButton = True;
		
	ElsIf Items.PagesFooter.CurrentPage = Items.TheDoneButtonPage Then
		
		Items.NextFinish.DefaultButton = True;
		
	ElsIf Items.PagesFooter.CurrentPage = Items.BackNextButtonPage Then
		
		Items.FurtherBackFurther.DefaultButton = True;
		
	EndIf;

EndProcedure

#EndRegion

#Region PageNavigation

&AtClient
Procedure NavigateThroughPages(Command)
	
	ClearMessages();
	
	CommandName = Command.Name;
	Cancel      = False;
	
	CheckAbilityToNavigateThroughPages(CommandName, Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	PerformNecessaryActionsWhenNavigatingThroughPages(CommandName);
	
EndProcedure

&AtClient
Procedure PerformNecessaryActionsWhenNavigatingThroughPages(CommandName)

	If CommandName = "Next" Then
		GotoNextPage();
	Else
		GoToThePreviousPage();
	EndIf;
	
	InstallAssistantNavigator();

EndProcedure

&AtClient
Procedure GotoNextPage()
	
	If Items.PagesUploadAssistant.CurrentPage = Items.UploadStartingPage Then
		
		If FullOrPartialUnloading = 1 Then
			
			GoToAssistantPage("PageUploadSelection"); 
			
		Else 
			
			GoToAssistantPage("PageUnloaded");
			
		EndIf;
		
	ElsIf Items.PagesUploadAssistant.CurrentPage = Items.PageUploadSelection Then
		
		GoToAssistantPage("WhatWillBeUploadedPage"); 
		
	ElsIf Items.PagesUploadAssistant.CurrentPage = Items.WhatWillBeUploadedPage Then
		
		GoToAssistantPage("PageUnloaded");
		
	ElsIf Items.PagesUploadAssistant.CurrentPage = Items.PageUnloaded Then
		
		Close();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToThePreviousPage()

	If Items.PagesUploadAssistant.CurrentPage = Items.PageUploadSelection Then 
		
		GoToAssistantPage("UploadStartingPage");
		
	ElsIf Items.PagesUploadAssistant.CurrentPage = Items.WhatWillBeUploadedPage Then
		
		GoToAssistantPage("PageUploadSelection");
		
	ElsIf Items.PagesUploadAssistant.CurrentPage = Items.PageUnloaded Then
		
		If FullOrPartialUnloading = 1 Then
			
			GoToAssistantPage("WhatWillBeUploadedPage");
			
		Else 
			
			GoToAssistantPage("UploadStartingPage");
			
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Procedure GoToAssistantPage(PageName)
	
	If PageName = "UploadStartingPage" Then
		
		GoToStartPageOfAssistant();
		
	ElsIf PageName = "PageUploadSelection" Then
		
		GoToSelectionAssistantPage();
		
	ElsIf PageName = "WhatWillBeUploadedPage" Then
		
		If ReceiptIsRequiredWhatWeAreUnloading Then 
			
			GetDataOfUploadedProcessDescriptions();
			
		Else
			
			GoToAssistantPageWhatWillBeUploaded();
			
		EndIf;
		
	ElsIf PageName = "PageUnloaded" Then
		
		If UnloadingIsRequired Then
			
			If ReceiptIsRequiredWhatWeAreUnloading Then 
			
				GetDataOfUploadedProcessDescriptions();
				
			Else
			
				StartUploadingScriptsToDirectory();
			
			EndIf;
			
		Else
			
			GoToUnloadedPage();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToSelectionAssistantPage()
	
	Items.PagesUploadAssistant.CurrentPage = Items.PageUploadSelection;
	Items.PagesFooter.CurrentPage = Items.BackNextButtonPage;
	
	InstallAssistantNavigator();
	DefineNextButtonTitle();
	DefineDefaultBasementButton();
	
EndProcedure

&AtClient
Procedure GoToStartPageOfAssistant()
	
	Items.PagesUploadAssistant.CurrentPage = Items.UploadStartingPage;
	Items.PagesFooter.CurrentPage           = Items.ClickNextPage;
	
	InstallAssistantNavigator();
	DefineNextButtonTitle();
	DefineDefaultBasementButton();
	
EndProcedure

&AtClient
Procedure GoToAssistantPageWhatWillBeUploaded()
	
	Items.PagesUploadAssistant.CurrentPage = Items.WhatWillBeUploadedPage;
	Items.PagesFooter.CurrentPage           = Items.BackNextButtonPage;
	
	InstallAssistantNavigator();
	DefineNextButtonTitle();
	DefineDefaultBasementButton();
	
EndProcedure

&AtClient
Procedure GoToUnloadedPage()
	
	Items.PagesUploadAssistant.CurrentPage = Items.PageUnloaded;
	Items.PagesFooter.CurrentPage           = Items.TheDoneButtonPage;
	
	InstallAssistantNavigator();
	DefineDefaultBasementButton();
	
EndProcedure

&AtClient
Procedure CheckAbilityToNavigateThroughPages(CommandName, Cancel)

	If Items.PagesUploadAssistant.CurrentPage = Items.UploadStartingPage
		And CommandName = "Next" Then
		
		If IsBlankString(Vendor) Then
			
			MessageText = NStr("vi = 'Chưa chỉ định nhà cung cấp cấu hình';
								|ru = 'Не указан поставщик конфигурации';
								|en = 'The configuration vendor is not specified'; fa = 'The configuration vendor is not specified';
								|it = 'Не указан поставщик конфигурации';
								|pl = 'The configuration vendor is not specified';
								|tr = 'Konfigürasyon sağlayıcısı belirtilmedi'");
			
			CommonClient.MessageToUser(MessageText,, "Vendor",, Cancel);
			
		EndIf;
		
		If IsBlankString(DumpDirectory) Then
			
			MessageText = NStr("vi = 'Chưa chỉ định thư mục kết xuất';
								|ru = 'Не указан каталог выгрузки';
								|en = 'The export directory is not specified'; fa = 'The export directory is not specified';
								|it = 'Не указан каталог выгрузки';
								|pl = 'The export directory is not specified';
								|tr = 'Dışa aktarma dizini belirtilmedi'");
			
			CommonClient.MessageToUser(MessageText,, "DumpDirectory",, Cancel);
			
		ElsIf Not DemoScenariosClientServer.FolderOnDiskExists(DumpDirectory) Then
			
			MessageText = NStr("vi = 'Không tồn tại thư mục chỉ định trên ổ đĩa';
								|ru = 'Указанный каталог на диске не существует';
								|en = 'The specified directory does not exist on the hard drive'; fa = 'The specified directory does not exist on the hard drive';
								|it = 'Указанный каталог на диске не существует';
								|pl = 'The specified directory does not exist on the hard drive';
								|tr = 'Belirtilen dizin disk üzerinde mevcut değil'");
			
			CommonClient.MessageToUser(MessageText,, "DumpDirectory",, Cancel);
			
		EndIf;
		
		If ExportMethod = 1 Then
			
			If Not ApplicationIsRunningAsTestManager Then
				
				MessageText = NStr("vi = 'Để kết xuất và thay thế liên kết đến các đối tượng bằng ảnh chụp màn hình, ứng dụng cần được khởi chạy như là ""Bộ quản lý thử nghiệm""';
									|ru = 'Для выгрузки с заменой ссылок на объекты на скриншоты требуется, чтобы приложение было запущено как ""Менеджер тестирования""';
									|en = 'To export and replace object links with screenshots, run the application as ""Test manager""'; fa = 'To export and replace object links with screenshots, run the application as ""Test manager""';
									|it = 'Для выгрузки с заменой ссылок на объекты на скриншоты требуется, чтобы приложение было запущено как ""Менеджер тестирования""';
									|pl = 'To export and replace object links with screenshots, run the application as ""Test manager""';
									|tr = 'Nesne bağlantılarının ekran görüntüleriyle değiştirilerek dışa aktarılması, uygulamanın ""Test yöneticisi"" olarak çalıştırılmasını gerektirmektedir'");
				
				CommonClient.MessageToUser(MessageText,,,, Cancel);
				
			ElsIf Not TestingClientIsConnected Then
				
				MessageText = NStr("vi = 'Để kết xuất và thay thế liên kết đến đối tượng bằng ảnh chụp màn hình, cần kết nối ""Client thử nghiệm""';
									|ru = 'Для выгрузки с заменой ссылок на объекты на скриншоты необходимо подключить ""Клиент тестирования""';
									|en = 'To export and replace object links with screenshots, connect ""Test client"".'; fa = 'To export and replace object links with screenshots, connect ""Test client"".';
									|it = 'Для выгрузки с заменой ссылок на объекты на скриншоты необходимо подключить ""Клиент тестирования""';
									|pl = 'To export and replace object links with screenshots, connect ""Test client"".';
									|tr = 'Nesne bağlantılarının ekran görüntüleriyle değiştirilerek dışa aktarılması için ""Test istemcisinin"" bağlanması gerekmektedir'");
				
				CommonClient.MessageToUser(MessageText,, ,, Cancel);
				
			EndIf;
			
		EndIf;
		
	EndIf;

EndProcedure

#EndRegion

#Region FilterUnloadedScripts

&AtClient
Procedure GetDataOfUploadedProcessDescriptions()
	
	ScriptsToUpload.GetItems().Clear();
	
	TimeConsumingOperation = GetDataOfUploadedProcessDescriptionsLongTermOperation(UUID);
	
	If TimeConsumingOperation = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	
	If TimeConsumingOperation.Status = "Completed2" Then
		
		GettingDataFromUploadedProcessDescriptionsCompletion(TimeConsumingOperation, AdditionalParameters);
		
	ElsIf TimeConsumingOperation.Status = "Running" Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		If FullOrPartialUnloading = 0 Then
			TitleText = NStr("vi = 'Chuẩn bị dữ liệu mô tả quy trình cần kết xuất';
							|ru = 'Подготовка данных описаний процессов к выгрузке';
							|en = 'Prepare process details data to export'; fa = 'Prepare process details data to export';
							|it = 'Подготовка данных описаний процессов к выгрузке';
							|pl = 'Prepare process details data to export';
							|tr = 'Dışa aktarılacak süreç ayrıntıları verilerinin hazırlanması'");
		Else
			TitleText = NStr("vi = 'Xác định mô tả quy trình được kết xuất';
							|ru = 'Определение выгружаемых описаний процессов';
							|en = 'Identify process details to export'; fa = 'Identify process details to export';
							|it = 'Определение выгружаемых описаний процессов';
							|pl = 'Identify process details to export';
							|tr = 'Dışa aktarılan süreç ayrıntılarının tanımlanması'");
		EndIf;
		IdleParameters.Title = TitleText;
		
		CallbackOnCompletion = New CallbackDescription("GettingDataFromUploadedProcessDescriptionsCompletion", ThisObject, AdditionalParameters);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
		
	EndIf;

EndProcedure

&AtServer
Function GetDataOfUploadedProcessDescriptionsLongTermOperation(Var_UUID)
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("ComposerSettings",  SettingsComposer.GetSettings());
	GenerationParameters.Insert("ThisIsFullUpload ",     FullOrPartialUnloading = 0);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(Var_UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Nhận dữ liệu mô tả quy trình được kết xuất';
														|ru = 'Получение данных выгружаемых описаний процессов';
														|en = 'Get data of process details to export'; fa = 'Get data of process details to export';
														|it = 'Получение данных выгружаемых описаний процессов';
														|pl = 'Get data of process details to export';
														|tr = 'Dışa aktarılan süreç ayrıntılarının verilerinin alınması'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground("DataProcessors.ProcessDetailsExport.GetDataFromUploadedDescriptions",
	                                                       GenerationParameters, ExecutionParameters);
	Return TimeConsumingOperation;
	
EndFunction

&AtClient
Procedure GettingDataFromUploadedProcessDescriptionsCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
	
	If Result.Status = "Completed2" Then
		ProcessReceivedDataForUploading(Result, AdditionalParameters);
	EndIf;

EndProcedure

&AtClient
Procedure ProcessReceivedDataForUploading(Result, AdditionalParameters)

	If Not IsTempStorageURL(Result.ResultAddress) Then 
		Return;
	EndIf;
	
	If ResultOfProcessingReceivedDataOnServer(Result) Then
		
		ReceiptIsRequiredWhatWeAreUnloading = False;
		
		If FullOrPartialUnloading = 1 Then
			
			GoToAssistantPageWhatWillBeUploaded();
			
		Else
			
			StartUploadingScriptsToDirectory();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function ResultOfProcessingReceivedDataOnServer(BackgroundJobExecutionResult) 
	
	DataAcquisitionResult = GetFromTempStorage(BackgroundJobExecutionResult.ResultAddress);
	
	If DataAcquisitionResult = Undefined Then
		Return False;
	EndIf;
	
	If DataAcquisitionResult.Success Then
		
		If DataAcquisitionResult.PreparedData.ProcessDescriptions <> Undefined
			And TypeOf(DataAcquisitionResult.PreparedData.ProcessDescriptions) = Type("ValueTree") Then
			
			ValueToFormAttribute(DataAcquisitionResult.PreparedData.ProcessDescriptions, "ScriptsToUpload");
			
		EndIf;
		
		If DataAcquisitionResult.PreparedData.Glossary <> Undefined
			And TypeOf(DataAcquisitionResult.PreparedData.Glossary) = Type("ValueTable") Then
			
			ValueToFormAttribute(DataAcquisitionResult.PreparedData.Glossary, "GlossariesForUploading");
			
		EndIf;
		
		Return True;
		
	Else
		
		Return False;
	
	EndIf;
	
EndFunction

#EndRegion

#Region UploadingToCatalog

&AtClient
Procedure StartUploadingScriptsToDirectory()
	
	Items.PagesAreBeingUnloadedUnloaded.CurrentPage = Items.PageIsBeingUnloaded;
	
	GoToUnloadedPage();
	
	AttachIdleHandler("UploadProcessDescriptionsToDirectory", 2, True);
	
EndProcedure 

&AtClientAtServerNoContext
Function NameOfActualUploadDirectory(DumpDirectory)

	Return DumpDirectory + "ProcessDescriptionUpload\";

EndFunction

&AtClient
Procedure UploadProcessDescriptionsToDirectory()
	
	If ScreenshotsAreRequired() Then 
		
		GetRequiredScreenshots();
		
	Else
		
		DeleteFiles(NameOfActualUploadDirectory(DumpDirectory),  GetClientAllFilesMask());
		Upload_ProcessDescriptions();
		
	EndIf;
	
EndProcedure 

&AtServer
Function ResultOfUploadingToServer(DataScreenshot)
	
	ExportResult = New Structure;
	ExportResult.Insert("DataForOutputOfProgress", UploadDataToDisplayProgress());
	ExportResult.Insert("Success",                  True);
	ExportResult.Insert("FileData",              Undefined);
	ExportResult.Insert("FileName",                 "");
	ExportResult.Insert("ErrorMessage",        "");
	
	TempFileName  = GetTempFileName();
	PathSeparator     = GetServerPathSeparator();
	ArrayOfDirectoryStrings = StrSplit(TempFileName, PathSeparator);
	
	ArrayOfDirectoryStrings.Delete(ArrayOfDirectoryStrings.Count() - 1); 
	UploadDirectoryOnServer = StrConcat(ArrayOfDirectoryStrings, PathSeparator);
	UploadDirectoryOnServer =  UploadDirectoryOnServer + PathSeparator + "DesriptionUnload" + PathSeparator;
	
	Try
		
		If Not DemoScenariosClientServer.FolderOnDiskExists(UploadDirectoryOnServer) Then
			CreateDirectory(UploadDirectoryOnServer);
		Else
			DeleteFiles(UploadDirectoryOnServer, GetServerAllFilesMask());
		EndIf;
		
		For Each FormTreeRow In ScriptsToUpload.GetItems() Do
			
			ProcessDescriptionDirectoryName = UploadDirectoryOnServer 
			                               + DemoScenariosClientServer.NameOfProcessDescriptionUploadDirectory()
			                               + PathSeparator;
			
			If Not DemoScenariosClientServer.FolderOnDiskExists(ProcessDescriptionDirectoryName) Then
				CreateDirectory(ProcessDescriptionDirectoryName);
			EndIf;
			
			UploadLineFromDescriptionTreeToFolder(FormTreeRow, ProcessDescriptionDirectoryName, ExportResult.DataForOutputOfProgress, PathSeparator);
			
		EndDo;
		
		For Each TableRow In GlossariesForUploading Do
			
			ProcessDescriptionDirectoryName = UploadDirectoryOnServer + DemoScenariosClientServer.NameOfGlossaryCatalog() + PathSeparator;
			
			If Not DemoScenariosClientServer.FolderOnDiskExists(ProcessDescriptionDirectoryName) Then
				CreateDirectory(ProcessDescriptionDirectoryName);
			EndIf;
			
			UploadRowOfGlossaryTableToCatalog(TableRow, ProcessDescriptionDirectoryName, ExportResult.DataForOutputOfProgress, PathSeparator);
			
		EndDo;
		
		UploadScreenshotDataToCatalog(DataScreenshot, UploadDirectoryOnServer);
		
		UploadUploadDescriptionToCatalog(UploadDirectoryOnServer);
		
		CurrentDate = CurrentSessionDate();
		
		DateOfUploadByLine = Format(Day(CurrentDate), "NG=0") + Format(Month(CurrentDate), "NG=0") + Format(Year(CurrentDate), "NG=0");
		
		ArchiveFileName  = "UnloadDescrionsOfProcesses_" + DateOfUploadByLine + ".zip";
		FullPathArchive = UploadDirectoryOnServer + ArchiveFileName;
		
		ArchiveContentsOfDirectory(UploadDirectoryOnServer, FullPathArchive);
		DeleteUploadFiles(UploadDirectoryOnServer, FullPathArchive);
	
	Except
		
		ExportResult.Success           = False;
		ExportResult.ErrorMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		
		DeleteUploadFiles(UploadDirectoryOnServer, FullPathArchive);
		
		Return ExportResult;
	
	EndTry;
	
	ExportResult.FileName    = ArchiveFileName;
	ExportResult.FileData = PutToTempStorage(New BinaryData(FullPathArchive), UUID);
	
	Return ExportResult;
	
EndFunction

&AtClient
Procedure AfterSavingUploadedArchive(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	DataForOutputOfProgress = AdditionalParameters.DataForOutputOfProgress;
	
	DirectoryByString = StringFunctionsClient.FormattedString("<a href=""%1"">%2</a>",
	                                                              "GoToUploadDirectory",
	                                                              NameOfActualUploadDirectory(DumpDirectory));
	
	LineIsSuccessful =  NStr("vi = 'Dữ liệu đã được kết xuất thành công vào thư mục';
							|ru = 'Данные успешно выгружены в каталог';
							|en = 'The data is successfully exported to the directory.'; fa = 'The data is successfully exported to the directory.';
							|it = 'Данные успешно выгружены в каталог';
							|pl = 'The data is successfully exported to the directory.';
							|tr = 'Veriler dizine başarıyla aktarıldı'");
	StringNumberOfDescriptions  =  StrTemplate(NStr("vi = 'Đã kết xuất mô tả %1quy trình';
													|ru = 'Выгружено описаний процессов - %1';
													|en = 'Exported process details: %1'; fa = 'Exported process details: %1';
													|it = 'Выгружено описаний процессов - %1';
													|pl = 'Exported process details: %1';
													|tr = 'Süreç ayrıntıları dışa aktarıldı; %1'"), DataForOutputOfProgress.DescriptionsUploaded);
	RowNumberGlossary =  StrTemplate(NStr("vi = 'Đã kết xuất %1 phần tử thuật ngữ';
											|ru = 'Выгружено элементов глоссария - %1';
											|en = 'Exported glossary items: %1'; fa = 'Exported glossary items: %1';
											|it = 'Выгружено элементов глоссария - %1';
											|pl = 'Exported glossary items: %1';
											|tr = 'Terim sözlüğü öğeleri dışa aktarıldı; %1'"), DataForOutputOfProgress.GlossaryUploaded);;
	
	LineTotal_ = New FormattedString(LineIsSuccessful, " ", DirectoryByString, 
	                                          Chars.LF, StringNumberOfDescriptions,
	                                          Chars.LF, RowNumberGlossary);
	
	Items.DecorationResultsOfUnloading.Title = LineTotal_;
	
	Items.PagesAreBeingUnloadedUnloaded.CurrentPage = Items.PageIsFinishedUploading;
	
EndProcedure

&AtClient
Procedure Upload_ProcessDescriptions()
	
	DataScreenshot = ScreenshotDataForArchiving();
	ExportResult = ResultOfUploadingToServer(DataScreenshot);
	
	If ExportResult.Success Then
		
		If Not DemoScenariosClientServer.FolderOnDiskExists(NameOfActualUploadDirectory(DumpDirectory)) Then
			CreateDirectory(NameOfActualUploadDirectory(DumpDirectory));
		EndIf;
		
		NameOfUploadedArchive = NameOfActualUploadDirectory(DumpDirectory) + ExportResult.FileName;
		FileSavingParameters              = FileSystemClient.FileSavingParameters();
		FileSavingParameters.Interactively = False;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("DataForOutputOfProgress", ExportResult.DataForOutputOfProgress);
		DescriptionOfNotificationAfterSavingArchive = New CallbackDescription("AfterSavingUploadedArchive", ThisObject, AdditionalParameters);
		
		FileSystemClient.SaveFile(DescriptionOfNotificationAfterSavingArchive, 
		                                    ExportResult.FileData, 
		                                    NameOfUploadedArchive, 
		                                    FileSavingParameters); 
		
	Else
		
		Raise ExportResult.ErrorMessage;
		
	EndIf;
		
EndProcedure

&AtClient
Function ScreenshotDataForArchiving()
	
	DataScreenshot = New Array;
	
	DirectoryName = NameOfActualUploadDirectory(DumpDirectory) 
	              + DemoScenariosClientServer.NameOfUploadFolderScreenshots() 
	              + GetClientPathSeparator();
	
	FilesInDirectory = FindFiles(DirectoryName, "*.png", False);
	
	For Each FileInfo In FilesInDirectory Do
		
		ScreenshotData = New Structure;
		ScreenshotData.Insert("BinaryData",        New BinaryData(FileInfo.FullName)); 
		ScreenshotData.Insert("FileName",              FileInfo.Name);
		
		DataScreenshot.Add(ScreenshotData);
		
	EndDo;
	
	DeleteFiles(NameOfActualUploadDirectory(DumpDirectory), GetClientAllFilesMask());
	
	Return DataScreenshot;
	
EndFunction

&AtServerNoContext
Procedure ArchiveContentsOfDirectory(UploadDirectoryOnServer, ArchiveName)
	
	ZipFileWriter = New ZipFileWriter(ArchiveName); 
	
	ZipFileWriter.Add(UploadDirectoryOnServer + "*", ZIPStorePathMode.StoreRelativePath, ZIPSubDirProcessingMode.ProcessRecursively);
	ZipFileWriter.Write();
	
EndProcedure

&AtServer
Procedure DeleteUploadFiles(UploadDirectoryOnServer, ArchiveName)
	
	FilesInDirectory = FindFiles(UploadDirectoryOnServer, GetClientAllFilesMask(), False);
	
	For Each FileInDirectory In FilesInDirectory Do
		
		If FileInDirectory.FullName = ArchiveName Then
			Continue;
		EndIf;
		
		DeleteFiles(FileInDirectory.FullName);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure UploadScreenshotDataToCatalog(DataScreenshot, UploadDirectoryOnServer)
	
	PathSeparator = GetServerPathSeparator();
	
	FolderNameScreenshots = UploadDirectoryOnServer 
	                       + DemoScenariosClientServer.NameOfUploadFolderScreenshots()
	                       + PathSeparator;
	
	If Not DemoScenariosClientServer.FolderOnDiskExists(FolderNameScreenshots) Then
		CreateDirectory(FolderNameScreenshots);
	EndIf;
	
	For Each ScreenshotData In DataScreenshot Do
		
		FileName = FolderNameScreenshots + ScreenshotData.FileName;
		ScreenshotData.BinaryData.Write(FileName);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure UploadUploadDescriptionToCatalog(UploadDirectoryOnServer)
	
	JSONTextDescriptionOfUpload = JSONTextUploadData();
	
	FileName = UploadDirectoryOnServer + DemoScenariosClientServer.FileNameUploadDescription();
	
	TextWriter = New TextWriter(FileName);
	TextWriter.Write(JSONTextDescriptionOfUpload);
	TextWriter.Close();
	
EndProcedure

&AtServer
Function UploadDataToDisplayProgress()

	DataForOutputOfProgress = New Structure;
	DataForOutputOfProgress.Insert("ForExport", 1);
	DataForOutputOfProgress.Insert("WasExported", 0);
	DataForOutputOfProgress.Insert("DescriptionsUploaded", 0);
	DataForOutputOfProgress.Insert("GlossaryUploaded", 0);
	
	For Each FormTreeRow In ScriptsToUpload.GetItems() Do
		
		ProcessProgressOutputDataForRowInProcessDescriptionTree(FormTreeRow, DataForOutputOfProgress);
		
	EndDo;
	
	DataForOutputOfProgress.ForExport = DataForOutputOfProgress.ForExport + GlossariesForUploading.Count();
	
	Return DataForOutputOfProgress;
	
EndFunction 

&AtServer
Procedure ProcessProgressOutputDataForRowInProcessDescriptionTree(FormTreeRow, DataForOutputOfProgress)
	
	If FormTreeRow.ScenarioDescriptions.Count() > 0 Then
		
		DataForOutputOfProgress.ForExport = DataForOutputOfProgress.ForExport + 1;
		
	EndIf;
	
	For Each SubordinateRow In FormTreeRow.GetItems() Do
		
		ProcessProgressOutputDataForRowInProcessDescriptionTree(SubordinateRow, DataForOutputOfProgress)
		
	EndDo;
	
EndProcedure

&AtServer
Procedure UploadRowOfGlossaryTableToCatalog(TableRow, DumpDirectory, DataForOutputOfProgress, PathSeparator)
	
	DirectoryOfThisLine = DumpDirectory 
	                   + TableRow.UUID 
	                   + PathSeparator;
	
	If Not DemoScenariosClientServer.FolderOnDiskExists(DirectoryOfThisLine) Then
		
		CreateDirectory(DirectoryOfThisLine);
		
	EndIf;
	
	UploadAttributesToCatalog(TableRow.AttributesOfGlossary, DirectoryOfThisLine, TableRow.UUID); 
	
	For Each FileData In TableRow.GlossaryDetails Do
		
		UploadDescriptionInLanguageToCatalog(FileData, DirectoryOfThisLine, TableRow.UUID);
		
	EndDo; 
	
	DataForOutputOfProgress.GlossaryUploaded = DataForOutputOfProgress.GlossaryUploaded +1;
	
EndProcedure

&AtServer
Procedure UploadLineFromDescriptionTreeToFolder(FormTreeRow, DumpDirectory, DataForOutputOfProgress, PathSeparator)
	
	YouNeedToCreateDirectory = True;
	
	ParentRow = FormTreeRow.GetParent();
	If ParentRow <> Undefined 
		And ParentRow.FullCode = FormTreeRow.FullCode Then
		
		YouNeedToCreateDirectory = False;
		
	EndIf;
	
	If YouNeedToCreateDirectory Then
		
		DirectoryOfThisLine = DumpDirectory 
		                   + DemoScenariosClientServer.FullLineCodeForFileName(FormTreeRow.FullCode)
		                   + "_"
		                   + FormTreeRow.HashOfId
		                   + PathSeparator;
		
	Else
		
		DirectoryOfThisLine = DumpDirectory;
		
	EndIf;
		
	If Not DemoScenariosClientServer.FolderOnDiskExists(DirectoryOfThisLine) Then
		
		CreateDirectory(DirectoryOfThisLine);
		
	EndIf;
	
	UploadAttributesToCatalog(FormTreeRow.ScriptDetails, DirectoryOfThisLine, FormTreeRow.UUID);
	
	For Each FileData In FormTreeRow.ScenarioDescriptions Do
		
		UploadDescriptionInLanguageToCatalog(FileData, DirectoryOfThisLine, FormTreeRow.UUID);
		
	EndDo;
	
	If FormTreeRow.ScenarioDescriptions.Count() > 0 Then
		
		DataForOutputOfProgress.DescriptionsUploaded = DataForOutputOfProgress.DescriptionsUploaded +1;
		
	EndIf;
	
	For Each SubordinateRow In FormTreeRow.GetItems() Do
		
		UploadLineFromDescriptionTreeToFolder(SubordinateRow, DirectoryOfThisLine, DataForOutputOfProgress, PathSeparator);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure UploadDescriptionInLanguageToCatalog(FileData,DirectoryOfThisLine, Var_UUID)
	
	FileName = DirectoryOfThisLine + FileData.LanguageCode + "_" + Var_UUID + ".html";
	
	TextWriter = New TextWriter(FileName);
	TextWriter.Write(FileData.HTMLText);
	TextWriter.Close();
	
EndProcedure

&AtServer
Procedure UploadAttributesToCatalog(ScriptDetails, DirectoryOfThisLine, Var_UUID)

	FileName = DirectoryOfThisLine + "Requisites_" + Var_UUID + ".json";
	
	TextWriter = New TextWriter(FileName);
	TextWriter.Write(ScriptDetails);
	TextWriter.Close()

EndProcedure

&AtServer
Function JSONTextUploadData()
	
	DataWriter = New JSONWriter;
	DataWriter.SetString();
	
	DataWriter.WriteStartObject();
	
	DataWriter.WritePropertyName("ConfigurationDescription");
	DataWriter.WriteValue(DeliveryInformation);
	
	DataWriter.WritePropertyName("Supplier");
	DataWriter.WriteValue(Vendor);
	
	DataWriter.WritePropertyName("Partial");
	DataWriter.WriteValue(FullOrPartialUnloading = 1); 
	
	DataWriter.WriteEndObject();
	
	JSONText = DataWriter.Close();
	
	Return JSONText;
	
EndFunction

#EndRegion 

#Region GettingScreenshots

&AtClient
Function ScreenshotsAreRequired()
	
	Return ExportMethod = 1;
	
EndFunction

&AtClient
Procedure GetRequiredScreenshots()
	
	DeleteFiles(NameOfActualUploadDirectory(DumpDirectory), GetClientAllFilesMask());
	
	If Not DemoScenariosClientServer.FolderOnDiskExists(NameOfActualUploadDirectory(DumpDirectory)) Then
		CreateDirectory(NameOfActualUploadDirectory(DumpDirectory));
	EndIf;
	
	PrepareTheseObjectsToGetScreenshots()
	
EndProcedure
	
&AtClient
Procedure PrepareTheseObjectsToGetScreenshots()
	
	ObjectsScreenshots.Clear();
	
	TimeConsumingOperation = PrepareTheseObjectsToGetScreenshotsLongTermOperation(UUID);
	
	If TimeConsumingOperation = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	
	If TimeConsumingOperation.Status = "Completed2" Then
		
		PreparingTheseObjectsForScreenshotsCompletion(TimeConsumingOperation, AdditionalParameters);
		
	ElsIf TimeConsumingOperation.Status = "Running" Then
		
		TitleText = NStr("vi = 'Phân tích các mô tả được kết xuất để tạo ảnh chụp màn hình';
						|ru = 'Разбор выгружаемых описаний для формирования скриншотов';
						|en = 'Analysis of details to export to generate screenshots'; fa = 'Analysis of details to export to generate screenshots';
						|it = 'Разбор выгружаемых описаний для формирования скриншотов';
						|pl = 'Analysis of details to export to generate screenshots';
						|tr = 'Ekran görüntülerinin oluşturulması için dışa aktarılan ayrıntıların ayrıştırılması'");
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.Title = TitleText;
		
		CallbackOnCompletion = New CallbackDescription("PreparingTheseObjectsForScreenshotsCompletion", ThisObject, AdditionalParameters);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
		
	EndIf;

EndProcedure

&AtServer
Function PrepareTheseObjectsToGetScreenshotsLongTermOperation(Var_UUID)
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("ScriptsToUpload", DataFromScenarioDescriptionsForGettingNavigationLinks());
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(Var_UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Nhận tham chiếu dẫn hướng để tạo ảnh chụp màn hình khi kết xuất';
														|ru = 'Получение навигационных ссылок для формирования скриншотов при выгрузке';
														|en = 'Get URLs for generating screenshots during export'; fa = 'Get URLs for generating screenshots during export';
														|it = 'Получение навигационных ссылок для формирования скриншотов при выгрузке';
														|pl = 'Get URLs for generating screenshots during export';
														|tr = 'Dışa aktarma sırasında ekran görüntülerinin oluşturulması için gezinme bağlantılarının alınması'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground("DataProcessors.ProcessDetailsExport.GetNavigationLinksFromDescriptions",
	                                                       GenerationParameters, ExecutionParameters);
	Return TimeConsumingOperation;
	
EndFunction 

&AtServer
Function DataFromScenarioDescriptionsForGettingNavigationLinks()
	
	DataOfDescriptions = New Array;
	
	For Each TreeRow In ScriptsToUpload.GetItems() Do
		
		 AddDescriptionDataToGetNavigationLinksOnTreeLine(TreeRow, DataOfDescriptions);
		
	EndDo;
	 
	Return DataOfDescriptions;
	
EndFunction

&AtServer
Procedure  AddDescriptionDataToGetNavigationLinksOnTreeLine(TreeRow, DataOfDescriptions)
	
	DetailsList1 = New Array;
	
	For Each StringWithDescription In TreeRow.ScenarioDescriptions Do
		
		DescriptionData = New Structure;
		DescriptionData.Insert("LanguageCode", StringWithDescription.LanguageCode);
		DescriptionData.Insert("HTMLText", StringWithDescription.HTMLText);
		
		DetailsList1.Add(DescriptionData);
		
	EndDo;
	
	If DetailsList1.Count() > 0 Then 
		
		DataByScenario = New Structure;
		DataByScenario.Insert("Scenario",            TreeRow.Scenario); 
		DataByScenario.Insert("RowID", TreeRow.GetID());
		DataByScenario.Insert("DetailsList1",            DetailsList1);
		
		DataOfDescriptions.Add(DataByScenario);
		
	EndIf;
	
	For Each SubordinateRow In  TreeRow.GetItems() Do
		
		 AddDescriptionDataToGetNavigationLinksOnTreeLine(SubordinateRow, DataOfDescriptions);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure PreparingTheseObjectsForScreenshotsCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
	
	If Result.Status = "Completed2" Then
		ProcessReceivedDataToGetScreenshots(Result, AdditionalParameters);
	EndIf;

EndProcedure 

&AtClient
Procedure ProcessReceivedDataToGetScreenshots(Result, AdditionalParameters)

	If Not IsTempStorageURL(Result.ResultAddress) Then 
		Return;
	EndIf;
	
	DataForGettingScreenshots = GetFromTempStorage(Result.ResultAddress);
	
	If Not DataForGettingScreenshots.Success Then
		Return;
	EndIf;
	
	GetScreenshotsBasedOnNavigationLinksInDescriptions(DataForGettingScreenshots.PreparedData);
	
EndProcedure 

&AtClient
Procedure GetScreenshotsBasedOnNavigationLinksInDescriptions(DataForGettingScreenshots)
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("TestingClientPortNumber",        TestingClientPortNumber);
	OpeningParameters.Insert("TestClientConnectionString", TestClientConnectionString);
	OpeningParameters.Insert("TestClientStartupTimeout",   TestClientStartupTimeout);
	OpeningParameters.Insert("DataForGettingScreenshots",        DataForGettingScreenshots);
	OpeningParameters.Insert("DirectoryName",                         NameOfActualUploadDirectory(DumpDirectory));
	OpeningParameters.Insert("OpeningMode",                       "GettingScreenshots");
	
	NotificationAfterClosingTestClientSettings = New CallbackDescription("GettingScreenshotsCompletion",ThisObject);
	
	OpenForm("DataProcessor.ProcessDetailsExport.Form.OperationWithTestClient", OpeningParameters, ThisObject,,,,
	             NotificationAfterClosingTestClientSettings, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure GettingScreenshotsCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Success 
		And IsTempStorageURL(Result.AddressScreenshotData) Then
		ReplaceLinksToObjectsWithLinksToScreenshots(Result.AddressScreenshotData);
		Upload_ProcessDescriptions();
	EndIf; 
	
EndProcedure 

&AtServer
Procedure ReplaceLinksToObjectsWithLinksToScreenshots(AddressScreenshotData)
	
	DataScreenshot = GetFromTempStorage(AddressScreenshotData);
	
	If TypeOf(DataScreenshot) <> Type("ValueTable") Then
		
		Return;
		
	EndIf; 
	
	For Each ScreenshotDataLine In DataScreenshot Do
		
		ReplaceLinkToObjectWithScreenshotsInDescriptions(ScreenshotDataLine);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ReplaceLinkToObjectWithScreenshotsInDescriptions(ScreenshotDataLine) 
	
	LineWithLinksToScreenshots = "";
	
	TemplateStringLinkToCurScreenshot = "<a href=""e1cib/data/Catalog.DemoScenariosAttachedFiles?UUID""> ScreenshotNumber </a>";
	ScreenshotNumber = 1;
	
	For Each ScreenshotDataRow In ScreenshotDataLine.Screenshots Do
		
		If ScreenshotNumber = 1 Then
			 LineWithLinksToScreenshots = LineWithLinksToScreenshots + " (";
		 Else
			 LineWithLinksToScreenshots = LineWithLinksToScreenshots + "<span> </span>";
		EndIf;
		
		LineNumberOfScreenshot = String(ScreenshotNumber);
		
		LineWithLinkToCurScreenshot = StrReplace(TemplateStringLinkToCurScreenshot,"UUID", ScreenshotDataRow.ScreenshotID);
		LineWithLinkToCurScreenshot = StrReplace(LineWithLinkToCurScreenshot,
		                                               "ScreenshotNumber", 
		                                              ?(ScreenshotNumber > 1, "," +  LineNumberOfScreenshot, LineNumberOfScreenshot));
		
		LineWithLinksToScreenshots = LineWithLinksToScreenshots + LineWithLinkToCurScreenshot;
		ScreenshotNumber = ScreenshotNumber + 1;
		
	EndDo;
	
	If ScreenshotDataLine.Screenshots.Count() > 0 Then
		 LineWithLinksToScreenshots = LineWithLinksToScreenshots + ")";
	EndIf;
	
	For Each DescriptionDataLine In  ScreenshotDataLine.BudgetingScenarios Do
		
		TreeLineOfUnloadedScripts = ScriptsToUpload.FindByID(DescriptionDataLine.RowID);
		If TreeLineOfUnloadedScripts = Undefined Then
			 Continue;
		 EndIf;
		 
		SearchParameters = New Structure;
		SearchParameters.Insert("LanguageCode", DescriptionDataLine.LanguageCode);
		
		FoundRows = TreeLineOfUnloadedScripts.ScenarioDescriptions.FindRows(SearchParameters); 
		
		For Each FoundRow In FoundRows Do
			
			ReplaceLinkToObjectWithScreenshotsForDescription(FoundRow, ScreenshotDataLine, LineWithLinksToScreenshots);
			
		EndDo;
		
	EndDo;
	
EndProcedure 

&AtServer
Procedure ReplaceLinkToObjectWithScreenshotsForDescription(DetailsString, ScreenshotDataLine, LineWithLinksToScreenshots)
	
	HyperlinkPosition = StrFind(DetailsString.HTMLText, ScreenshotDataLine.URL);
	
	While HyperlinkPosition > 0 Do
		
		 DetailsString.HTMLText = Left(DetailsString.HTMLText, HyperlinkPosition -8)
		                          + "span"
		                          + Right(DetailsString.HTMLText, StrLen(DetailsString.HTMLText) - HyperlinkPosition - StrLen(ScreenshotDataLine.URL));
		
		PositionOfEndOfHyperlink =  StrFind(DetailsString.HTMLText, "</a", SearchDirection.FromBegin, HyperlinkPosition);
		
		DetailsString.HTMLText = Left(DetailsString.HTMLText, PositionOfEndOfHyperlink  - 1)
		                          + "</span>"
		                          + LineWithLinksToScreenshots
		                          + Right(DetailsString.HTMLText, StrLen(DetailsString.HTMLText) -3 - PositionOfEndOfHyperlink);
		 
		 HyperlinkPosition = StrFind(DetailsString.HTMLText, ScreenshotDataLine.URL);
		 
	EndDo;

EndProcedure

#EndRegion 

#EndRegion
