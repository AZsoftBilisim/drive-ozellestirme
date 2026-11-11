#Region FormEventHandlers 

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ServerAddress = AnalyticsSystem.GetAnalyticsSystemServerAddress(); 
	
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	
	PerformUpdateFromAnalytics();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SwitchSettingsSourceOnChange(Item)
	
	SetVisibilityOfElementsWhenSwitchingSource(SourceFromFile);
	
	If SourceFromFile = 0 Then
		SelectedStatesOwnersReceiver.Clear();
		For Each String In StateTableOfOwnersOfReceiver Do
			String.Check = False;
		EndDo;
		StatesOfOwnersOfReceiver = "";
	EndIf;
	
	UpdateTablesWhenSwitchingSettingsSource();
	
	SourceFromFileBeforeChange = SourceFromFile;
	
EndProcedure

&AtClient
Procedure PanelFileStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	BeforeUpdatingSourceTree();
	
	CallbackDescription = New CallbackDescription(
		"PanelsFileExtensionIsEnabled",
		ThisObject);
	
	FileSystemClient.AttachFileOperationsExtension(CallbackDescription);
	
EndProcedure

&AtClient
Procedure PanelFileClearing(Item, StandardProcessing)
	
	OwnersOfSourcePanels = "";
	SelectedOwnersSource.Clear();
	OwnersOfAnalyticsFromFile.Clear();
	DashboardsFromFile.Clear();
	DiagramsFromFile.Clear();
	AnalyticsObjectsFromFile.Clear();
	PanelsFromFile.Clear();
	FoldersFromFile.Clear();
	TableOfOwnersSource.Clear();
	SourcePanels.GetItems().Clear();
	
EndProcedure

&AtClient
Procedure ServerAddressHyperlinkClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	InformationLink = ServerAddress;
	FileSystemClient.OpenURL(InformationLink);
	
EndProcedure

