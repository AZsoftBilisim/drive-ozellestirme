#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	InitializingListSettings();
	Items.SettingsFilter.Visible = SelectionSet();
	// Handler of the "Assignment" mechanism.
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	ApplicationFormalized = Undefined;
	GoodsResearchIsUsed = GoodsResearchIsUsed();
	HyperlinkWhenActivated(ActiveHyperlink(ApplicationFormalized).Name, True);
	RestoreFormSettingsWhenCreating();
	StartTaskUploadItems();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EnableHandlerForWaitingForTaskToCompleteFillingInGoods();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PurposeOnChange(Item)
	
	WhenSelectionChangesOnServer();
	EnableHandlerForWaitingForTaskToCompleteFillingInGoods();
	
EndProcedure

&AtClient
Procedure ProductsOnChange(Item)
	
	WhenSelectionChangesOnServer();
	EnableHandlerForWaitingForTaskToCompleteFillingInGoods();
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WhenSelectionChangesOnServer();
	EnableHandlerForWaitingForTaskToCompleteFillingInGoods();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Item.CurrentData = Undefined Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	Data = Undefined;
	
	If Field = Items.GoodsControlledLotReference Then
		
		Data = AttributesOfLotReference(Item.CurrentData.ControlledLotReference)
		
	ElsIf Field = Items.GoodsIsLocked And Item.CurrentData.InTransitProcess Then
		
		ShowMessageBox(, NStr("vi = 'Có điểu chuyển hàng hóa bị khóa chưa hoàn tất.';
								|ru = 'Есть незавершенное перемещение заблокированного товара.';
								|en = 'There is an incomplete transfer of the locked goods.'; fa = 'There is an incomplete transfer of the locked goods.';
								|it = 'There is an incomplete transfer of the locked goods.';
								|pl = 'There is an incomplete transfer of the locked goods.';
								|tr = 'Kilitli ürünün tamamlanmamış transferi var.'"));
		
	EndIf;
	
	If ValueIsFilled(Data) Then
		ShowValue(, Data);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AllHyperlinks(Command)
	
	HyperlinkWhenActivated(Items.AllHyperlinks.Name);
	EnableHandlerForWaitingForTaskToCompleteFillingInGoods();
	
EndProcedure

&AtClient
Procedure ApplicationFormalizedHyperlink(Command)
	
	HyperlinkWhenActivated(Items.ApplicationFormalizedHyperlink.Name);
	EnableHandlerForWaitingForTaskToCompleteFillingInGoods();
	
EndProcedure

&AtClient
Procedure ApplicationHasNotBeenIssuedHyperlink(Command)
	
	HyperlinkWhenActivated(Items.ApplicationHasNotBeenIssuedHyperlink.Name);
	EnableHandlerForWaitingForTaskToCompleteFillingInGoods();
	
EndProcedure

&AtClient
Procedure IssueQualityControlReport(Command)
	
	RowsSelected = Items.Goods.SelectedRows;
	If RowsSelected.Count() = 0 Then
		
		ShowMessageBox(, NStr("vi = 'Chưa chọn dòng nào trong danh sách hàng hóa. Lệnh không được thực hiện';
								|ru = 'Не выбрано ни одной строки списка товаров. Команда не выполнена';
								|en = 'No goods are selected. The command is not performed'; fa = 'No goods are selected. The command is not performed';
								|it = 'No goods are selected. The command is not performed';
								|pl = 'No goods are selected. The command is not performed';
								|tr = 'Ürün listesinden hiç satır seçilmedi. Komut gerçekleştirilmedi'"));
		Return;
		
	EndIf;
	
	ControlledLotReference = Object.Goods.FindByID(RowsSelected[0]).ControlledLotReference;
	For Each RowSelected In RowsSelected Do
		If Object.Goods.FindByID(RowSelected).ControlledLotReference <> ControlledLotReference Then
			ShowMessageBox(, NStr("vi = 'Cần phải chọn các dòng thuộc cùng một lô hàng được kiểm soát. Không thể tạo một ""Biên bản kiểm soát chất lượng"" cho nhiều lô hàng được kiểm soát.';
									|ru = 'Необходимо выбрать строки, относящиеся к одной контролируемой партии. Один ""Акт контроля качества"" на несколько контролируемых партий не может быть создан.';
									|en = 'Select the lines related to one controlled lot. Cannot create one ""Quality control certificate"" for several controlled lots.'; fa = 'Select the lines related to one controlled lot. Cannot create one ""Quality control certificate"" for several controlled lots.';
									|it = 'Select the lines related to one controlled lot. Cannot create one ""Quality control certificate"" for several controlled lots.';
									|pl = 'Select the lines related to one controlled lot. Cannot create one ""Quality control certificate"" for several controlled lots.';
									|tr = 'Aynı kontrole tabi lota ait satırların seçilmesi gerekir. Birden fazla kontrole tabi lot için tek bir ""Kalite Kontrol Tutanağı"" oluşturulamaz.'"));
			Return;
		EndIf;
	EndDo;
	
	Analysts = PutAnalyticsInStorage(False);
	OpenForm(
		"Document.GoodsQualityControlCertificate.Form.DocumentForm",
		New Structure("FillInByBalance,Analysts", True, Analysts),
		ThisObject,
		UUID);
	
EndProcedure

&AtClient
Procedure ApplyForQualityControl(Command)
	
	If Items.Goods.SelectedRows.Count() = 0 Then
		
		ShowMessageBox(, NStr("vi = 'Chưa chọn dòng nào trong danh sách hàng hóa. Lệnh không được thực hiện';
								|ru = 'Не выбрано ни одной строки списка товаров. Команда не выполнена';
								|en = 'No goods are selected. The command is not performed'; fa = 'No goods are selected. The command is not performed';
								|it = 'No goods are selected. The command is not performed';
								|pl = 'No goods are selected. The command is not performed';
								|tr = 'Ürün listesinden hiç satır seçilmedi. Komut gerçekleştirilmedi'"));
		Return;
		
	EndIf;
	
	ThereAreLines = False;
	For Each Id In Items.Goods.SelectedRows Do
		
		If Not Object.Goods.FindByID(Id).ThisIsARequestForControl Then
			ThereAreLines = True;
			Break;
		EndIf;
		
	EndDo;
	
	If Not ThereAreLines Then
		
		ShowMessageBox(,
			NStr("vi = 'Không thể tạo giấy đề nghị kiểm soát chất lượng hàng hóa cho các lô hàng được kiểm soát đã được liên kết với các giấy đề nghị kiểm soát chất lượng hàng hóa khác.';
				|ru = 'Заявку на контроль качества товаров нельзя создать для контролируемых партий, связанных с другими заявками на контроль качества товаров.';
				|en = 'Cannot create a request for goods quality control for controlled lots related to other requests for goods quality control.'; fa = 'Cannot create a request for goods quality control for controlled lots related to other requests for goods quality control.';
				|it = 'Cannot create a request for goods quality control for controlled lots related to other requests for goods quality control.';
				|pl = 'Cannot create a request for goods quality control for controlled lots related to other requests for goods quality control.';
				|tr = 'Diğer kalite kontrol talepleriyle ilişkili kontrole tabi lotlar için ürün kalite kontrol talebi oluşturulamaz.'"));
		Return;
		
	EndIf;
	
	Analysts = PutAnalyticsInStorage(True);
	FillingData = QualityControlClientServer.NewDataOnFillingOutApplicationForQualityControlOfGoods();
	FillingData.ReasonForGoodsLock
		= PredefinedValue("Catalog.GoodsLockReasons.InputQualityControlOfGoods");
	
	OpenForm(
		"Document.RequestForGoodsQualityControl.Form.DocumentForm",
		New Structure("FillInByBalance,Analysts,FillingData", True, Analysts, FillingData),
		ThisObject,
		UUID);
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	StartTaskUploadItems();
	EnableHandlerForWaitingForTaskToCompleteFillingInGoods();
	
EndProcedure

&AtClient
Procedure QualityControlCertificates(Command)
	
	OpenForm("Document.GoodsQualityControlCertificate.Form.ListForm");
	
EndProcedure

&AtClient
Procedure QualityControlApplications(Command)
	
	If GoodsResearchIsUsed Then
		OpenForm("Document.RequestForGoodsQualityControl.Form.FulfillmentOfResearchRequests");
		Return;
	Else
		OpenForm("Document.RequestForGoodsQualityControl.Form.ListForm");
	EndIf;
	
EndProcedure

&AtClient
Procedure CustomizeList(Command)
	
	FormParameters = New Structure();
	FormParameters.Insert("SchemaURL", AddressOfDataLayoutSchemeListSettings);
	FormParameters.Insert("ListSettings", ListSettings);
	CallbackDescription = New CallbackDescription("ListSettingsCompletion", ThisObject);
	OpenForm("Report.ListSettings.Form.ListSettings", FormParameters, , , , , CallbackDescription);
	
EndProcedure

&AtClient
Procedure SaveListSettings(Command)
	
	FormParameters = New Structure();
	FormParameters.Insert("ObjectKey", "GoodsUnderQualityControl");
	FormParameters.Insert("SettingsKey", "GoodsUnderQualityControl.ListSettings");
	CallbackDescription = New CallbackDescription("SaveListSettingsCompletion", ThisObject);
	OpenForm("ФормаСохраненияПользовательскихНастроекДинамическихСписков", 
			FormParameters,
			,
			,
			,
			, 
			CallbackDescription, 
			FormWindowOpeningMode.LockOwnerWindow);
			
EndProcedure

&AtClient
Procedure SelectListSettings(Command)
	
	FormParameters = New Structure();
	FormParameters.Insert("ObjectKey", "GoodsUnderQualityControl");
	FormParameters.Insert("SettingsKey", "GoodsUnderQualityControl.ListSettings");
	CallbackDescription = New CallbackDescription("SelectListSettingsCompletion", ThisObject);
	OpenForm("ФормаЗагрузкиПользовательскихНастроекДинамическихСписков", 
			FormParameters,
			,
			,
			,
			, 
			CallbackDescription, 
			FormWindowOpeningMode.LockOwnerWindow);
			
EndProcedure

#EndRegion

#Region Private

#Region LoadingListOfGoods

&AtServer
Procedure StartTaskUploadItems()
	
	If ResultOfCompletingTaskOfFillingInGoods <> Undefined Then
		Return;
	EndIf;
	
	DataCompositionSchema = GetFromTempStorage(AddressOfDataLayoutSchemeListSettings);
	
	// SKD loading
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	SettingsComposer.LoadSettings(ListSettings.GetSettings());
	SettingsComposer.Refresh();
	
	SettingsUsed = SettingsComposer.GetSettings();
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground = True;
	FunctionName = "DataProcessors.GoodsUnderQualityControl.CompleteTaskOfFillingInGoods";
	
	FunctionParameters = QualityControlClientServer.FillingParametersOfItemsForQualityControl();
	FunctionParameters.Filter.Warehouse = ?(ValueIsFilled(Warehouse), Warehouse, Undefined);
	FunctionParameters.Filter.Products = ?(ValueIsFilled(Products), Products, Undefined);
	FunctionParameters.Filter.Purpose = ?(ValueIsFilled(Purpose), Purpose, Undefined);
	FunctionParameters.Filter.ApplicationFormalized = ?(ValueIsFilled(ApplicationFormalized), ApplicationFormalized, Undefined);
	FunctionParameters.CompositionSettings = SettingsUsed;
	
	ResultOfCompletingTaskOfFillingInGoods = TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters, FunctionName, FunctionParameters);
	
	If ResultOfCompletingTaskOfFillingInGoods.Status = "Completed2" Then
		UploadProducts(ResultOfCompletingTaskOfFillingInGoods.ResultAddress);
		ResultOfCompletingTaskOfFillingInGoods = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure EnableHandlerForWaitingForTaskToCompleteFillingInGoods()
	
	If ResultOfCompletingTaskOfFillingInGoods <> Undefined Then
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = True;
		IdleParameters.OwnerForm = ThisObject;
		CallbackOnCompletion = New CallbackDescription("LoadGoodsNotificationHandler", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(
			ResultOfCompletingTaskOfFillingInGoods, CallbackOnCompletion, IdleParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadGoodsNotificationHandler(Result, AdditionalParameters) Export
	
	ResultOfCompletingTaskOfFillingInGoods = Undefined;
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		UploadProducts(Result.ResultAddress);
	EndIf;
	
EndProcedure

&AtServer
Procedure UploadProducts(StorageAddress)
	
	Table = GetFromTempStorage(StorageAddress);
	Object.Goods.Load(Table);
	
EndProcedure

&AtServer
Procedure WhenSelectionChangesOnServer()
	
	SaveFormSettings();
	StartTaskUploadItems();
	
EndProcedure

#EndRegion

#Region FormSettings

&AtServer
Procedure RestoreFormSettingsWhenCreating()
	
	FormSettings = FormDataSettingsStorage.Load(
		ObjectKeySettingsManager(), SettingsManagerSettingsKey());
	If ValueIsFilled(FormSettings) Then
		FillPropertyValues(ThisObject, FormSettings);
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveFormSettings()
	
	FormSettings = SavedFormSettings();
	
	FillPropertyValues(FormSettings, ThisObject);
	FormDataSettingsStorage.Save(
		ObjectKeySettingsManager(), SettingsManagerSettingsKey(), FormSettings);
	
EndProcedure

&AtServer
Function SavedFormSettings()
	
	Result = New Structure;
	Result.Insert("Warehouse");
	Result.Insert("Products");
	Result.Insert("Purpose");
	
	Return Result;
	
EndFunction

&AtServer
Function ObjectKeySettingsManager()
	
	Return "GoodsUnderQualityControl";
	
EndFunction

&AtServer
Function SettingsManagerSettingsKey()
	
	Return "FormSettings";
	
EndFunction

#EndRegion

#Region SettingUpLists

&AtServer
Procedure InitializingListSettings()
	
	Filters = DataProcessors.GoodsUnderQualityControl.GetTemplate("Filters");
	AddressOfDataLayoutSchemeListSettings = PutToTempStorage(Filters, UUID);
	AvailableSettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataLayoutSchemeListSettings);
	ListSettings.Initialize(AvailableSettingsSource);
	ListSettings.LoadSettings(Filters.DefaultSettings);
	
EndProcedure

&AtClient
Procedure ListSettingsCompletion(ClosingResult, AdditionalParameters) Export
	
	If TypeOf(ClosingResult) = Type("DataCompositionSettingsComposer") Then
		ConfiguringListATServer(ClosingResult);
		EnableHandlerForWaitingForTaskToCompleteFillingInGoods();
	EndIf;
	
EndProcedure

&AtServer
Function SelectionSet()
	
	FilterItems1 = ListSettings.GetSettings().Filter.Items;
	For Each FilterElement In FilterItems1 Do
		If FilterElement.Use Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Procedure ConfiguringListATServer(Val SettingsComposer)
	
	ListSettings.LoadSettings(SettingsComposer.GetSettings());
	ListSettings.LoadUserSettings(SettingsComposer.UserSettings);
	Items.SettingsFilter.Visible = SelectionSet();
	StartTaskUploadItems();
	
EndProcedure

&AtClient
Procedure SelectListSettingsCompletion(ClosingResult, AdditionalParameters) Export
	
	If TypeOf(ClosingResult) = Type("SettingsChoice") Then
		SelectListSettingsAtServer(ClosingResult.SettingsKey);
		EnableHandlerForWaitingForTaskToCompleteFillingInGoods();
	EndIf; 
	
EndProcedure

&AtServer
Procedure SelectListSettingsAtServer(Val SettingsKey)
	
	Reports.ListSettings.DownloadSettingsFromStorage(
		"GoodsUnderQualityControl.ListSettings",
		SettingsKey,
		ListSettings);
	Items.SettingsFilter.Visible = SelectionSet();
	StartTaskUploadItems();
	
EndProcedure

&AtClient
Procedure SaveListSettingsCompletion(ClosingResult, AdditionalParameters) Export
	
	If TypeOf(ClosingResult) = Type("SettingsChoice") Then
		SaveListSettingsAtServer(ClosingResult.SettingsKey);
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveListSettingsAtServer(Val SettingsKey)
	
	Reports.ListSettings.SaveSettingsInStorage(
		"GoodsUnderQualityControl.ListSettings",
		SettingsKey,
		ListSettings);
	
EndProcedure

#EndRegion

#Region Research

&AtServerNoContext
Function GoodsResearchIsUsed()
	
	UseResearch = False;
	UseResearch = GetFunctionalOption("UseGoodsQualityResearch");
	Return UseResearch;
	
EndFunction

#EndRegion

&AtServer
Function ActiveHyperlink(ApplicationFormalized)
	
	If ApplicationFormalized = Undefined Then
		Return Items.AllHyperlinks;
	ElsIf ApplicationFormalized = True Then
		Return Items.ApplicationFormalizedHyperlink;
	Else
		Return Items.ApplicationHasNotBeenIssuedHyperlink;
	EndIf;
	
EndFunction

&AtServer
Procedure HyperlinkWhenActivated(TagName, Initialize = False)
	
	Item = Items[TagName];
	Items.AllHyperlinks.Enabled = True;
	Items.ApplicationFormalizedHyperlink.Enabled = True;
	Items.ApplicationHasNotBeenIssuedHyperlink.Enabled = True;
	Item.Enabled = False;
	
	If Not Initialize Then
		
		If Item = Items.AllHyperlinks Then
			ApplicationFormalized = Undefined;
		ElsIf Item = Items.ApplicationFormalizedHyperlink Then
			ApplicationFormalized = True;
		Else
			ApplicationFormalized = False;
		EndIf;
		
		StartTaskUploadItems();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	CurrentDayStart = BegOfDay(CurrentSessionDate());
	
	// Expired control period.
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Tô sáng thời hạn kiểm soát đã quá hạn.';
							|ru = 'Подсветка просроченного срока контроля.';
							|en = 'Highlight the expired control period.'; fa = 'Highlight the expired control period.';
							|it = 'Highlight the expired control period.';
							|pl = 'Highlight the expired control period.';
							|tr = 'Vadesi geçmiş kontrol süresinin vurgulanması.'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsControlTerm.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(Items.GoodsControlTerm.DataPath);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(Items.GoodsControlTerm.DataPath);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = CurrentDayStart;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDocument);
	
	// The parties are blocked forever.
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Các lô hàng bị khóa vĩnh viễn.';
							|ru = 'Партии заблокированные навсегда.';
							|en = 'Permanently locked lots.'; fa = 'Permanently locked lots.';
							|it = 'Permanently locked lots.';
							|pl = 'Permanently locked lots.';
							|tr = 'Sonsuza kadar kilitli lotlar.'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsControlTerm.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(Items.GoodsControlTerm.DataPath);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có kế hoạch mở khóa>';
													|ru = '<разблокировка не планируется>';
													|en = '<unlocking is not planned>'; fa = '<unlocking is not planned>';
													|it = '<unlocking is not planned>';
													|pl = '<unlocking is not planned>';
													|tr = '<kilidi kaldırma planlanmıyor>'"));
	
EndProcedure

&AtServer
Function PutAnalyticsInStorage(ToExcludeControlRequests)
	
	Rows = New Array(Items.Goods.SelectedRows.Count());
	IndexOf = 0;
	For Each RowID In Items.Goods.SelectedRows Do
		Rows[IndexOf] = Object.Goods.FindByID(RowID);
		IndexOf = IndexOf + 1;
	EndDo;
	RowKey =
		"ControlledLotReference,
		|Products,
		|Characteristic,
		|Warehouse,
		|Purpose,
		|Premise,
		|Series,
		|ThisIsARequestForControl";
	Analysts = Object.Goods.Unload(Rows, RowKey);
	If ToExcludeControlRequests Then
		Analysts = Analysts.Copy(New Structure("ThisIsARequestForControl", False));
	EndIf;
	Analysts.Columns.Delete("ThisIsARequestForControl");
	AddressInStorage = PutToTempStorage(Analysts, UUID);
	Return AddressInStorage;
	
EndFunction

&AtServerNoContext
Function AttributesOfLotReference(ControlledLotReference)
	
	SetPrivilegedMode(True);
	Return Common.ObjectAttributeValue(ControlledLotReference, "Lot");
	
EndFunction

#EndRegion