&AtClient
Procedure OwnersOfReceiverPanelsStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	BeforeUpdatingReceiverTree();
	
	FormParameters = New Structure;
	FormParameters.Insert("AddressInTempStorage", FormTableToTemporaryStorage(ReceiverOwnersTable));
	
	OpenForm("DataProcessor.Manage1CAnalyticsPanels.Form.FilterByOwners",
				FormParameters,
				ThisObject,,,,
				New CallbackDescription("UpdateSelectedReceiverOwners", ThisObject), 
				FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure OwnersOfSourcePanelsStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	BeforeUpdatingSourceTree();
	
	FormParameters = New Structure;
	FormParameters.Insert("AddressInTempStorage", FormTableToTemporaryStorage(TableOfOwnersSource));
	
	OpenForm("DataProcessor.Manage1CAnalyticsPanels.Form.FilterByOwners",
				FormParameters,
				ThisObject,,,,
				New CallbackDescription("UpdateSelectedOwnersSource", ThisObject), 
				FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure OwnersOfSourcePanelsClearing(Item, StandardProcessing)
	
	BeforeUpdatingSourceTree();
	
	If SelectedOwnersSource.Count() Then
		OwnersOfSourcePanelsClearingServer();
		ExpandSourcePanel();
	EndIf;
	
EndProcedure

&AtClient
Procedure OwnersOfReceiverPanelsClearing(Item, StandardProcessing)
	
	BeforeUpdatingReceiverTree();
	
	If SelectedOwnersReceiver.Count() Then
		OwnersOfReceiverPanelsClearingServer();
		ExpandReceiverPanel();
	EndIf;
	
EndProcedure

&AtClient
Procedure StatesOfOwnersOfReceiverStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	BeforeUpdatingReceiverTree();
	
	FormParameters = New Structure;
	FormParameters.Insert("AddressInTempStorage", FormTableToTemporaryStorage(StateTableOfOwnersOfReceiver));
	
	OpenForm("DataProcessor.Manage1CAnalyticsPanels.Form.FilterByStates",
				FormParameters,
				ThisObject,,,,
				New CallbackDescription("UpdateSelectedStatesOfOwnersOfReceiver", ThisObject), 
				FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure StatesOfOwnersOfReceiverClearing(Item, StandardProcessing)
	
	BeforeUpdatingReceiverTree();
	
	If SelectedStatesOwnersReceiver.Count() Then
		StatesOfOwnersOfReceiverClearingServer();
		ExpandReceiverPanel();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReceiverPanels

&AtClient
Procedure ReceiverPanelsOnActivateRow(Item)
	
	If SourceFromFile > 0 Then
		
		CurrentData = Item.CurrentData;
		If CurrentData = Undefined Then
			Return;
		EndIf;
		
		LineNumber = TreeRowNumberById(SourcePanels, CurrentData.Id);
		If LineNumber <> Undefined Then
			Items.SourcePanels.CurrentRow = LineNumber;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdatePanelsFromAnalytics(Command)
	
	PerformUpdateFromAnalytics();
	
EndProcedure

&AtClient
Procedure CopyPanel(Command)
	
	CheckFilling();
	
	SelectedObject = Items.SourcePanels.CurrentData;
	
	If SourceFromFile Then
		If SelectedObject = Undefined 
			Or SelectedObject.Type <> "chart" And SelectedObject.Type <> "dashboard" And SelectedObject.Type <> "folder" Then
			CommonClient.MessageToUser(NStr("vi = 'Hãy chọn thanh lệnh hoặc thư mục trong nguồn';
											|ru = 'Выберите панель или папку в источнике';
											|en = 'Select a panel or folder in the source'; fa = 'Select a panel or folder in the source';
											|it = 'Выберите панель или папку в источнике';
											|pl = 'Select a panel or folder in the source';
											|tr = 'Kaynakta panel veya klasör seçin'"));
			Return;
		EndIf;
	Else
		If SelectedObject.Type = "folder" Then
			CommonClient.MessageToUser(NStr("vi = 'Chỉ có thể sao chép thư mục từ tệp';
											|ru = 'Копирование папки возможно только из файла';
											|en = 'You can only copy a folder from a file'; fa = 'You can only copy a folder from a file';
											|it = 'Копирование папки возможно только из файла';
											|pl = 'You can only copy a folder from a file';
											|tr = 'Klasörü sadece dosyadan kopyalamak mümkündür'"));
			Return;
		ElsIf  SelectedObject.Type <> "chart" And SelectedObject.Type <> "dashboard" Then
			CommonClient.MessageToUser(NStr("vi = 'Hãy chọn thanh lệnh trong nguồn';
											|ru = 'Выберите панель в источнике';
											|en = 'Select a panel in the source'; fa = 'Select a panel in the source';
											|it = 'Выберите панель в источнике';
											|pl = 'Select a panel in the source';
											|tr = 'Kaynakta panel seçin'"));
			Return;
		EndIf;
	EndIf;
	
	ObjectID = SelectedObject.Id;
	
	CheckingForTransferOfPanels = CheckingForTransferOfPanels(ObjectID);
	
	PossibleOwners = CheckingForTransferOfPanels.PossibleOwners;
	ThereAreAvailableForTransfer = CheckingForTransferOfPanels.ThereAreAvailableForTransfer;
	ThereAreThoseThatAreNotAvailableForTransfer = CheckingForTransferOfPanels.ThereAreThoseThatAreNotAvailableForTransfer;
	ThereAreReplacements = CheckingForTransferOfPanels.ThereAreReplacements;
	
	If (ThereAreAvailableForTransfer And ThereAreThoseThatAreNotAvailableForTransfer) Or ThereAreReplacements Then
		
		If ThereAreThoseThatAreNotAvailableForTransfer And ThereAreReplacements Then
			QueryText = NStr("vi = 'Có các đối tượng không hợp lệ để chuyển và đối tượng được thay thế. Tiếp tục?';
							|ru = 'Есть недоступные объекты к переносу и замещаемые объекты. Продолжить?';
							|en = 'There are objects unavailable for transfer and replaceable objects. Continue?'; fa = 'There are objects unavailable for transfer and replaceable objects. Continue?';
							|it = 'Есть недоступные объекты к переносу и замещаемые объекты. Продолжить?';
							|pl = 'There are objects unavailable for transfer and replaceable objects. Continue?';
							|tr = 'Aktarım için kullanılamayan nesneler ve yedek nesneler var. Devam edilsin mi?'");
		ElsIf ThereAreThoseThatAreNotAvailableForTransfer And Not ThereAreReplacements Then
			QueryText = NStr("vi = 'Có các đối tượng không hợp lệ để chuyển. Tiếp tục?';
							|ru = 'Есть недоступные объекты к переносу. Продолжить?';
							|en = 'There are objects unavailable for transfer. Continue?'; fa = 'There are objects unavailable for transfer. Continue?';
							|it = 'Есть недоступные объекты к переносу. Продолжить?';
							|pl = 'There are objects unavailable for transfer. Continue?';
							|tr = 'Aktarım için kullanılamayan nesneler var. Devam edilsin mi?'");
		ElsIf Not ThereAreThoseThatAreNotAvailableForTransfer And ThereAreReplacements Then
			QueryText = NStr("vi = 'Có các đối tượng được thay thế. Tiếp tục?';
							|ru = 'Есть замещаемые объекты. Продолжить?';
							|en = 'There are replaceable objects. Continue?'; fa = 'There are replaceable objects. Continue?';
							|it = 'Есть замещаемые объекты. Продолжить?';
							|pl = 'There are replaceable objects. Continue?';
							|tr = 'Yedek nesneler var. Devam edilsin mi?'");
		EndIf;
		
		NotificationParameters = New Structure;
		NotificationParameters.Insert("ObjectID", ObjectID);
		NotificationParameters.Insert("PossibleOwners", PossibleOwners);
		Notification = New CallbackDescription("AfterConfirmingTransferOfPanels", ThisObject, NotificationParameters);
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
		
	ElsIf SourceFromFile And PossibleOwners.Count() > 1 Then
		
		FormParameters = New Structure;
		FormParameters.Insert("AddressInTempStorage", PutToTempStorage(PossibleOwners, UUID));
		
		OpenForm("DataProcessor.Manage1CAnalyticsPanels.Form.SelectOwnerForPanels",
					FormParameters,
					ThisObject,,,,
					New CallbackDescription("OwnerForNewPanelsIsSelected", ThisObject, ObjectID), 
					FormWindowOpeningMode.LockOwnerWindow);
		
	ElsIf SourceFromFile And PossibleOwners.Count() Then
					
		ExecuteCopyPanel(ObjectID, PossibleOwners[0]);
					
	Else
					
		ExecuteCopyPanel(ObjectID, Undefined);
		
	EndIf;
	
EndProcedure 

&AtClient
Procedure CreateLinkToPanel(Command)
	
	CheckFilling();
	
	SelectedObject = Items.SourcePanels.CurrentData;
	
	If SourceFromFile Then
		CommonClient.MessageToUser(NStr("vi = 'Đối với các thanh lệnh, không thể tạo tham chiếu từ tệp';
										|ru = 'Для панелей из файла нельзя создавать ссылку';
										|en = 'Cannot create a link for panels from a file'; fa = 'Cannot create a link for panels from a file';
										|it = 'Для панелей из файла нельзя создавать ссылку';
										|pl = 'Cannot create a link for panels from a file';
										|tr = 'Dosya üzerinden paneller için bağlantı oluşturulamaz'"));
		Return;
	EndIf;
	
	If SelectedObject = Undefined 
		Or SelectedObject.Type <> "chart" And SelectedObject.Type <> "dashboard" And SelectedObject.Type <> "folder" Then
		CommonClient.MessageToUser(NStr("vi = 'Hãy chọn thanh lệnh hoặc thư mục trong nguồn';
										|ru = 'Выберите панель или папку в источнике';
										|en = 'Select a panel or folder in the source'; fa = 'Select a panel or folder in the source';
										|it = 'Выберите панель или папку в источнике';
										|pl = 'Select a panel or folder in the source';
										|tr = 'Kaynakta panel veya klasör seçin'"));
		Return;
	EndIf;
	
	ObjectID = SelectedObject.Id;
	
	CheckingForLinkCreation = CheckingForLinkCreation(ObjectID);
	ThereAreAvailableForProcessing = CheckingForLinkCreation.ThereAreAvailableForProcessing;
	ThereAreUnavailableForProcessing = CheckingForLinkCreation.ThereAreUnavailableForProcessing;
	
	If ThereAreAvailableForProcessing And ThereAreUnavailableForProcessing Then
		Notification = New CallbackDescription("AfterConfirmationCreateLinkToPanel", ThisObject, ObjectID);
		QueryText = NStr("vi = 'Đối với một số đối tượng chủ, không thể tạo tham chiếu. Tạo tham chiếu cho các đối tượng còn lại?';
						|ru = 'Для некоторых владельцев нельзя создать ссылки. Создать ссылки для остальных?';
						|en = 'Cannot create links for some owners. Do you want to create links for other owners?'; fa = 'Cannot create links for some owners. Do you want to create links for other owners?';
						|it = 'Для некоторых владельцев нельзя создать ссылки. Создать ссылки для остальных?';
						|pl = 'Cannot create links for some owners. Do you want to create links for other owners?';
						|tr = 'Bazı sahipler için bağlantı oluşturulamaz. Diğerleri için bağlantı oluşturulsun mu?'");
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
	Else	
		ExecuteCreationLinkToPanel(ObjectID);
	EndIf;

EndProcedure

&AtClient
Procedure CreateLinksToAllPanels(Command)
	
	CheckFilling();
	
	If SourceFromFile Then
		CommonClient.MessageToUser(NStr("vi = 'Đối với các thanh lệnh, không thể tạo tham chiếu từ tệp';
										|ru = 'Для панелей из файла нельзя создавать ссылку';
										|en = 'Cannot create a link for panels from a file'; fa = 'Cannot create a link for panels from a file';
										|it = 'Для панелей из файла нельзя создавать ссылку';
										|pl = 'Cannot create a link for panels from a file';
										|tr = 'Dosya üzerinden paneller için bağlantı oluşturulamaz'"));
		Return;
	EndIf;
	
	CheckingForLinkCreation = CheckingForLinkCreation();
	ThereAreAvailableForProcessing = CheckingForLinkCreation.ThereAreAvailableForProcessing;
	ThereAreUnavailableForProcessing = CheckingForLinkCreation.ThereAreUnavailableForProcessing;
	
	If ThereAreAvailableForProcessing And ThereAreUnavailableForProcessing Then
		Notification = New CallbackDescription("AfterConfirmationCreateLinksToAllPanels", ThisObject);
		QueryText = NStr("vi = 'Không thể tạo tham chiếu đến một số đối tượng. Tạo tham chiếu đến các đối tượng còn lại?';
						|ru = 'На некоторые объекты нельзя создать ссылки. Создать ссылки на остальные?';
						|en = 'Cannot create links to some objects. Do you want to create links to other objects?'; fa = 'Cannot create links to some objects. Do you want to create links to other objects?';
						|it = 'На некоторые объекты нельзя создать ссылки. Создать ссылки на остальные?';
						|pl = 'Cannot create links to some objects. Do you want to create links to other objects?';
						|tr = 'Bazı nesnelere bağlantı oluşturulamaz. Diğerlerine bağlantı oluşturulsun mu?'");
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
	Else
		ExecuteCreatiinLinksOnPanel();
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveSettingsOfAllOwners(Command)
	
	SaveOwnerSettingsToFile();
	
EndProcedure 

&AtClient
Procedure SaveSettingsOfSelectedOwners(Command)
	
	SaveOwnerSettingsToFile(True); 
	
EndProcedure

&AtClient
Procedure RemoveReceiverPanel(Command)
	
	CheckFilling();
	
	SelectedObject = Items.ReceiverPanels.CurrentData;
	
	If SelectedObject = Undefined
		Or SelectedObject.Type <> "chart" And SelectedObject.Type <> "dashboard" And SelectedObject.Type <> "folder" Then
		CommonClient.MessageToUser(NStr("vi = 'Hãy chọn thanh lệnh hoặc thư mục trong nguồn';
										|ru = 'Выберите панель или папку в источнике';
										|en = 'Select a panel or folder in the source'; fa = 'Select a panel or folder in the source';
										|it = 'Выберите панель или папку в источнике';
										|pl = 'Select a panel or folder in the source';
										|tr = 'Kaynakta panel veya klasör seçin'"));
		Return;
	EndIf;
	
	RowID = SelectedObject.RowID;
	
	If Not CanDelete(RowID) Then
		CommonClient.MessageToUser(NStr("vi = 'Không thể xóa, đối tượng được kết nối thông qua truy cập chung hoặc thư mục lớp trên';
										|ru = 'Удаление невозможно, объект подключен через общий доступ или через вышестоящую папку';
										|en = 'Cannot delete as the object is connected via shared access or the parent folder'; fa = 'Cannot delete as the object is connected via shared access or the parent folder';
										|it = 'Удаление невозможно, объект подключен через общий доступ или через вышестоящую папку';
										|pl = 'Cannot delete as the object is connected via shared access or the parent folder';
										|tr = 'Silme mümkün değildir, nesne paylaşım veya bir üst klasör aracılığıyla bağlıdır'"));
		Return;
	EndIf;

	If SelectedObject.Type = "folder" Then
		QueryText = NStr("vi = 'Thư mục và các đối tượng kèm theo sẽ bị xóa, tiếp tục?';
						|ru = 'Папка и вложенные объекты будут удалены, продолжить?';
						|en = 'The folder and nested objects will be deleted. Continue?'; fa = 'The folder and nested objects will be deleted. Continue?';
						|it = 'Папка и вложенные объекты будут удалены, продолжить?';
						|pl = 'The folder and nested objects will be deleted. Continue?';
						|tr = 'Klasör ve ekli nesneler silinecektir, devam edilsin mi?'");
	Else
		QueryText = NStr("vi = 'Đối tượng sẽ bị xóa, tiếp tục?';
						|ru = 'Объект будет удален, продолжить?';
						|en = 'The object will be deleted. Continue?'; fa = 'The object will be deleted. Continue?';
						|it = 'Объект будет удален, продолжить?';
						|pl = 'The object will be deleted. Continue?';
						|tr = 'Nesne silinecektir, devam edilsin mi?'");
	EndIf;

	Notification = New CallbackDescription("AfterConfirmingRemovalOfPanel", ThisObject, RowID);
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure DownloadPanelsFromService(Command)
	
	
EndProcedure

#EndRegion

#Region Private

#Region TimeConsumingOperations

#Region UpdateFromAnalytics

&AtClient
Procedure PerformUpdateFromAnalytics()
	
	TimeConsumingOperation = UploadPanelDataToServer();
	If TimeConsumingOperation <> Undefined Then
		CallbackOnCompletion = New CallbackDescription("UpdateFromAnalyticsCompleted", ThisObject);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.Title = NStr("vi = 'Cập nhật các thanh lệnh từ Analytics';
									|ru = 'Обновление панелей из Аналитики';
									|en = 'Update panels from Analytics'; fa = 'Update panels from Analytics';
									|it = 'Обновление панелей из Аналитики';
									|pl = 'Update panels from Analytics';
									|tr = 'Boyutlar üzerinden panellerin güncellenmesi'");
		IdleParameters.OutputIdleWindow = True;
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	EndIf;
	
EndProcedure

&AtServer
Function UploadPanelDataToServer()
	
	JobParameters = UpdateParametersFromAnalytics();
	
	MethodName = "DataProcessors.Manage1CAnalyticsPanels.UploadPanelData";
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = NStr("vi = 'Cập nhật các thanh lệnh từ Analytics';
													|ru = 'Обновление панелей из Аналитики';
													|en = 'Update panels from Analytics'; fa = 'Update panels from Analytics';
													|it = 'Обновление панелей из Аналитики';
													|pl = 'Update panels from Analytics';
													|tr = 'Boyutlar üzerinden panellerin güncellenmesi'");
	StartSettings1.WaitCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteFunction(StartSettings1, MethodName, JobParameters);
	
EndFunction

&AtServer
Function UpdateParametersFromAnalytics()
	
	UpdateParametersFromAnalytics = DataProcessors.Manage1CAnalyticsPanels.UpdateParametersFromAnalytics();
	UpdateParametersFromAnalytics.OwnersOfAnalytics = FormAttributeToValue("OwnersOfAnalytics");
	UpdateParametersFromAnalytics.Dashboards = FormAttributeToValue("Dashboards");
	UpdateParametersFromAnalytics.Charts = FormAttributeToValue("Charts");
	UpdateParametersFromAnalytics.AnalyticsObjects = FormAttributeToValue("AnalyticsObjects");
	UpdateParametersFromAnalytics.Panels = FormAttributeToValue("Panels");
	UpdateParametersFromAnalytics.Folders = FormAttributeToValue("Folders");
	
	Return UpdateParametersFromAnalytics;
	
EndFunction

&AtClient
Procedure UpdateFromAnalyticsCompleted(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Result) = Type("Structure") Then
		
		If Result.Property("Messages") And Result.Messages <> Undefined Then
			For Each Message In Result.Messages Do
				Message.Message();
			EndDo;
		EndIf;
		
		If Result.Property("Status") Then
			If Result.Status = "Error" Then
				CommonClient.MessageToUser(Result.BriefErrorDescription);
			ElsIf Result.Status = "Completed2" Then
				FillInDataAfterUpdateFromAnalytics(Result.ResultAddress);
				
				UpdateReceiverPanels();
				If Not SourceFromFile Then
					UpdateSourcePanel();
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDataAfterUpdateFromAnalytics(ResultAddress)
	
	ResultStructure1 = GetFromTempStorage(ResultAddress);
	
	FillInCollectionOfFormAccordingToTableOfValues(OwnersOfAnalytics, ResultStructure1.OwnersOfAnalytics);
	FillInCollectionOfFormAccordingToTableOfValues(Dashboards, ResultStructure1.Dashboards);
	FillInCollectionOfFormAccordingToTableOfValues(Charts, ResultStructure1.Charts);
	FillInCollectionOfFormAccordingToTableOfValues(AnalyticsObjects, ResultStructure1.AnalyticsObjects);
	FillInCollectionOfFormAccordingToTableOfValues(Panels, ResultStructure1.Panels);
	FillInCollectionOfFormAccordingToTableOfValues(Folders, ResultStructure1.Folders);
	
EndProcedure

&AtServer
Procedure FillInCollectionOfFormAccordingToTableOfValues(Collection, Table)
	
	Collection.Clear();
	
	For Each String In Table Do
		NewRow = Collection.Add();
		For Each Column In Table.Columns Do //ValueTableColumn
			If Column.Name = "OtherFields" Then
				NewRow[Column.Name].Load(String[Column.Name]);
			Else
				NewRow[Column.Name] = String[Column.Name];
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion

#Region ReadingFromFile

&AtClient
Procedure PerformReadingFromFile(StorageAddress)
	
	TimeConsumingOperation = ReadingFromFileOnServer(StorageAddress);
	If TimeConsumingOperation <> Undefined Then
		CallbackOnCompletion = New CallbackDescription("ReadingFromFileIsComplete", ThisObject);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		
		If SourceFromFile = 1 Then
			TitleText = NStr("vi = 'Đọc thanh lệnh từ tệp';
							|ru = 'Чтение панелей из файла';
							|en = 'Read panels from the file'; fa = 'Read panels from the file';
							|it = 'Чтение панелей из файла';
							|pl = 'Read panels from the file';
							|tr = 'Dosya üzerinden panellerin okunması'");
		ElsIf SourceFromFile = 2 Then
			TitleText = NStr("vi = 'Đọc thanh lệnh từ dịch vụ';
							|ru = 'Чтение панелей из сервиса';
							|en = 'Read panels from the service'; fa = 'Read panels from the service';
							|it = 'Read panels from the service';
							|pl = 'Read panels from the service';
							|tr = 'Hizmet üzerinden panellerin okunması'");
		EndIf;
		
		IdleParameters.Title = TitleText;
		IdleParameters.OutputIdleWindow = True;
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	EndIf;

EndProcedure

&AtServer
Function ReadingFromFileOnServer(StorageAddress)
	
	If TypeOf(StorageAddress) = Type("Array") Then
		AddressesOfTemporaryFiles = StorageAddress;
	Else
		AddressesOfTemporaryFiles = CommonClientServer.ValueInArray(StorageAddress);
	EndIf;
	
	JobParameters = New Structure;
	JobParameters.Insert("ParametersReadingFromFile", ParametersReadingFromFile());
	JobParameters.Insert("Content", DataProcessors.Manage1CAnalyticsPanels.ContentsOfTemporaryFile(AddressesOfTemporaryFiles));
	
	MethodName = "DataProcessors.Manage1CAnalyticsPanels.LoadSourcePanelsFromJSON";
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = NStr("vi = 'Đọc thanh lệnh từ tệp';
													|ru = 'Чтение панелей из файла';
													|en = 'Read panels from the file'; fa = 'Read panels from the file';
													|it = 'Чтение панелей из файла';
													|pl = 'Read panels from the file';
													|tr = 'Dosya üzerinden panellerin okunması'");
	StartSettings1.WaitCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteFunction(StartSettings1, MethodName, JobParameters);
	
EndFunction

&AtServer
Function ParametersReadingFromFile()
	
	ParametersReadingFromFile = DataProcessors.Manage1CAnalyticsPanels.ParametersReadingFromFile();
	
	If SourceFromFile = 1 Then
		ParametersReadingFromFile.OwnersOfAnalyticsFromFile = FormAttributeToValue("OwnersOfAnalyticsFromFile");
		ParametersReadingFromFile.DashboardsFromFile           = FormAttributeToValue("DashboardsFromFile");
		ParametersReadingFromFile.DiagramsFromFile          = FormAttributeToValue("DiagramsFromFile");
		ParametersReadingFromFile.AnalyticsObjectsFromFile   = FormAttributeToValue("AnalyticsObjectsFromFile");
		ParametersReadingFromFile.PanelsFromFile             = FormAttributeToValue("PanelsFromFile");
		ParametersReadingFromFile.FoldersFromFile              = FormAttributeToValue("FoldersFromFile");
	ElsIf SourceFromFile = 2 Then
		ParametersReadingFromFile.OwnersOfAnalyticsFromFile     = FormAttributeToValue("OwnersOfAnalyticsFromService");
		ParametersReadingFromFile.DashboardsFromFile               = FormAttributeToValue("DashboardsFromService");
		ParametersReadingFromFile.DiagramsFromFile              = FormAttributeToValue("ChartsFromService");
		ParametersReadingFromFile.AnalyticsObjectsFromFile       = FormAttributeToValue("AnalyticsObjectsFromService");
		ParametersReadingFromFile.PanelsFromFile                 = FormAttributeToValue("PanelsFromService");
		ParametersReadingFromFile.FoldersFromFile                  = FormAttributeToValue("FoldersFromService");
		ParametersReadingFromFile.PanelSettingsIds = FormAttributeToValue("IdsOfSettingsOfBIPPanels"); 
	EndIf;
	
	Return ParametersReadingFromFile;
	
EndFunction

&AtClient
Procedure ReadingFromFileIsComplete(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Result) = Type("Structure") Then
		
		If Result.Property("Messages") And Result.Messages <> Undefined Then
			For Each Message In Result.Messages Do
				Message.Message();
			EndDo;
		EndIf;
		
		If Result.Property("Status") Then
			If Result.Status = "Error" Then
				CommonClient.MessageToUser(Result.BriefErrorDescription);
			ElsIf Result.Status = "Completed2" Then
				FillInDataAfterReadingFromFile(Result.ResultAddress);
				UpdateCacheOfCurrentDates(Result.ResultAddress);
				
				UpdateSourceOwnerTable();
				BeforeUpdatingSourceTree();
				UpdateSourcePanelTree();
				ExpandSourcePanel();
				
				UpdateReceiverOwnerTable();
				BeforeUpdatingReceiverTree();
				UpdateTreeOfReceiverPanels();
				ExpandReceiverPanel();
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDataAfterReadingFromFile(ResultAddress)
	
	ResultStructure1 = GetFromTempStorage(ResultAddress);
	
	If SourceFromFile = 1 Then
		FillInCollectionOfFormAccordingToTableOfValues(OwnersOfAnalyticsFromFile, ResultStructure1.OwnersOfAnalyticsFromFile);
		FillInCollectionOfFormAccordingToTableOfValues(DashboardsFromFile,           ResultStructure1.DashboardsFromFile);
		FillInCollectionOfFormAccordingToTableOfValues(DiagramsFromFile,          ResultStructure1.DiagramsFromFile);
		FillInCollectionOfFormAccordingToTableOfValues(AnalyticsObjectsFromFile,   ResultStructure1.AnalyticsObjectsFromFile);
		FillInCollectionOfFormAccordingToTableOfValues(PanelsFromFile,             ResultStructure1.PanelsFromFile);
		FillInCollectionOfFormAccordingToTableOfValues(FoldersFromFile,              ResultStructure1.FoldersFromFile);
	ElsIf SourceFromFile = 2 Then
		FillInCollectionOfFormAccordingToTableOfValues(OwnersOfAnalyticsFromService, ResultStructure1.OwnersOfAnalyticsFromFile);
		FillInCollectionOfFormAccordingToTableOfValues(DashboardsFromService,           ResultStructure1.DashboardsFromFile);
		FillInCollectionOfFormAccordingToTableOfValues(ChartsFromService,          ResultStructure1.DiagramsFromFile);
		FillInCollectionOfFormAccordingToTableOfValues(AnalyticsObjectsFromService,   ResultStructure1.AnalyticsObjectsFromFile);
		FillInCollectionOfFormAccordingToTableOfValues(PanelsFromService,             ResultStructure1.PanelsFromFile);
		FillInCollectionOfFormAccordingToTableOfValues(FoldersFromService,              ResultStructure1.FoldersFromFile);
		
		ValueToFormAttribute(ResultStructure1.PanelSettingsIds, "IdsOfSettingsOfBIPPanels");
	EndIf;
	
EndProcedure

#EndRegion

#Region CreatingLink

&AtClient
Procedure ExecuteCreationLinkToPanel(ObjectID)
	
	TimeConsumingOperation = CreateLinkToDashboardOnServer(ObjectID);
	If TimeConsumingOperation <> Undefined Then
		CallbackOnCompletion = New CallbackDescription("CreationOfLinkToPanelIsComplete", ThisObject);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.Title = NStr("vi = 'Tạo tham chiếu đến thanh lệnh';
									|ru = 'Создание ссылки на панель';
									|en = 'Create a link to the panel'; fa = 'Create a link to the panel';
									|it = 'Создание ссылки на панель';
									|pl = 'Create a link to the panel';
									|tr = 'Panel bağlantısı oluşturma'");
		IdleParameters.OutputIdleWindow = True;
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	EndIf;
	
EndProcedure

&AtServer
Function CreateLinkToDashboardOnServer(ObjectID)
	
	JobParameters = RefCreationParameters(ObjectID);
	
	MethodName = "DataProcessors.Manage1CAnalyticsPanels.CreateLinkToPanel";
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = NStr("vi = 'Tạo tham chiếu đến thanh lệnh';
													|ru = 'Создание ссылки на панель';
													|en = 'Create a link to the panel'; fa = 'Create a link to the panel';
													|it = 'Создание ссылки на панель';
													|pl = 'Create a link to the panel';
													|tr = 'Panel bağlantısı oluşturma'");
	StartSettings1.WaitCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteFunction(StartSettings1, MethodName, JobParameters);
	
EndFunction

&AtServer
Function RefCreationParameters(ObjectID)
	
	RefCreationParameters = DataProcessors.Manage1CAnalyticsPanels.RefCreationParameters();
	RefCreationParameters.SelectedOwnersReceiver = SelectedOwnersReceiver;
	RefCreationParameters.ObjectID = ObjectID;
	RefCreationParameters.SourcePanels = FormAttributeToValue("SourcePanels");
	RefCreationParameters.Panels = FormAttributeToValue("Panels");
	RefCreationParameters.Dashboards = FormAttributeToValue("Dashboards");
	RefCreationParameters.Charts = FormAttributeToValue("Charts");
	RefCreationParameters.Folders = FormAttributeToValue("Folders");
	RefCreationParameters.OwnersOfAnalytics = FormAttributeToValue("OwnersOfAnalytics");
	RefCreationParameters.AnalyticsObjects = FormAttributeToValue("AnalyticsObjects");
	
	Return RefCreationParameters;
	
EndFunction

&AtClient
Procedure CreationOfLinkToPanelIsComplete(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Result) = Type("Structure") Then
		
		If Result.Property("Messages") And Result.Messages <> Undefined Then
			For Each Message In Result.Messages Do
				Message.Message();
			EndDo;
		EndIf;
		
		If Result.Property("Status") Then
			If Result.Status = "Error" Then
				CommonClient.MessageToUser(Result.BriefErrorDescription);
			ElsIf Result.Status = "Completed2" Then
				FillInDataAfterCreatingLink(Result.ResultAddress);
				UpdateReceiverPanels();
				UpdateTreeOfReceiverPanels(); 
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDataAfterCreatingLink(ResultAddress)
	
	ResultStructure1 = GetFromTempStorage(ResultAddress);
	
	FillInCollectionOfFormAccordingToTableOfValues(Dashboards, ResultStructure1.Dashboards);
	FillInCollectionOfFormAccordingToTableOfValues(Charts, ResultStructure1.Charts);
	FillInCollectionOfFormAccordingToTableOfValues(AnalyticsObjects, ResultStructure1.AnalyticsObjects);
	FillInCollectionOfFormAccordingToTableOfValues(Panels, ResultStructure1.Panels);
	FillInCollectionOfFormAccordingToTableOfValues(Folders, ResultStructure1.Folders);
	
EndProcedure

&AtClient
Procedure AfterConfirmationCreateLinkToPanel(Response, ObjectID) Export 
	
	If Response = DialogReturnCode.Yes Then
		ExecuteCreationLinkToPanel(ObjectID);
	EndIf;
	
EndProcedure

#EndRegion

#Region CreatingLinks

&AtClient
Procedure ExecuteCreatiinLinksOnPanel()
	
	TimeConsumingOperation = CreateLinksToPanelsOnServer();
	If TimeConsumingOperation <> Undefined Then
		CallbackOnCompletion = New CallbackDescription("CreationOfLinksOnPanelIsComplete", ThisObject);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.Title = NStr("vi = 'Tạo tham chiếu đến thanh lệnh';
									|ru = 'Создание ссылок на панели';
									|en = 'Create links to panels'; fa = 'Create links to panels';
									|it = 'Создание ссылок на панели';
									|pl = 'Create links to panels';
									|tr = 'Panel bağlantıları oluşturma'");
		IdleParameters.OutputIdleWindow = True;
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	EndIf;
	
EndProcedure

&AtServer
Function CreateLinksToPanelsOnServer()
	
	JobParameters = RefsCreationParameters();
	
	MethodName = "DataProcessors.Manage1CAnalyticsPanels.CreateLinksOnPanel";
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = NStr("vi = 'Tạo tham chiếu đến thanh lệnh';
													|ru = 'Создание ссылок на панели';
													|en = 'Create links to panels'; fa = 'Create links to panels';
													|it = 'Создание ссылок на панели';
													|pl = 'Create links to panels';
													|tr = 'Panel bağlantıları oluşturma'");
	StartSettings1.WaitCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteFunction(StartSettings1, MethodName, JobParameters);
	
EndFunction

&AtServer
Function RefsCreationParameters()
	
	RefsCreationParameters = DataProcessors.Manage1CAnalyticsPanels.RefsCreationParameters();
	RefsCreationParameters.SelectedOwnersReceiver = SelectedOwnersReceiver;
	RefsCreationParameters.SourcePanels = FormAttributeToValue("SourcePanels");
	RefsCreationParameters.Panels = FormAttributeToValue("Panels");
	RefsCreationParameters.Dashboards = FormAttributeToValue("Dashboards");
	RefsCreationParameters.Charts = FormAttributeToValue("Charts");
	RefsCreationParameters.Folders = FormAttributeToValue("Folders");
	RefsCreationParameters.OwnersOfAnalytics = FormAttributeToValue("OwnersOfAnalytics");
	RefsCreationParameters.AnalyticsObjects = FormAttributeToValue("AnalyticsObjects");
	
	Return RefsCreationParameters;
	
EndFunction

&AtClient
Procedure CreationOfLinksOnPanelIsComplete(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Result) = Type("Structure") Then
		
		If Result.Property("Messages") And Result.Messages <> Undefined Then
			For Each Message In Result.Messages Do
				Message.Message();
			EndDo;
		EndIf;
		
		If Result.Property("Status") Then
			If Result.Status = "Error" Then
				CommonClient.MessageToUser(Result.BriefErrorDescription);
			ElsIf Result.Status = "Completed2" Then
				FillInDataAfterProcessingObjects(Result.ResultAddress);
				UpdateReceiverPanels();
				UpdateTreeOfReceiverPanels(); 
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDataAfterProcessingObjects(ResultAddress)
	
	ResultStructure1 = GetFromTempStorage(ResultAddress);
	
	FillInCollectionOfFormAccordingToTableOfValues(Dashboards, ResultStructure1.Dashboards);
	FillInCollectionOfFormAccordingToTableOfValues(Charts, ResultStructure1.Charts);
	FillInCollectionOfFormAccordingToTableOfValues(AnalyticsObjects, ResultStructure1.AnalyticsObjects);
	FillInCollectionOfFormAccordingToTableOfValues(Panels, ResultStructure1.Panels);
	FillInCollectionOfFormAccordingToTableOfValues(Folders, ResultStructure1.Folders);
	
EndProcedure

&AtClient
Procedure AfterConfirmationCreateLinksToAllPanels(Response, AddnlParameter_) Export 
	
	If Response = DialogReturnCode.Yes Then
		ExecuteCreatiinLinksOnPanel();
	EndIf;  
	
EndProcedure
 
#EndRegion

#Region Copy

&AtClient
Procedure ExecuteCopyPanel(ObjectID, SelectedOwner)
	
	TimeConsumingOperation = CopyPanelOnServer(ObjectID, SelectedOwner);
	If TimeConsumingOperation <> Undefined Then
		CallbackOnCompletion = New CallbackDescription("CopyingOfPanelIsComplete", ThisObject);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.Title = NStr("vi = 'Sao chép thanh lệnh';
									|ru = 'Копирование панели';
									|en = 'Copy panel'; fa = 'کپی پنل';
									|it = 'Копирование панели';
									|pl = 'Copy panel';
									|tr = 'Panel kopyalama'");
		IdleParameters.OutputIdleWindow = True;
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	EndIf;
	
EndProcedure

&AtServer
Function CopyPanelOnServer(ObjectID, SelectedOwner)
	
	JobParameters = OptionsForCopyingPanels(ObjectID, SelectedOwner);
	
	MethodName = "DataProcessors.Manage1CAnalyticsPanels.CopyPanel";
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = NStr("vi = 'Sao chép thanh lệnh';
													|ru = 'Копирование панели';
													|en = 'Copy panel'; fa = 'کپی پنل';
													|it = 'Копирование панели';
													|pl = 'Copy panel';
													|tr = 'Panel kopyalama'");
	StartSettings1.WaitCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteFunction(StartSettings1, MethodName, JobParameters);
	
EndFunction

&AtServer
Function OptionsForCopyingPanels(ObjectID, SelectedOwner)
	
	OptionsForCopyingPanels = DataProcessors.Manage1CAnalyticsPanels.OptionsForCopyingPanels();

	OptionsForCopyingPanels.ObjectID = ObjectID;
	OptionsForCopyingPanels.SelectedOwner = SelectedOwner;
	
	OptionsForCopyingPanels.FromFile                     = SourceFromFile;
	OptionsForCopyingPanels.SelectedOwnersReceiver  = SelectedOwnersReceiver;
	OptionsForCopyingPanels.SourcePanels              = FormAttributeToValue("SourcePanels");
	OptionsForCopyingPanels.Panels                      = FormAttributeToValue("Panels");
	OptionsForCopyingPanels.Dashboards                    = FormAttributeToValue("Dashboards");
	OptionsForCopyingPanels.Charts                   = FormAttributeToValue("Charts");
	OptionsForCopyingPanels.Folders                       = FormAttributeToValue("Folders");
	OptionsForCopyingPanels.OwnersOfAnalytics          = FormAttributeToValue("OwnersOfAnalytics");
	OptionsForCopyingPanels.AnalyticsObjects            = FormAttributeToValue("AnalyticsObjects");
	OptionsForCopyingPanels.IdsToOverwrite = IdsToOverwrite;

	If SourceFromFile = 0 Then
		OptionsForCopyingPanels.DashboardsSource         = FormAttributeToValue("Dashboards");
		OptionsForCopyingPanels.SourceCharts        = FormAttributeToValue("Charts");
		OptionsForCopyingPanels.SourceFolders            = FormAttributeToValue("Folders");
		OptionsForCopyingPanels.AnalyticsObjectsSource = FormAttributeToValue("AnalyticsObjects");
	ElsIf SourceFromFile = 1 Then
		OptionsForCopyingPanels.DashboardsSource         = FormAttributeToValue("DashboardsFromFile");
		OptionsForCopyingPanels.SourceCharts        = FormAttributeToValue("DiagramsFromFile");
		OptionsForCopyingPanels.SourceFolders            = FormAttributeToValue("FoldersFromFile");
		OptionsForCopyingPanels.AnalyticsObjectsSource = FormAttributeToValue("AnalyticsObjectsFromFile");
		OptionsForCopyingPanels.PanelSettingsIds = FormAttributeToValue("IdsOfSettingsOfBIPPanels");
	ElsIf SourceFromFile = 2 Then
		OptionsForCopyingPanels.DashboardsSource         = FormAttributeToValue("DashboardsFromService");
		OptionsForCopyingPanels.SourceCharts        = FormAttributeToValue("ChartsFromService");
		OptionsForCopyingPanels.SourceFolders            = FormAttributeToValue("FoldersFromService");
		OptionsForCopyingPanels.AnalyticsObjectsSource = FormAttributeToValue("AnalyticsObjectsFromService");
		OptionsForCopyingPanels.AdditionalSources  = FormAttributeToValue("AdditionalSources");
		OptionsForCopyingPanels.PanelSettingsIds = FormAttributeToValue("IdsOfSettingsOfBIPPanels");
		OptionsForCopyingPanels.ServerAddress             = ServerAddress;
	EndIf;
	
	Return OptionsForCopyingPanels;
	
EndFunction

&AtClient
Procedure CopyingOfPanelIsComplete(Result, AdditionalParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	If Result.Property("Messages") And Result.Messages <> Undefined Then
		For Each Message In Result.Messages Do
			Message.Message();
		EndDo;
	EndIf;
	
	If Result.Property("Status") Then
		If Result.Status = "Error" Then
			CommonClient.MessageToUser(Result.BriefErrorDescription);
		ElsIf Result.Status = "Completed2" Then
			FillInDataAfterCopyingPanel(Result.ResultAddress);
			UpdateReceiverPanels();
			UpdateTreeOfReceiverPanels(); 
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDataAfterCopyingPanel(ResultAddress)
	
	ResultStructure1 = GetFromTempStorage(ResultAddress);
	
	FillInCollectionOfFormAccordingToTableOfValues(Dashboards, ResultStructure1.Dashboards);
	FillInCollectionOfFormAccordingToTableOfValues(Charts, ResultStructure1.Charts);
	FillInCollectionOfFormAccordingToTableOfValues(AnalyticsObjects, ResultStructure1.AnalyticsObjects);
	FillInCollectionOfFormAccordingToTableOfValues(Panels, ResultStructure1.Panels);
	FillInCollectionOfFormAccordingToTableOfValues(Folders, ResultStructure1.Folders);
	FillInCollectionOfFormAccordingToTableOfValues(IdsOfSettingsOfBIPPanels, ResultStructure1.PanelSettingsIds);
	
EndProcedure

&AtClient
Procedure AfterConfirmingTransferOfPanels(Response, AdditionalParameters) Export 
	
	If Response = DialogReturnCode.Yes Then
		ObjectID = AdditionalParameters.ObjectID;
		PossibleOwners = AdditionalParameters.PossibleOwners;
		
		If SourceFromFile And PossibleOwners.Count() > 1 Then
			SelectOwnerForPanels(AdditionalParameters)
		ElsIf SourceFromFile And PossibleOwners.Count() Then
			ExecuteCopyPanel(ObjectID, PossibleOwners[0]);
		Else
			ExecuteCopyPanel(ObjectID, Undefined);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectOwnerForPanels(AdditionalParameters) Export 
	
	PossibleOwners = AdditionalParameters.PossibleOwners;
	
	If PossibleOwners.Count() > 1 Then
		
		FormParameters = New Structure;
		FormParameters.Insert("AddressInTempStorage", PutToTempStorage(PossibleOwners, UUID));
		
		OpenForm("DataProcessor.Manage1CAnalyticsPanels.Form.SelectOwnerForPanels",
					FormParameters,
					ThisObject,,,,
					New CallbackDescription("OwnerForNewPanelsIsSelected", ThisObject, AdditionalParameters.ObjectID), 
					FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OwnerForNewPanelsIsSelected(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ExecuteCopyPanel(AdditionalParameters, Result);
	
EndProcedure

#EndRegion

#Region Delete

&AtClient
Procedure PerformPanelRemoval(RowID)
	
	TimeConsumingOperation = DeletePanelOnServer(RowID);
	If TimeConsumingOperation <> Undefined Then
		CallbackOnCompletion = New CallbackDescription("PanelRemovalIsComplete", ThisObject);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.Title = NStr("vi = 'Xóa thanh lệnh';
									|ru = 'Удаление панели';
									|en = 'Panel deletion'; fa = 'Panel deletion';
									|it = 'Удаление панели';
									|pl = 'Panel deletion';
									|tr = 'Panel silme'");
		IdleParameters.OutputIdleWindow = True;
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	EndIf;
	
EndProcedure

&AtServer
Function DeletePanelOnServer(RowID)
	
	JobParameters = OptionsDeletingPanel(RowID);
	
	MethodName = "DataProcessors.Manage1CAnalyticsPanels.DeletePanel";
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = NStr("vi = 'Xóa thanh lệnh';
													|ru = 'Удаление панели';
													|en = 'Panel deletion'; fa = 'Panel deletion';
													|it = 'Удаление панели';
													|pl = 'Panel deletion';
													|tr = 'Panel silme'");
	StartSettings1.WaitCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteFunction(StartSettings1, MethodName, JobParameters);
	
EndFunction

&AtServer
Function OptionsDeletingPanel(RowID)
	
	RefCreationParameters = DataProcessors.Manage1CAnalyticsPanels.PanelRemovalOptions();
	RefCreationParameters.RowID = RowID;
	RefCreationParameters.SourcePanels = FormAttributeToValue("SourcePanels");
	RefCreationParameters.ReceiverPanels = FormAttributeToValue("ReceiverPanels");
	RefCreationParameters.Panels = FormAttributeToValue("Panels");
	RefCreationParameters.Dashboards = FormAttributeToValue("Dashboards");
	RefCreationParameters.Charts = FormAttributeToValue("Charts");
	RefCreationParameters.Folders = FormAttributeToValue("Folders");
	RefCreationParameters.OwnersOfAnalytics = FormAttributeToValue("OwnersOfAnalytics");
	RefCreationParameters.AnalyticsObjects = FormAttributeToValue("AnalyticsObjects");
	
	Return RefCreationParameters;
	
EndFunction

&AtClient
Procedure PanelRemovalIsComplete(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Result) = Type("Structure") Then
		
		If Result.Property("Messages") And Result.Messages <> Undefined Then
			For Each Message In Result.Messages Do
				Message.Message();
			EndDo;
		EndIf;
		
		If Result.Property("Status") Then
			If Result.Status = "Error" Then
				CommonClient.MessageToUser(Result.BriefErrorDescription);
			ElsIf Result.Status = "Completed2" Then
				FillInDataAfterDeletingPanel(Result.ResultAddress);
				UpdateReceiverPanels();
				UpdateTreeOfReceiverPanels(); 
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDataAfterDeletingPanel(ResultAddress)
	
	ResultStructure1 = GetFromTempStorage(ResultAddress);
	
	FillInCollectionOfFormAccordingToTableOfValues(Dashboards, ResultStructure1.Dashboards);
	FillInCollectionOfFormAccordingToTableOfValues(Charts, ResultStructure1.Charts);
	FillInCollectionOfFormAccordingToTableOfValues(AnalyticsObjects, ResultStructure1.AnalyticsObjects);
	FillInCollectionOfFormAccordingToTableOfValues(Panels, ResultStructure1.Panels);
	FillInCollectionOfFormAccordingToTableOfValues(Folders, ResultStructure1.Folders);
	
EndProcedure

&AtClient
Procedure AfterConfirmingRemovalOfPanel(Response, RowID) Export 
	
	If Response = DialogReturnCode.Yes Then
		PerformPanelRemoval(RowID);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Other

&AtClient
Procedure UpdateReceiverPanels()
	
	UpdateReceiverOwnerTable();
	UpdateStateTableOfReceiverOwners();
	UpdateTreeOfReceiverPanels();
	ExpandReceiverPanel(); 
	
EndProcedure

&AtClient
Procedure UpdateSourcePanel()
	
	UpdateSourceOwnerTable();
	UpdateSourcePanelTree();
	ExpandSourcePanel();
	
EndProcedure

&AtClient
Procedure UpdateReceiverOwnerTable()
	
	ReceiverOwnersTable.Clear();
	
	For Each User In OwnersOfAnalytics Do
		NewRow = ReceiverOwnersTable.Add();
		NewRow.Owner = User.OwnerName;
		If SelectedOwnersReceiver.FindByValue(NewRow.Owner) = Undefined Then
			NewRow.Check = False;
		Else
			NewRow.Check = True;
		EndIf;
	EndDo;
	
	ReceiverOwnersTable.Sort("Owner");
	
EndProcedure

&AtClient
Procedure UpdateSourceOwnerTable()
	
	TableOfOwnersSource.Clear();
	
	ChoosingTableOfOwners = New Map;
	ChoosingTableOfOwners.Insert(0, OwnersOfAnalytics);
	ChoosingTableOfOwners.Insert(1, OwnersOfAnalyticsFromFile);
	ChoosingTableOfOwners.Insert(2, OwnersOfAnalyticsFromService); 
	
	OwnersTable = ChoosingTableOfOwners[SourceFromFile];
	
	For Each User In OwnersTable Do
		NewRow = TableOfOwnersSource.Add();
		NewRow.Owner = User.OwnerName;
		If SelectedOwnersSource.FindByValue(NewRow.Owner) = Undefined Then
			NewRow.Check = False;
		Else
			NewRow.Check = True;
		EndIf;
	EndDo;
	
	TableOfOwnersSource.Sort("Owner");
	
EndProcedure

&AtClient
Procedure UpdateStateTableOfReceiverOwners()
	
	StateTableOfOwnersOfReceiver.Clear();
	
	NewRow = StateTableOfOwnersOfReceiver.Add();
	NewRow.State = CurrentState();
	NewRow.Check = False;
	
	NewRow = StateTableOfOwnersOfReceiver.Add();
	NewRow.State = StateIsNotUpToDate();
	NewRow.Check = False;
	
EndProcedure

&AtServer
Procedure UpdateTreeOfReceiverPanels()
	
	ReceiverPanels.GetItems().Clear();

	SetOfTables = NewSetOfTables();
	SetOfTables.ChartsTable  = Charts;
	SetOfTables.DashboardTable = Dashboards;
	SetOfTables.FoldersTable     = Folders;

	For Each Panel In Panels Do
		
		If SelectedOwnersReceiver.FindByValue(Panel.OwnerName) = Undefined Then
			Continue;
		EndIf;
		
		RootDirectory = DataProcessors.Manage1CAnalyticsPanels.FindByID(Folders, Panel.Data_RootFolderId);
		If RootDirectory <> Undefined Then 
			TreeRoot = ReceiverPanels.GetItems().Add();
			TreeRoot.RowID = New UUID;
			TreeRoot.Name1 = Panel.OwnerName;
			TreeRoot.PanelOwner = Panel.Owner; 
			TreeRoot.Id = Panel.Data_RootFolderId;
			
			FillInPanelElements(RootDirectory, TreeRoot.GetItems(), False, Panel.Owner, New Map(), SetOfTables);
		EndIf;
		
	EndDo;
	
	SortFormDataTree("ReceiverPanels");
	
EndProcedure

&AtServer 
Procedure UpdateSourcePanelTree()
	
	SetOfTables = NewSetOfTables();
	
	If SourceFromFile = 0 Then
		PanelTable = Panels;
		SetOfTables.ChartsTable  = Charts;
		SetOfTables.DashboardTable = Dashboards;
		SetOfTables.FoldersTable     = Folders;
	ElsIf SourceFromFile = 1 Then
		PanelTable = PanelsFromFile;
		SetOfTables.ChartsTable  = DiagramsFromFile;
		SetOfTables.DashboardTable = DashboardsFromFile;
		SetOfTables.FoldersTable     = FoldersFromFile;
	ElsIf SourceFromFile = 2 Then
		PanelTable = PanelsFromService;
		SetOfTables.ChartsTable  = ChartsFromService;
		SetOfTables.DashboardTable = DashboardsFromService;
		SetOfTables.FoldersTable     = FoldersFromService;
	EndIf;
	
	SourcePanels.GetItems().Clear();
	ConsiderFilter = SelectedOwnersSource.Count() > 0;
	
	IndexOfRepeatingPanel = 0;
	For Each Panel In PanelTable Do
		
		If ConsiderFilter And SelectedOwnersSource.FindByValue(Panel.OwnerName) = Undefined Then
			Continue;
		EndIf;
		
		RootFolders = SetOfTables.FoldersTable.FindRows(New Structure("Id", Panel.Data_RootFolderId));
		NumberOfRootFolders = RootFolders.Count();
		If NumberOfRootFolders > 0 Then
			TreeRoot = SourcePanels.GetItems().Add();
			TreeRoot.RowID = New UUID;
			TreeRoot.Name1 = Panel.OwnerName;
			TreeRoot.PanelOwner = Panel.Owner;
			TreeRoot.Id = Panel.Data_RootFolderId;
			
			If NumberOfRootFolders > 1 Then
				If NumberOfRootFolders < IndexOfRepeatingPanel + 1 Then
					SourcePanels.GetItems().Clear();
					Raise("vi = 'Lỗi kết nhập thanh lệnh được cung cấp. Vui lòng liên hệ với nhà cung cấp thanh lệnh.';
							|ru = 'Ошибка загрузки поставляемых панелей. Обратитесь к поставщику панелей.';
							|en = 'Error importing built-in panels. Contact the panel provider.';
							|it = 'Error importing built-in panels. Contact the panel provider.';
							|pl = 'Error importing built-in panels. Contact the panel provider.';
							|tr = 'Tedarik edilen paneller yüklenirken hata oluştu. Panel tedarikçinizle iletişime geçin.'");
				EndIf;
				
				RootDirectory = RootFolders[IndexOfRepeatingPanel];
				IndexOfRepeatingPanel = IndexOfRepeatingPanel + 1;
			Else
				RootDirectory = RootFolders[0];
			EndIf;
			
			FillInPanelElements(RootDirectory, TreeRoot.GetItems(), SourceFromFile, Panel.Owner, New Map(), SetOfTables);
		EndIf;
	EndDo;
	
	SortFormDataTree("SourcePanels");
	
EndProcedure

&AtServer
Procedure FillInPanelElements(FolderString, TreeItems, FromFile, IDOwner, FolderIds, SetOfTables)
	
	UseStateSelection = SelectedStatesOwnersReceiver.Count();
	
	For Each SubfolderId In FolderString.Data_FolderIds Do
		If FolderIds.Get(SubfolderId) <> Undefined Then // otherwise an infinite loop
			Break;
		EndIf;
		FolderIds.Insert(SubfolderId, True);
		
		SubfolderString = SetOfTables.FoldersTable.FindRows(New Structure("Id", SubfolderId.Value));
		If SubfolderString.Count() Then
			Folder = SubfolderString[0];
			PanelImage = PictureLib.Folder;
			If ReceiverIsBeingUpdated And UseStateSelection Then
				FillInPanelElements(Folder, TreeItems, FromFile, IDOwner, FolderIds, SetOfTables);
			Else
				TreeRow = TreeItems.Add();
				TreeRow.RowID = New UUID;
				FillInTreeLine(TreeRow, Folder, IDOwner, PanelImage, FromFile);
				FillInPanelElements(Folder, TreeRow.GetItems(), FromFile, IDOwner, FolderIds, SetOfTables);
			EndIf;
		EndIf;
	EndDo;
	
	For Each FileID In FolderString.Data_FileIds Do
		Id = FileID.Value;
		
		ChartLines = SetOfTables.ChartsTable.FindRows(New Structure("Id", Id));
		If ChartLines.Count() Then 
			Chart = ChartLines[0];
			
			If ReceiverIsBeingUpdated
				And UseStateSelection
				And Not StateCorrespondsToSelection(Chart, SetOfTables.TableOfRelevance) Then
				Continue;
			EndIf;
			
			PanelImage = PictureLib.Chart; 
			TreeRow = TreeItems.Add();
			TreeRow.RowID = New UUID;
			FillInTreeLine(TreeRow, Chart, IDOwner, PanelImage, FromFile);
			Continue;
		EndIf;
		
		DashboardLines = SetOfTables.DashboardTable.FindRows(New Structure("Id", Id));
		If DashboardLines.Count() Then
			Dashboard = DashboardLines[0];
			
			If ReceiverIsBeingUpdated
				And UseStateSelection
				And Not StateCorrespondsToSelection(Dashboard, SetOfTables.TableOfRelevance) Then
				Continue;
			EndIf;
			
			PanelImage = PictureLib.AppearanceBoxesEmpty; 
			TreeRow = TreeItems.Add();
			TreeRow.RowID = New UUID;
			FillInTreeLine(TreeRow, Dashboard, IDOwner, PanelImage, FromFile);
			Continue;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInTreeLine(TreeRow, Source, IDOwner, PanelImage, FromFile)
	
	TreeRow.Name1 = Source.Name;
	TreeRow.OwnerIdentifier = Source.Owner;
	TreeRow.Id = Source.Id;
	TreeRow.Owner_Name = Source.OwnerName;
	TreeRow.PanelImage = PanelImage;
	TreeRow.Type = Source.Type;
	TreeRow.ChangeDate = TimestampToDate(Source.Updated);
	TreeRow.PanelOwner = IDOwner;
	
	If Source.Owner <> IDOwner Then
		TreeRow.IsReference = True;
		If Not FromFile Then
			TreeRow.LinkImage = PictureLib.GetURL;
		EndIf;
	EndIf;
	
	If SourceFromFile = 1 Then
		TableOfRelevance = CurrentDatesFromFile;
	ElsIf SourceFromFile = 2 Then
		TableOfRelevance = CurrentDatesFromService;
	Else
		Return;
	EndIf;
		
	Rows = TableOfRelevance.FindRows(New Structure("Id", Source.Id));
	If Rows.Count() Then
		If Rows[0].Updated = Source.Updated Then
			TreeRow.StatusPicture_2 = PictureLib.AppearanceCircleGreen;
		Else
			TreeRow.StatusPicture_2 = PictureLib.AppearanceCircleYellow;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure PanelsFileExtensionIsEnabled(Result, AdditionalParameters) Export 
	
	OpenFileDialog = New FileDialog(FileDialogMode.Open);
	OpenFileDialog.Filter =  NStr("vi = 'Tệp thanh lệnh';
									|ru = 'Файл панелей';
									|en = 'Panel file'; fa = 'فایل پنل';
									|it = 'Файл панелей';
									|pl = 'Panel file';
									|tr = 'Panel dosyası'") + " (*.json)|*.json";
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = NStr("vi = 'Hãy chọn đường dẫn đến tệp thanh lệnh';
								|ru = 'Выберите путь к файлу панелей';
								|en = 'Select the path to the panel file'; fa = 'Select the path to the panel file';
								|it = 'Выберите путь к файлу панелей';
								|pl = 'Select the path to the panel file';
								|tr = 'Panel dosyasının yolunu seçin'");
	
	CallbackDescription = New CallbackDescription(
		"FilePanelsShowEndDialog",
		ThisObject);
		
	OpenFileDialog.Show(CallbackDescription);
	
EndProcedure

&AtClient
Async Procedure FilePanelsShowEndDialog(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	PanelFile = SelectedFiles[0];
	
	FileDetails = Await PutFileToServerAsync(, , , PanelFile);
	
	If FileDetails <> Undefined Then
		PerformReadingFromFile(FileDetails.Address);
	EndIf;
	
EndProcedure

&AtServer 
Procedure SortFormDataTree(Var_AttributeName)
	
	Tree = FormAttributeToValue(Var_AttributeName);
	Tree.Rows.Sort("Name1", True);
	ValueToFormData(Tree, ThisObject[Var_AttributeName]);
	
EndProcedure

&AtServerNoContext
Function TimestampToDate(TimestampRow)
	
	If ValueIsFilled(TimestampRow) Then
		Return ToLocalTime('19700101' + Number(TimestampRow) / 1000)
	Else
		Return Undefined;
	EndIf;
	
EndFunction

&AtServer
Function CheckingForLinkCreation(Val RowID = Undefined)
	
	Tree = FormAttributeToValue("SourcePanels");
	ReadyForProcessing_ = DataProcessors.Manage1CAnalyticsPanels.TreeRowsToBeProcessed(Tree, RowID);
	
	ThereAreUnavailableForProcessing = False;
	ThereAreAvailableForProcessing = False;
	
	For Each Panel In Panels Do
		If SelectedOwnersReceiver.FindByValue(Panel.OwnerName) = Undefined Then
			Continue;
		EndIf;
		
		Transfers_1 = DataProcessors.Manage1CAnalyticsPanels.Transfers_1(Panel, ReadyForProcessing_, SourceFromFile, Charts, Dashboards, Folders);
		For Each String In ReadyForProcessing_ Do
			
			Transfer = Transfers_1.Get(String);
			If Transfer = Undefined Then
				Continue;
			EndIf;
			
			If Not Transfer.PossibleAsLink Then
				ThereAreUnavailableForProcessing = True;
				Message = New UserMessage();
				Message.Text = StrTemplate(NStr("vi = 'Trong đích ""%1"" đã có đối tượng: %2';
												|ru = 'В приемнике ""%1"" уже есть объект: %2';
												|en = 'The %1 destination already contains the %2 object'; fa = 'The %1 destination already contains the %2 object';
												|it = 'В приемнике ""%1"" уже есть объект: %2';
												|pl = 'The %1 destination already contains the %2 object';
												|tr = '""%1"" alıcısında zaten nesne mevcut: %2'"), Panel.OwnerName, String.Name1);
				Message.Message();
			Else
				ThereAreAvailableForProcessing = True;
			EndIf;
		EndDo;
	EndDo;
	
	Result = New Structure();
	Result.Insert("ThereAreAvailableForProcessing", ThereAreAvailableForProcessing);
	Result.Insert("ThereAreUnavailableForProcessing", ThereAreUnavailableForProcessing);
	
	Return Result;
	
EndFunction	

&AtServer
Function CheckingForTransferOfPanels(Val RowID)
	
	IdsToOverwrite.Clear();
	
	SortingFolders = New ValueTable(); // to sort folders by level
	SortingFolders.Columns.Add("FolderFields");
	SortingFolders.Columns.Add("Level");
	
	Tree = FormAttributeToValue("SourcePanels");
	LinesToTransfer = DataProcessors.Manage1CAnalyticsPanels.TreeRowsToBeProcessed(Tree, RowID);
	
	ThereAreAvailableForTransfer = False;
	ThereAreThoseThatAreNotAvailableForTransfer = False;
	ThereAreReplacements = False;
	PossibleOwners = New Array;
	
	For Each Panel In Panels Do
		
		If SelectedOwnersReceiver.FindByValue(Panel.OwnerName) = Undefined Then
			Continue;
		EndIf;
				
		Transfers_1 = DataProcessors.Manage1CAnalyticsPanels.Transfers_1(Panel, LinesToTransfer, SourceFromFile, Charts, Dashboards, Folders);
		
		For Each String In LinesToTransfer Do //ValueTreeRow
			
			Transfer = Transfers_1.Get(String);
			
			StringType = String.Type;
			IDRow = String.Id;
			String_Name = String.Name1;
			
			If Transfer.PossibleAsNew Then
				ThereAreAvailableForTransfer = True;
				
				If SourceFromFile Then
					If PossibleOwners.Find(Panel.OwnerName) = Undefined Then
						PossibleOwners.Add(Panel.OwnerName);
					EndIf;
				EndIf;
			ElsIf Transfer.PossibleWithSubstitution Then
				If SourceFromFile Then
					If PossibleOwners.Find(Panel.OwnerName) = Undefined Then
						PossibleOwners.Add(Panel.OwnerName);
					EndIf;
				EndIf;
				
				If StringType = "folder" Then
					IdsToOverwrite.Add(String.Id);
					ThereAreReplacements = True;
					Message = New UserMessage();
					Message.Text = StrTemplate(NStr("vi = 'Đối tượng ""%1"" đã có trong đích ""%2"", đối tượng sẽ bị thay thế';
													|ru = 'Объект ""%1"" уже есть в приемнике ""%2"", он будет заменен';
													|en = 'The %2 destination already contains the %1 object. The object will be replaced'; fa = 'The %2 destination already contains the %1 object. The object will be replaced';
													|it = 'Объект ""%1"" уже есть в приемнике ""%2"", он будет заменен';
													|pl = 'The %2 destination already contains the %1 object. The object will be replaced';
													|tr = '""%1"" nesnesi ""%2"" alıcısında zaten mevcut, bu değiştirilecektir'"), String_Name, Panel.OwnerName);
					Message.Message();
				Else
					If DataProcessors.Manage1CAnalyticsPanels.ParentFolderCanBeMoved(String, Transfers_1) Then
						IdsToOverwrite.Add(String.Id);
						ThereAreReplacements = True;
						Message = New UserMessage();
						Message.Text = StrTemplate(NStr("vi = 'Đối tượng ""%1"" đã có trong đích ""%2"", đối tượng sẽ bị thay thế';
														|ru = 'Объект ""%1"" уже есть в приемнике ""%2"", он будет заменен';
														|en = 'The %2 destination already contains the %1 object. The object will be replaced'; fa = 'The %2 destination already contains the %1 object. The object will be replaced';
														|it = 'Объект ""%1"" уже есть в приемнике ""%2"", он будет заменен';
														|pl = 'The %2 destination already contains the %1 object. The object will be replaced';
														|tr = '""%1"" nesnesi ""%2"" alıcısında zaten mevcut, bu değiştirilecektir'"), String_Name, Panel.OwnerName);
						Message.Message();
					Else
						ThereAreThoseThatAreNotAvailableForTransfer = True;
						Message = New UserMessage();
						Message.Text = StrTemplate(NStr("vi = 'Đối tượng ""%1"" đang nằm trong thư mục không thể chuyển';
														|ru = 'Объект ""%1"" находится в папке, которая не может быть перенесена';
														|en = 'The %1 object is in the folder that cannot be transferred'; fa = 'The %1 object is in the folder that cannot be transferred';
														|it = 'Объект ""%1"" находится в папке, которая не может быть перенесена';
														|pl = 'The %1 object is in the folder that cannot be transferred';
														|tr = '""%1"" nesnesi, taşınamayan bir klasörde bulunmaktadır'"), String_Name);
						Message.Message();
					EndIf;
				EndIf;
			Else
				// the object belongs to another desktop
				NameOfOwnerOfExistingObject = NameOfOwnerOfExistingObject(IDRow, StringType);
				
				ThereAreThoseThatAreNotAvailableForTransfer = True;
				Message = New UserMessage();
				Message.Text = StrTemplate(NStr("vi = 'Đối tượng ""%1"" đang nằm trong thư mục của đối tượng chủ ""%2"" và không thể chuyển';
												|ru = 'Объект ""%1"" находится в папке у владельца ""%2"" и не может быть перенесен';
												|en = 'The %1 object is already in the folder of the %2 owner and cannot be transferred'; fa = 'The %1 object is already in the folder of the %2 owner and cannot be transferred';
												|it = 'Объект ""%1"" находится в папке у владельца ""%2"" и не может быть перенесен';
												|pl = 'The %1 object is already in the folder of the %2 owner and cannot be transferred';
												|tr = '""%1"" nesnesi ""%2"" sahibinin klasöründe bulunmaktadır ve taşınamaz'"), String_Name, NameOfOwnerOfExistingObject);
				Message.Message();
			EndIf;
			
		EndDo;
		
	EndDo;
	
	If SourceFromFile Then
		For Each SourceObject In LinesToTransfer Do //ValueTreeRow
			If SourceObject.Type = "chart" Then
				SearchTable = Charts;
			ElsIf SourceObject.Type = "dashboard" Then
				SearchTable = Dashboards;
			ElsIf SourceObject.Type = "folder" Then
				SearchTable = Folders;
			EndIf;
			
			TheStructureOfTheSearch = New Structure;
			TheStructureOfTheSearch.Insert("Id", SourceObject.Id);
			SearchResult = SearchTable.FindRows(TheStructureOfTheSearch);
			If SearchResult.Count() Then
				ExistingObject = SearchResult[0];
				If SelectedOwnersReceiver.FindByValue(ExistingObject.OwnerName) = Undefined Then
					Message = New UserMessage();
					Message.Text = StrTemplate(NStr("vi = 'Đối tượng ""%1"" đã gắn với đối tượng chủ ""%2"", mà sẽ được tạo tham chiếu, bởi vì đối tượng sẽ gắn với đối tượng chủ mới';
													|ru = 'Объект ""%1"" уже прикреплен к владельцу ""%2"", для этого владельца будет создана ссылка, т.к. объект будет прикреплен к новому владельцу';
													|en = 'The %1 object is already linked to the %2 owner. For this owner, a link will be generated as the object will be linked to a new owner'; fa = 'The %1 object is already linked to the %2 owner. For this owner, a link will be generated as the object will be linked to a new owner';
													|it = 'Объект ""%1"" уже прикреплен к владельцу ""%2"", для этого владельца будет создана ссылка, т.к. объект будет прикреплен к новому владельцу';
													|pl = 'The %1 object is already linked to the %2 owner. For this owner, a link will be generated as the object will be linked to a new owner';
													|tr = '""%1"" nesnesi zaten ""%2"" sahibine bağlı, nesne yeni sahibine bağlanacağından dolayı bu sahip için bağlantı oluşturulacaktır'"), ExistingObject.Name, ExistingObject.OwnerName);
					Message.Message();
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	Result = New Structure();
	Result.Insert("ThereAreAvailableForTransfer", ThereAreAvailableForTransfer);
	Result.Insert("ThereAreThoseThatAreNotAvailableForTransfer", ThereAreThoseThatAreNotAvailableForTransfer);
	Result.Insert("ThereAreReplacements", ThereAreReplacements);
	Result.Insert("PossibleOwners", PossibleOwners);
	
	Return Result;
	
EndFunction

&AtServer
Function NameOfOwnerOfExistingObject(ObjectID, ObjectType)
	
	If ObjectType = "chart" Then
		Table = Charts;
	ElsIf ObjectType = "dashboard" Then
		Table = Dashboards;
	ElsIf ObjectType = "folder" Then
		Table = Folders;
	EndIf;
	
	SearchResult = Table.FindRows(New Structure("Id", ObjectID));
	If SearchResult.Count() Then
		Return SearchResult[0].OwnerName;
	Else
		Return ""
	EndIf; 
	
EndFunction

&AtServer
Function JSONPanelSettings()
	
	If SourceFromFile Then
		OwnersOfAnalyticsToSave = OwnersOfAnalyticsFromFile;
		PanelsToSave = PanelsFromFile;
		FoldersToSave = FoldersFromFile;
		DiagramsToSave = DiagramsFromFile;
		DashboardsToSave = DashboardsFromFile;
		AnalyticsObjectsToSave = AnalyticsObjectsFromFile;
	Else
		OwnersOfAnalyticsToSave = OwnersOfAnalytics;
		PanelsToSave = Panels;
		FoldersToSave = Folders;
		DiagramsToSave = Charts;
		DashboardsToSave = Dashboards;
		AnalyticsObjectsToSave = AnalyticsObjects;
	EndIf;
	
	Return DataProcessors.Manage1CAnalyticsPanels.JSONPanelSettings(
					OwnersOfAnalyticsToSave,
					PanelsToSave,
					FoldersToSave,
					DiagramsToSave,
					DashboardsToSave,
					AnalyticsObjectsToSave); 
	
EndFunction

&AtServer
Function SettingsOfSelectedJSONOwners()
	
	If SourceFromFile Then
		PanelsToSave = PanelsFromFile;
		SelectedOwnersToSave = SelectedOwnersSource;
		OwnersOfAnalyticsToSave = OwnersOfAnalyticsFromFile;
		FoldersToSave = FoldersFromFile;
		DiagramsToSave = DiagramsFromFile;
		DashboardsToSave = DashboardsFromFile;
		AnalyticsObjectsToSave = AnalyticsObjectsFromFile;
	Else
		PanelsToSave = Panels;
		SelectedOwnersToSave = SelectedOwnersSource;
		OwnersOfAnalyticsToSave = OwnersOfAnalytics;
		FoldersToSave = Folders;
		DiagramsToSave = Charts;
		DashboardsToSave = Dashboards;
		AnalyticsObjectsToSave = AnalyticsObjects;
	EndIf;
	
	Return DataProcessors.Manage1CAnalyticsPanels.SettingsOfSelectedJSONOwners(
					PanelsToSave,
					SelectedOwnersToSave,
					OwnersOfAnalyticsToSave,
					FoldersToSave,
					DiagramsToSave,
					DashboardsToSave,
					AnalyticsObjectsToSave);
	
EndFunction

&AtClient
Procedure ExpandReceiverPanel()
	
	If ReceiverPanels.GetItems().Count() Then 
		Items.ReceiverPanels.Expand(ReceiverPanels.GetItems()[0].GetID());
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpandSourcePanel()
	
	If SourcePanels.GetItems().Count() Then
		Items.SourcePanels.Expand(SourcePanels.GetItems()[0].GetID()); 
	EndIf; 
	
EndProcedure

&AtClient
Procedure SaveOwnerSettingsToFile(OnlySelectedUser = False)
	
	CallbackDescription = New CallbackDescription(
		"SaveOwnerSettingsExtensionEnabled",
		ThisObject,
		OnlySelectedUser);
	
	FileSystemClient.AttachFileOperationsExtension(CallbackDescription);
	
EndProcedure

&AtClient
Procedure SaveOwnerSettingsExtensionEnabled(Result, AdditionalParameters) Export 
	
	OpenFileDialog = New FileDialog(FileDialogMode.Save);
	OpenFileDialog.Filter =  NStr("vi = 'Tệp thanh lệnh';
									|ru = 'Файл панелей';
									|en = 'Panel file'; fa = 'فایل پنل';
									|it = 'Файл панелей';
									|pl = 'Panel file';
									|tr = 'Panel dosyası'") + " (*.json)|*.json";
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = NStr("vi = 'Hãy chọn đường dẫn đến tệp thanh lệnh';
								|ru = 'Выберите путь к файлу панелей';
								|en = 'Select path to the panel file'; fa = 'Select path to the panel file';
								|it = 'Выберите путь к файлу панелей';
								|pl = 'Select path to the panel file';
								|tr = 'Panel dosyasının yolunu seçin'");
	
	CallbackDescription = New CallbackDescription(
		"SaveOwnerSettingsShowEndDialog",
		ThisObject,
		AdditionalParameters);
		
	OpenFileDialog.Show(CallbackDescription);
	
EndProcedure

&AtClient
Procedure SaveOwnerSettingsShowEndDialog(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	If AdditionalParameters Then
		Content = SettingsOfSelectedJSONOwners();
	Else
		Content = JSONPanelSettings();
	EndIf;
	
	CallbackDescription = New CallbackDescription("AllowSourceSwitching", ThisObject);
	AddressInTempStorage = PutToTempStorage(Content);
	ProhibitSwitchingSource();
	FileSystemClient.SaveFile(CallbackDescription, AddressInTempStorage, SelectedFiles[0]);
	
EndProcedure

&AtClient
Procedure ProhibitSwitchingSource()
	Items.SwitchSettingsSource.ReadOnly = True;
EndProcedure

&AtClient
Procedure AllowSourceSwitching(Result, AdditionalParameters) Export 
	Items.SwitchSettingsSource.ReadOnly = False;
EndProcedure

&AtServer
Function FormTableToTemporaryStorage(Val Table)
	Return PutToTempStorage(Table.Unload(), UUID);
EndFunction

&AtClient
Procedure UpdateSelectedOwnersSource(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	UpdateSelectedOwnersSourceServer(Result);
	ExpandSourcePanel();
	
EndProcedure

&AtServer
Procedure UpdateSelectedOwnersSourceServer(Result)
	
	If IsTempStorageURL(Result) Then
		Table = GetFromTempStorage(Result); // ValueTable -
		TableOfOwnersSource.Load(Table);
		
		SelectedOwnersSource.Clear();
		For Each String In TableOfOwnersSource Do
			If String.Check Then
				SelectedOwnersSource.Add(String.Owner);
			EndIf;
		EndDo;
		
		If SelectedOwnersSource.Count() Then
			OwnersOfSourcePanels = StrConcat(SelectedOwnersSource.UnloadValues(), ";")
		Else
			OwnersOfSourcePanels = "";
		EndIf;
		
		UpdateSourcePanelTree();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateSelectedReceiverOwners(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	UpdateSelectedReceiverOwnersServer(Result);
	ExpandReceiverPanel();
	
EndProcedure

&AtServer
Procedure UpdateSelectedReceiverOwnersServer(Result)
	
	If IsTempStorageURL(Result) Then
		Table = GetFromTempStorage(Result); // ValueTable -
		ReceiverOwnersTable.Load(Table);
		
		SelectedOwnersReceiver.Clear();
		For Each String In ReceiverOwnersTable Do
			If String.Check Then
				SelectedOwnersReceiver.Add(String.Owner);
			EndIf;
		EndDo;
		
		If SelectedOwnersReceiver.Count() Then
			OwnersOfReceiverPanels = StrConcat(SelectedOwnersReceiver.UnloadValues(), ";");
		Else
			OwnersOfReceiverPanels = "";
		EndIf;
		
		UpdateTreeOfReceiverPanels();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OwnersOfSourcePanelsClearingServer()
	
	SelectedOwnersSource.Clear();
	For Each String In TableOfOwnersSource Do
		String.Check = False;
	EndDo;

	UpdateSourcePanelTree();
EndProcedure

&AtServer
Procedure OwnersOfReceiverPanelsClearingServer()
	
	SelectedOwnersReceiver.Clear();
	For Each String In ReceiverOwnersTable Do
		String.Check = False;
	EndDo;
		
	UpdateTreeOfReceiverPanels();
	
EndProcedure

&AtServer
Procedure StatesOfOwnersOfReceiverClearingServer()
	
	SelectedStatesOwnersReceiver.Clear();
	For Each String In StateTableOfOwnersOfReceiver Do
		String.Check = False;
	EndDo;
	
	UpdateTreeOfReceiverPanels();
	
EndProcedure

&AtServer
Function CanDelete(RowID)
	
	CanDelete = True;
	
	Tree = FormAttributeToValue("ReceiverPanels");
	TreeRow = Tree.Rows.Find(RowID, "RowID", True); //ValueTreeRow
	
	Panel = DataProcessors.Manage1CAnalyticsPanels.FindByID(Panels, TreeRow.PanelOwner, "Owner");

	If TreeRow.IsReference And TreeRow.Parent.Id <> Panel.Data_RootFolderId Then
		CanDelete = False;
	EndIf;
			
	Return CanDelete;
	
EndFunction

&AtClient
Procedure UpdateSelectedStatesOfOwnersOfReceiver(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	UpdateSelectedStatesOfOwnersOfReceiverServer(Result);
	ExpandReceiverPanel();
	
EndProcedure

&AtServer
Procedure UpdateSelectedStatesOfOwnersOfReceiverServer(Result)
	
	If IsTempStorageURL(Result) Then
		Table = GetFromTempStorage(Result);
		StateTableOfOwnersOfReceiver.Load(Table);
		
		SelectedStatesOwnersReceiver.Clear();
		For Each String In StateTableOfOwnersOfReceiver Do
			If String.Check Then
				SelectedStatesOwnersReceiver.Add(String.State);
			EndIf;
		EndDo;
		
		If SelectedStatesOwnersReceiver.Count() Then
			StatesOfOwnersOfReceiver = StrConcat(SelectedStatesOwnersReceiver.UnloadValues(), ";");
		Else
			StatesOfOwnersOfReceiver = "";
		EndIf;
		
		UpdateTreeOfReceiverPanels();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetVisibilityOfElementsWhenSwitchingSource(Val SwitchValue)
	
	If SwitchValue = 0 Then
		Items.ServerAddressHyperlink.Visible = True;
		Items.PanelFile.Visible = False;
		Items.DownloadPanelsFromService.Visible = False;
		Items.ReceiverPanelsStatusPicture_2.Visible = False;
		Items.StatesOfOwnersOfReceiver.Visible = False;
		Items.SaveToFileSubmenu.Visible = True;
		
	ElsIf SwitchValue = 1 Then
		Items.ServerAddressHyperlink.Visible = False;
		Items.PanelFile.Visible = True;
		Items.DownloadPanelsFromService.Visible = False;
		Items.ReceiverPanelsStatusPicture_2.Visible = True;
		Items.StatesOfOwnersOfReceiver.Visible = True;
		Items.SaveToFileSubmenu.Visible = False;
		
		
	EndIf;
	
EndProcedure


&AtServer
Procedure UpdateCacheOfCurrentDates(ResultAddress)
	
	ResultStructure1 = GetFromTempStorage(ResultAddress);
	
	ResultDashboards  = ResultStructure1.DashboardsFromFile;
	ChartResult = ResultStructure1.DiagramsFromFile;
		
	If SourceFromFile = 1 Then
		TableOfRelevance = CurrentDatesFromFile;
	ElsIf SourceFromFile = 2 Then
		TableOfRelevance = CurrentDatesFromService;
	Else
		Return;
	EndIf;
	
	TableOfRelevance.Clear();
	For Each Dashboard In ResultDashboards Do
		FillPropertyValues(TableOfRelevance.Add(), Dashboard);
	EndDo;
	
	For Each Chart In ChartResult Do
		FillPropertyValues(TableOfRelevance.Add(), Chart);
	EndDo;
	
EndProcedure

&AtServer
Function StateCorrespondsToSelection(String, Table)
	
	LineDate = String.Updated;
	State = Undefined;
	
	LineFromFile = Table.FindRows(New Structure("Id", String.Id));
	If LineFromFile.Count() Then
		DateFromFile = LineFromFile[0].Updated;
		
		If LineDate = DateFromFile Then
			State = CurrentState();
		ElsIf LineDate <> DateFromFile Then
			State = StateIsNotUpToDate();
		EndIf;
	EndIf;
	
	If SelectedStatesOwnersReceiver.FindByValue(State) <> Undefined Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

&AtClient
Procedure BeforeUpdatingSourceTree()
	
	SourceIsBeingUpdated = True;
	ReceiverIsBeingUpdated = False;
	
EndProcedure

&AtClient
Procedure BeforeUpdatingReceiverTree()
	
	SourceIsBeingUpdated = False;
	ReceiverIsBeingUpdated = True;
	
EndProcedure

&НаКлиентеНаСервереБезконтекста
Function CurrentState()
	
	Return NStr("vi = 'Cập nhật';
				|ru = 'Актуальный';
				|en = 'Relevant'; fa = 'Relevant';
				|it = 'Relevant';
				|pl = 'Relevant';
				|tr = 'Güncel'");
	
EndFunction

&НаКлиентеНаСервереБезконтекста
Function StateIsNotUpToDate()
	
	Return NStr("vi = 'Chưa cập nhật';
				|ru = 'Не актуальный';
				|en = 'Not relevant'; fa = 'نامربوط';
				|it = 'Not relevant';
				|pl = 'Not relevant';
				|tr = 'Güncel değil'");
	
EndFunction

&AtClient
Function TreeRowNumberById(TreeOnForm, Id)
	
	ResultLineNumber = Undefined;
	
	TreeRows = TreeOnForm.GetItems();
	For Each TreeRow In TreeRows Do
		
		ResultLineNumber = TreeRowNumberById(TreeRow, Id);
		If ResultLineNumber <> Undefined Then
			Return ResultLineNumber;
		EndIf;
		
		If TreeRow.Id = Id Then
			Return TreeRow.GetID();
		EndIf;
		
	EndDo;
	
	Return ResultLineNumber;
EndFunction

&AtServer
Function NewSetOfTables()
	
	Structure = New Structure;
	Structure.Insert("ChartsTable");
	Structure.Insert("DashboardTable");
	Structure.Insert("FoldersTable");
	Structure.Insert("TableOfRelevance");
	
	If SourceFromFile = 1 Then
		Structure.TableOfRelevance = CurrentDatesFromFile;
	ElsIf SourceFromFile = 2 Then
		Structure.TableOfRelevance = CurrentDatesFromService;
	EndIf;
	
	Return Structure;
	
EndFunction

&AtClient
Procedure UpdateTablesWhenSwitchingSettingsSource()
	
	OwnersOfSourcePanels = "";
	SelectedOwnersSource.Clear();
	
	UpdateSourceOwnerTable();
	BeforeUpdatingSourceTree();
	UpdateSourcePanelTree();
	ExpandSourcePanel();
	
	UpdateReceiverOwnerTable();
	BeforeUpdatingReceiverTree();
	UpdateTreeOfReceiverPanels();
	ExpandReceiverPanel();
	
EndProcedure

#EndRegion

#EndRegion
