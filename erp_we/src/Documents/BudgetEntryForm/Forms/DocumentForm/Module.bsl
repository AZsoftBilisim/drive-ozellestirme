#Region Variables

&AtClient
Var IdleHandlerParameters;

&AtClient
Var CellAfterInput; // Boolean -

&AtClient
Var DisconnectionTime; // Boolean - 

&AtClient
Var DoubleQuestionDialogIsOpen; // Boolean -

&AtClient
Var ChangesToListAreReflectedInDocument; // Boolean - 

#EndRegion

#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	If Not ExecutingTheChangeCalculationJob Then
		RunReportExecutionCheck();
	Else
		RunChangeCalculationCheck();
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

	CommonInternalClient.SetIndicatorsPanelVisibiility(Items, ExpandIndicatorsArea);
	CalculateIndicators(MainIndicator);

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // refund upon receipt of the form for analysis
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Parameters.Property("Basis") And TypeOf(Parameters.Basis) = Type("DocumentRef.BudgetEntryForm") Then
		FoundationStatus = Common.ObjectAttributeValue(Parameters.Basis, "Status");
		If FoundationStatus = Enums.PlanStatuses.UnderPreparation
			Or FoundationStatus = Enums.PlanStatuses.RolledBack_ Then
			Raise NStr(
				"vi = 'Không cho phép nhập điều chỉnh ngân sách có trạng thái ""Đang chuẩn bị"" hoặc ""Đã hủy""';
				|ru = 'Недопустимо вводить корректировку бюджета со статусом ""В подготовке"" или ""Отменен""';
				|en = 'You cannot enter a budget adjustment with the ""Under development"" or ""Canceled"" status'; fa = 'You cannot enter a budget adjustment with the ""Under development"" or ""Canceled"" status';
				|it = 'Недопустимо вводить корректировку бюджета со статусом ""В подготовке"" или ""Отменен""';
				|pl = 'You cannot enter a budget adjustment with the ""Under development"" or ""Canceled"" status';
				|tr = '""Hazırlanıyor"" veya ""İptal edildi"" durumundaki bütçe düzeltmelerinin girilmesi mümkün değildir'");
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	ParametersStructure = PrepareParametersForBudgetViewOutput();
	ItemParameterCache = BudgetingServer.FillCacheOfArticleParameters(ParametersStructure);
	
	If ParametersStructure = Undefined
		Or Not ValueIsFilled(Object.Scenario)
		Or Not ValueIsFilled(Object.BeginOfPeriod)
		Or Not ValueIsFilled(Object.PeriodEnding) Then
		Items.MainPanel.CurrentPage = Items.PageGeneral;
	Else
		Items.MainPanel.CurrentPage = Items.BudgetPage;
	EndIf;
	GetAvailabilityOfItemsByBudgetIssue();
	SetDocumentHeaderFields();
	SetAvailabilityOfBudgetingModel();
	SetAvailabilityOfItemsByStatusServer();
	SetAvailabilityOfItemsAfterCheckingFill();
	SetScriptParameters();
	
	SetParametersForSelectingBudgetItemToAdjustTurnover();
	If Object.Action = Enums.TypesOfBudgetEntryFormActions.AdjustByBudgetFlowItems Then
		FillInTableOfAdjustmentsByBudgetItems();
		CalculateTotalAmountsOfAdjustment(ThisObject);
		SetVisibilityOfColumnsByAdjustments(ThisObject);
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	FileInformationSecurity = Common.FileInfobase();
	
	Catalogs.BudgetProfiles.ConfigureGroupOfPeriodElements(Object.BudgetProfile, Items, Object.ActualDataLimit);
	
	DetailsDataAddress = PutToTempStorage(Undefined, UUID);
	
	If ValueIsFilled(Object.BudgetProfile) And Items.BudgetPage.Visible Then
		EditMode = Common.CommonSettingsStorageLoad("BudgetProfile_" + XMLString(Object.BudgetProfile), "EditMode");
		If ValueIsFilled(EditMode) Then
			Items.PanelBudget.CurrentPage = Items[EditMode];
		EndIf;
	EndIf;
	
	WhenChangingBudgetEditingMethod();
	
	PreviousLineOfItemTree = -1;
	
	SetAvailabilityOfClipboardCommands();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	OptionsParameters = New Structure("BudgetingModel", Object.BudgetingModel);
	SetFormFunctionalOptionParameters(OptionsParameters);
	UseBudgetConfirmation = GetFormFunctionalOption("UseBudgetConfirmation");
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(Result, ChoiceSource)
	
	If TypeOf(Result) = Type("CatalogRef.BudgetEntryFormAttachedFiles") Then
		AbilityToRead = AbilityToReadAttachedFile(Result);
		If Not AbilityToRead.ReadingIsPossible Then
			ShowMessageBox(, AbilityToRead.ErrorText);
		Else
			DownloadFromExcelOnClient(Result);
		EndIf;
	EndIf;
	
	If ChoiceSource.FormName = "Document.BudgetEntryForm.Form.FormOfMappingOfImportedDataFromExcel" Then
		UploadBudgetToServer(Result);
		UpdateBudget();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);

	OnReadCreateAtServer();
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CheckData_BeforeWrite(CurrentObject);
	
	If Object.Action = Enums.TypesOfBudgetEntryFormActions.AdjustByBudgetFlowItems Then
		WriteDownTableOfAdjustmentsByBudgetItems(CurrentObject);
	EndIf;
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"AutomaticRecalculation",
		"Check",
		AutomaticUpdateOfTheBudget);
		
	RestoreCellSizes();
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	SavedColumnWidth = New Array;
	For Cnt = 1 To Budget.TableWidth Do
		SavedColumnWidth.Add(Budget.Area(,Cnt,,Cnt).ColumnWidth);
	EndDo;
	
	FormDataSettingsStorage.Save(FormName,
		"ColumnWidth__" + Object.Ref.UUID(),
		SavedColumnWidth);
	
	StoredRowHeight = New Array;
	For Cnt = 1 To Budget.TableHeight Do
		StoredRowHeight.Add(Budget.Area(Cnt,,Cnt,).RowHeight);
	EndDo;
	
	FormDataSettingsStorage.Save(FormName,
		"RowHeight_" + Object.Ref.UUID(),
		StoredRowHeight);
	
	If Not Items.Budget.StatePresentation.Visible Then
		// The budget is formed, the table is displayed
		SaveStoredTemplate();
	EndIf;
	
	If Items.BudgetPage.Visible Then
		EditMode = Items.PanelBudget.CurrentPage.Name;
		Common.CommonSettingsStorageSave("BudgetProfile_" + XMLString(Object.BudgetProfile), "EditMode", EditMode);
	EndIf;
	
	If Items.MainPanel.CurrentPage = Items.BudgetPage Then
		ReflectBudgetChanges();
	EndIf;
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_BudgetEntryForm", , Object.Ref);
	
	If Items.BudgetItemTree.Visible Then
		AttachIdleHandler("Attachable_ExpandTreeOfBudgetItems", 1, True);
	EndIf;
	
	SetLabelForUpdatingTotals(True);
	RunChangeCalculationCheck();
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		SetAvailabilityOfClipboardCommandsOnClient();
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BudgetProfileOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.BudgetEntryForm.DocumentForm.Item.BudgetProfile.OnChange",,
		True);
	
	WhenChangingBudgetTypeServer();
	RunReportExecutionCheck();
	
EndProcedure

&AtClient
Procedure BudgetingModelOnChange(Item)
	
	WhenBudgetingModelChangesServer();
	UpdateBudget();
	
EndProcedure

&AtClient
Procedure BudgetingModelChoiceProcessing(Item, ValueSelected, StandardProcessing)
	If Not BudgetingModelWorks(ValueSelected) Then
		StandardProcessing = False;
		WarningText = NStr("vi = 'Mô hình lập ngân sách không có hiệu lực.
									|Hãy thay đổi trạng thái mô hình để chọn trong chứng từ';
									|ru = 'Модель бюджетирования не действует.
									|Измените статус у модели для выбора в документе';
									|en = 'Budgeting model is invalid.
									|Change the model status for selection in the document'; fa = 'Budgeting model is invalid.
									|Change the model status for selection in the document';
									|it = 'Il modello del budgeting non funziona. 
									|Modificare lo status del modello per la selezione nel documento';
									|pl = 'Model budżetowania nie działa.
									|Zmień status modelu dla wyboru w dokumencie';
									|tr = 'Bütçeleme modeli etki etmiyor.
									|Belgede seçim yapabilmek için durum modelini değiştirin'");
		ShowMessageBox(,WarningText);
	EndIf;
EndProcedure

&AtClient
Procedure ScenarioOnChange(Item)
	
	WhenScriptChangesServer();
	UpdateBudget();
	
EndProcedure

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Object.PeriodEnding = ?(Object.BeginOfPeriod > Object.PeriodEnding, Object.BeginOfPeriod, Object.PeriodEnding);
	OnPeriodChangeServer();
	UpdateBudget();
	
EndProcedure

&AtClient
Procedure PeriodEndingOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Object.BeginOfPeriod = ?(Object.BeginOfPeriod > Object.PeriodEnding, Object.PeriodEnding, Object.BeginOfPeriod);
	OnPeriodChangeServer();
	UpdateBudget();
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure ActionOnChange(Item)
	
	If Object.Action = PredefinedValue(
		"Enum.TypesOfBudgetEntryFormActions.CorrectBudgetEntryForm") Then
		AdditionalParameters = New Structure("Action", Object.Action);
		CallbackDescription = New CallbackDescription("ActionOnChangeCompletion", ThisObject, AdditionalParameters);
		QueryText = NStr("vi = 'Sẽ điền chứng từ bằng dữ liệu hiện tại của ngân sách. Tiếp tục?';
						|ru = 'Документ будет заполнен актуальными данными бюджета. Продолжить?';
						|en = 'The document will be filled with relevant budget data. Continue?'; fa = 'The document will be filled with relevant budget data. Continue?';
						|it = 'Документ будет заполнен актуальными данными бюджета. Продолжить?';
						|pl = 'The document will be filled with relevant budget data. Continue?';
						|tr = 'Belge, güncel bütçe verileriyle doldurulacak. Devam edilsin mi?'");
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		WhenChangingActionServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure BudgetOnChangeAreaContent(Item, Area)
	
	If Not Area.ContainsValue Then
		Items.Budget.Edit = False;
		Area.Text = "";
		WarningText = NStr("vi = 'Chỉnh sửa ô không được cung cấp';
							|ru = 'Редактирование ячейки не предусмотрено';
							|en = 'Storage bin editing is not supported'; fa = 'Storage bin editing is not supported';
							|it = 'Redazione delle caselle non è prevista';
							|pl = 'Edytowanie komórki nie jest przewidziane';
							|tr = 'Hücrede herhangi bir düzenleme mevcut değil'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	SetLabelForUpdatingTotals(True);
	
	Details = Area.Details;
	Details = BudgetReportingServerCall.DetailsValue(Details, DetailsDataAddress);
	Value = Area.Value;
	
	AbbreviatedDigits = 0;
	If Details.Property("AbbreviatedDigits", AbbreviatedDigits) Then
		Value = Value * Pow(10, AbbreviatedDigits);
	EndIf;
	
	ObjectAndCalculationParameters = BudgetReportingClientServer.StructureByBudgetInstanceObject(ThisObject);
	ReflectionResult = BudgetReportingClientServer.ReflectCellChange(ObjectAndCalculationParameters, Details, Value);
	CellAfterInput = True;
	
	ParametersOfNonContextCall = ParametersOfNonContextCall(ReflectionResult, Details, Area.Name);
	
	If AutomaticUpdateOfTheBudget Then
		
		BudgetWhenChangingServerAutoRecalculation(ParametersOfNonContextCall);
		RunChangeCalculationCheck();
		
	Else
		
		//Parameterynecontext Call= Parameterynecontext call(Result, Interpretation, Area.Name);
		ResultingStructure = BudgetWhenServerChanges(ParametersOfNonContextCall);
		
		If ResultingStructure <> Undefined Then
			ObjectAndCalculationParameters = BudgetReportingClientServer.StructureByBudgetInstanceObject(ThisObject);
			LoadResultOfCalculatingChangesOnClient(ObjectAndCalculationParameters, Budget, ResultingStructure);
		EndIf;
		
		SetLabelForUpdatingTotals();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BudgetDetailProcessing(Item, DetailsIndex, StandardProcessing)
	
	StandardProcessing = False;
	
	Details = BudgetReportingServerCall.DetailsValue(DetailsIndex, DetailsDataAddress);
	
	If TypeOf(Details) = Type("Structure") Then
		If Not Details.Property("DataLineIndex") And Details.Property("Value") Then
			
			If Details.Value <> Undefined Then
				ShowValue(Undefined, Details.Value);
			EndIf;
			
		Else
			
			If Not Object.DeletionMark And CheckFilling() Then
				If Modified Or Object.Ref.IsEmpty() Then
					CallbackDescription = New CallbackDescription("AfterSavingDocumentBeforeDecrypting", ThisObject);
					QueryText = NStr("vi = 'Giải mã chỉ có thể có trong chứng từ được kết chuyển. Kết chuyển?';
									|ru = 'Расшифровка возможна только в проведенном документе. Провести документ?';
									|en = 'Drill-down is only allowed for posted documents. Post the document?'; fa = 'Drill-down is only allowed for posted documents. Post the document?';
									|it = 'La decodifica è possibile solo per un documento registrato in contabilità. Registrare il documento?';
									|pl = 'Odszyfrowanie jest możliwe tylko w zaksięgowanym dokumencie. Zaksięgować dokument?';
									|tr = 'Deşifre sadece kaydedilen belgelerde mümkündür. Belge kaydedilsin mi?'");
					ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
				Else
					AfterSavingDocumentBeforeDecrypting(DialogReturnCode.Yes, Undefined);
				EndIf;
			Else
				WarningText = NStr("vi = 'Giải mã chỉ có thể có trong chứng từ được kết chuyển';
									|ru = 'Расшифровка возможна только в проведенном документе';
									|en = 'Drill-down is only allowed for posted documents'; fa = 'Drill-down is only allowed for posted documents';
									|it = 'La decodifica è possibile solo per un documento registrato in contabilità';
									|pl = 'Odszyfrowanie jest możliwe tylko w zaksięgowanym dokumencie.';
									|tr = 'Deşifre sadece kaydedilen belgelerde mümkündür'");
				ShowMessageBox(, WarningText);
			EndIf;
			
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BudgetWhenTheRegionIsActivated(Item)
	
	CurrentArea = Budget.CurrentArea;
	
	If CellAfterInput = True Then
		
		If CurrentArea.Left = 1 Then
			// This is a transition to a new line - we will set the first cell available for input as the current area.
			
			ThereAreInputCellsInRow = False;
			
			TopSearch = CurrentArea.Top;
			While Not ThereAreInputCellsInRow Do
				
				SearchRights = CurrentArea.Right + 1;
				ThereAreColumnsForInput = False;
				While SearchRights <= Budget.TableWidth Do
					
					AreaOnRight = Budget.Area(TopSearch, SearchRights);
					If AreaOnRight.ContainsValue Then
						ThereAreInputCellsInRow = True;
						Items.Budget.CurrentArea = AreaOnRight;
						Break;
					EndIf;
					SearchRights = SearchRights + 1;
					
				EndDo;
				
				If ThereAreInputCellsInRow Then
					Break;
				EndIf;
				
				TopSearch = TopSearch + 1;
				If TopSearch > Budget.TableHeight Then
					Break;
				EndIf;
				
			EndDo;
			
		ElsIf Not CurrentArea.ContainsValue = True Then
			// Transitions within the section
			
			BottomLeftArea_ = Budget.Area(CurrentArea.Top + 1, CurrentArea.Left - 1);
			If BottomLeftArea_.ContainsValue Then
				// Switching to a new line in the current section
				
				LeftSearch = BottomLeftArea_.Left;
				While LeftSearch >= 2 Do
					
					Area = Budget.Area(BottomLeftArea_.Top, LeftSearch);
					If Not Area.ContainsValue Then
						Break;
					EndIf;
					BottomLeftArea = Area;
					LeftSearch = LeftSearch - 1;
					
				EndDo;
				Items.Budget.CurrentArea = BottomLeftArea;
				
			Else
				
				// Moving to the next section through the vertical separator
				LeftSearch = CurrentArea.Left + 1;
				ThereAreColumnsForInput = False;
				While LeftSearch <= Budget.TableWidth Do
					
					AreaOnRight = Budget.Area(CurrentArea.Top, LeftSearch);
					If AreaOnRight.ContainsValue Then
						ThereAreColumnsForInput = True;
						Break;
					EndIf;
					LeftSearch = LeftSearch + 1;
					
				EndDo;
				If ThereAreColumnsForInput Then
					
					// find the first cell available for input
					InputArea = AreaOnRight;
					TopSearch = AreaOnRight.Top;
					While True Do
						TopArea = Budget.Area(TopSearch, LeftSearch);
						If Not TopArea.ContainsValue Then
							Break;
						Else
							InputArea = TopArea;
						EndIf;
						TopSearch = TopSearch - 1;
					EndDo;
					Items.Budget.CurrentArea = InputArea;
					
				EndIf;
			EndIf;
			
		EndIf;
	EndIf;
	CellAfterInput = False;

	AttachIdleHandler("CalculateIndicatorsDynamically", 0.2, True);
	
EndProcedure

&AtClient
Procedure BudgetProfileChoiceProcessing(Item, ValueSelected, StandardProcessing)
	UseToEnterPlan = Undefined;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.BudgetEntryForm.DocumentForm.Item.BudgetProfile.ChoiceProcessing");
	
	If Not ViewAndProcessSelectionOnServer(ValueSelected, UseToEnterPlan) Then
		
		ValueSelected = Undefined;
		StandardProcessing = False;
		WarningText = NStr("vi = 'Dạng ngân sách không hợp lệ để chọn trong bản ghi ngân sách:
										 |%1';
										 |ru = 'Вид бюджета не доступен для выбора в экземпляре бюджета:
										 |%1';
										 |en = 'Cannot select a budget profile in the Budget entry form:
										 |%1'; fa = 'Cannot select a budget profile in the Budget entry form:
										 |%1';
										 |it = 'La tipologia di budget non è disponibile per la selezione nel documento di inserimento del budget:
										 |%1';
										 |pl = 'Rodzaj budżetu nie jest dostępny do wyboru w egzemplarze budżetu:
										 |%1';
										 |tr = 'Bütçe profili, bütçe giriş formunun seçimi için kullanılamaz: 
										 |%1'");
		If UseToEnterPlan Then
			WarningText = StringFunctionsClientServer.SubstituteParametersToString(
				WarningText,
				NStr("vi = 'Có phát hiện lỗi';
					|ru = 'Обнаружены ошибки';
					|en = 'Errors are found'; fa = 'Errors are found';
					|it = 'Errori trovati';
					|pl = 'Wykryto błędy';
					|tr = 'Hatalar bulundu'"));
		Else
			WarningText = StringFunctionsClientServer.SubstituteParametersToString(
				WarningText,
				NStr("vi = 'Đặt cờ ""Sử dụng để nhập kế hoạch""';
					|ru = 'Установите флаг ""Использовать для ввода плана""';
					|en = 'Select the ""Use to enter plan"" check box'; fa = 'Select the ""Use to enter plan"" check box';
					|it = 'Mettete il flag ""Usare per l''inserimento del piano""';
					|pl = 'Zaznacz pole wyboru ""Wykorzystać do wprowadzenia planu""';
					|tr = '""Plan girmek için kullan"" onay işaretini kur'"));
		EndIf;
		
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	UpdateBudget();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	DivisionWhenChangedOnServer();
	UpdateBudget();
	
EndProcedure

&AtClient
Procedure ActualDataLimitClick(Item)
	
	FormParameters = New Structure("BudgetProfile, BeginOfPeriod, ActualDataLimit", Object.BudgetProfile, Object.BeginOfPeriod, Object.ActualDataLimit);
	CallbackDescription = New CallbackDescription("SetFactBoundary", ThisObject);
	OpenForm("CommonForm.ConfigureActualDataLimit", FormParameters,,,,,
						CallbackDescription,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBudgetItemTree

&AtClient
Procedure BudgetItemTreeOnActivateRow(Item)
	
	AttachIdleHandler("ProcessingActivationOfElementTreeRow", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBudgetEditList

&AtClient
Procedure BudgetEditListOnStartEdit(Item, NewRow, Copy)
	
	ChangesToListAreReflectedInDocument = False;
	
	If NewRow Then
		EditParameters = GetFromTempStorage(AddressOfLineEditingParameters);
		FixedValues = EditParameters.FixedValues;
		For Each KeyAndValue In FixedValues Do
			Item.CurrentData[KeyAndValue.Key] = KeyAndValue.Value;
		EndDo;
		For Each ColumnName In EditParameters.VariableMeasurements Do
			If StrFind(ColumnName, "Period") Then
				
				If ValueIsFilled(Item.CurrentData[ColumnName]) Then
					Continue;
				EndIf;
				
				PeriodicityByString = StrReplace(ColumnName, "Period", "");
				Periodicity = PredefinedValue("Enum.Periodicity." + PeriodicityByString);
				Item.CurrentData[ColumnName] = WorkingWithClientServerPeriods.BeginningDateOfPeriod(Object.BeginOfPeriod, Periodicity);
				
			EndIf;
		EndDo;
	Else
		ChangeableColumns = StringFunctionsClientServer.SplitStringIntoSubstringsArray(EditedListColumns);
		Details = New Structure();
		For Each Dimension In ChangeableColumns Do
			Details.Insert(Dimension, Item.CurrentData[Dimension]);
		EndDo;
		PutToTempStorage(Details, AddressOfEditedValuesOfListLine);
	EndIf;
	
EndProcedure

&AtClient
Function PerformChecksBeforeFinishingEditing(Item, Cancel, RowWillBeDeletedAutomatically)
	CheckResult = Undefined;
	
	HasErrors = ThereAreErrorsInBudgetEditLine(Item.CurrentRow, CheckResult);
	If HasErrors Then
		
		If Not RowWillBeDeletedAutomatically Then
			
			Cancel = True;
			
			If CheckResult.Result = "AfterEnteringValueThereWillBeDouble" Then
				
				AddlParameters = New Structure("Id", Item.CurrentRow);
				DecisionNotification = New CallbackDescription("SelectingLineIncrease", ThisObject, AddlParameters);
				QueryText = NStr("vi = 'Đã có dòng với các trường như vậy. Hợp nhất các dòng?
														|Có - hợp nhất các dòng
														|Không - xóa dòng
														|Hủy bỏ - tiếp tục chỉnh sửa';
														|ru = 'Строка с такими полями уже существует. Объединить строки?
														|Да - объединить строки
														|Нет - удалить строку
														|Отмена - продолжить редактирование';
														|en = 'Line with such fields already exists. Merge lines? 
														|Yes - merge the lines
														|No - remove the line
														|Cancel - continue editing'; fa = 'Line with such fields already exists. Merge lines? 
														|Yes - merge the lines
														|No - remove the line
														|Cancel - continue editing';
														|it = 'La riga con questi campi esiste già. Unire le righe?
														|Si - unire le righe
														|No - eliminare la riga
														|Annullare - continuare la redazione';
														|pl = 'Wiersz z takimi polami już istnieje. Połączyć wiersze?
														|Tak - połączyć wiersze
														|Nie - usunąć wiersz
														|Anuluj - kontynuuj edytowanie';
														|tr = 'Bu tür alanlara sahip bir satır halihazırda mevcut. Satırlar birleştirilsin mi?
														|Evet, satırları birleştir
														|Hayır, satırları sil
														|İptal et, düzenlemeye devam et'");
				ShowQueryBox(DecisionNotification, QueryText, QuestionDialogMode.YesNoCancel);
				
				DoubleQuestionDialogIsOpen = True;
				
			ElsIf CheckResult.Result = "ThereAreElementsUnavailableForInput" Then
				
				ColumnWithError 	= CheckResult.ColumnWithError;
				
				MessageTemplate 	= NStr("vi = 'Không thể chọn giá trị trong cột ""%1""';
											|ru = 'Значение не может быть выбрано в колонке ""%1""';
											|en = 'You cannot select a value in the ""%1"" column'; fa = 'You cannot select a value in the ""%1"" column';
											|it = 'Il valore non può essere selezionato nella colonna ""%1""';
											|pl = 'Nie można wybrać wartości w kolumnie ""%1""';
											|tr = 'Değer sütunda seçilemiyor ""%1""'");
				ElementByColumn	= Items[ColumnWithError]; // FormField, FormGroup, FormDecoration
				ColumnTitle 	= ElementByColumn.Title;
				MessageText 		= StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, ColumnTitle);
				LineToEdit = BudgetEditList.FindByID(Item.CurrentRow);
				RowIndex 		= BudgetEditList.IndexOf(LineToEdit);
				Field 				= CommonClientServer.PathToTabularSection("BudgetEditList", RowIndex + 1, ColumnWithError);
				
				CommonClient.MessageToUser(MessageText, Object.Ref, Field, "Object");
				
			ElsIf CheckResult.Result = "DifferentCurrency" Then
				
				MessageTemplate 	= NStr("vi = 'Theo dòng, tiền tệ đầu vào ""%1"" được xác định bởi các chỉ số. Không được phép nhập loại tiền khác';
											|ru = 'По строке валюта ввода ""%1"" определена аналитикой. Ввод в другой валюте не допускается';
											|en = 'By line the ""%1"" currency is determined by dimension. Another currency is not allowed'; fa = 'By line the ""%1"" currency is determined by dimension. Another currency is not allowed';
											|it = 'Per la riga la valuta di inserimento ""%1"" è predefinita da analitica. L''inserimento in una valuta diversa non è ammesso';
											|pl = 'W wierszu waluta ewidencji ""%1"" jest wyznaczona przez analitykę. Ewidencja w inej walucie nie jest dozwolona.';
											|tr = 'Para birimi satırına göre ""%1"" girişi boyut tarafından belirlendi. Diğer para birimleriyle girişe izin verilmeyecektir'");
				MessageText 		= StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, CheckResult.ValidCurrency);
				LineToEdit = BudgetEditList.FindByID(Item.CurrentRow);
				RowIndex 		= BudgetEditList.IndexOf(LineToEdit);
				Field 				= CommonClientServer.PathToTabularSection("BudgetEditList", RowIndex + 1, ColumnWithError);
				
				CommonClient.MessageToUser(MessageText, Object.Ref, Field, "Object");
				
			EndIf;
		
		EndIf;
	
	EndIf;
	
	Return CheckResult;
	
EndFunction

&AtClient
Procedure BudgetEditListBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	If DisconnectionTime = True Then
		DisconnectionTime = False;
		Return;
	EndIf;
	
	If DoubleQuestionDialogIsOpen = True Then
		Cancel = True;
		Return;
	EndIf;
	
	RowWillBeDeletedAutomatically = NewRow And CancelEdit;
	
	// So that there would be no conflicts of empty links, we will bring the unfilled values to undefined.
	ArrayOfEdits = StringFunctionsClientServer.SplitStringIntoSubstringsArray(EditedListColumns);
	For Each Dimension In ArrayOfEdits Do
		If Not ValueIsFilled(Item.CurrentData[Dimension]) Then
			Item.CurrentData[Dimension] = Undefined;
		EndIf;
	EndDo;
	
	// If there are duplicates, there is always an algorithm for combining rows
	// if you cannot edit the current row from the difference in currencies, we issue a warning
	// if the wrong element is selected, we issue a warning.
	CheckResult = PerformChecksBeforeFinishingEditing(Item, Cancel, RowWillBeDeletedAutomatically);
	
	// In case the cancellation from filling in a correctly filled line
	If CheckResult.Result <> "AfterEnteringValueThereWillBeDouble" Then
		
		If RowWillBeDeletedAutomatically Then
			
			DeleteRelatedBudgetLinesOnServer(Item.CurrentRow);
			
			// If the column values have been changed, we will clear the previous data
		ElsIf Not Cancel And Not NewRow Then
			
			ClearDataOfChangedColumns(Item.CurrentRow);
			
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure BudgetEditListOnEditEnd(Item, NewRow, CancelEdit)
	
	RowWillBeDeletedAutomatically = NewRow And CancelEdit;
	If Not RowWillBeDeletedAutomatically Then
		If Not ChangesToListAreReflectedInDocument = True Then
			ThereAreChangesInRelatedCells = False;
			ReflectChangesToData(Items.BudgetEditList.CurrentRow,, ThereAreChangesInRelatedCells);
			StartReflectingBudgetChanges(ThereAreChangesInRelatedCells);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_BudgetEditingListMainColumnForChanges(Item)
	CheckResult = Undefined;
	
	Modified = True;
	
	// Checking duplicates
	ColumnName = Items.BudgetEditList.CurrentItem.Name;
	
	If StrFind(EditedListColumns, ColumnName) Then
		
		CurrentData = Items.BudgetEditList.CurrentData;
		
		If StrFind(ColumnName, "Period") Then
			
			CurrentData = Items.BudgetEditList.CurrentData;
			
			PeriodicityByString = StrReplace(ColumnName, "Period", "");
			Periodicity = PredefinedValue("Enum.Periodicity." + PeriodicityByString);
			
			If CurrentData[ColumnName] < Object.BeginOfPeriod Then
				CurrentData[ColumnName] = Max(CurrentData[ColumnName], Object.BeginOfPeriod);
			ElsIf CurrentData[ColumnName] > Object.PeriodEnding Then
				CurrentData[ColumnName] = Min(CurrentData[ColumnName], Object.PeriodEnding);
			EndIf;
			
			CurrentData[ColumnName] = WorkingWithClientServerPeriods.BeginningDateOfPeriod(CurrentData[ColumnName], Periodicity);
			
		EndIf;
		
	Else
		
		CurrentRow = Items.BudgetEditList.CurrentRow;
		
		If ThereAreErrorsInBudgetEditLine(CurrentRow, CheckResult) Then
			
			If CheckResult.Result = "AfterEnteringValueThereWillBeDouble" Then
			
				AddlParameters = New Structure("ColumnName, Id", ColumnName, CurrentRow);
				DecisionNotification = New CallbackDescription("SelectingLineIncrease", ThisObject, AddlParameters);
				
				QueryText = NStr("vi = 'Đã có dòng với các trường như vậy. Hợp nhất các dòng?
										|Có - hợp nhất các dòng
										|Không - xóa dòng
										|Hủy bỏ - tiếp tục chỉnh sửa';
										|ru = 'Строка с такими полями уже существует. Объединить строки?
										|Да - объединить строки
										|Нет - удалить строку
										|Отмена - продолжить редактирование';
										|en = 'Line with such fields already exists. Merge lines? 
										|Yes - merge the lines
										|No - remove the line
										|Cancel - continue editing'; fa = 'Line with such fields already exists. Merge lines? 
										|Yes - merge the lines
										|No - remove the line
										|Cancel - continue editing';
										|it = 'La riga con questi campi esiste già. Unire le righe?
										|Si - unire le righe
										|No - eliminare la riga
										|Annullare - continuare la redazione';
										|pl = 'Wiersz z takimi polami już istnieje. Połączyć wiersze?
										|Tak - połączyć wiersze
										|Nie - usunąć wiersz
										|Anuluj - kontynuuj edytowanie';
										|tr = 'Bu tür alanlara sahip bir satır halihazırda mevcut. Satırlar birleştirilsin mi?
										|Evet, satırları birleştir
										|Hayır, satırları sil
										|İptal et, düzenlemeye devam et'");
				ShowQueryBox(DecisionNotification, QueryText, QuestionDialogMode.YesNoCancel);
				DoubleQuestionDialogIsOpen = True;
			
			EndIf;
			
			// we will report the error before the end of editing
			Return;
			
		EndIf;
		
		ThereAreChangesInRelatedCells = False;
		If Not Object.BudgetFlowItemTurnovers.Count() Then
			ChangesToListAreReflectedInDocument = True;
			ReflectChangesToData(Items.BudgetEditList.CurrentRow,,
				ThereAreChangesInRelatedCells);
		Else
			ReflectChangesToData(Items.BudgetEditList.CurrentRow,
				ColumnName,
				ThereAreChangesInRelatedCells);
		EndIf;
		StartReflectingBudgetChanges(ThereAreChangesInRelatedCells);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BudgetEditListOnActivateCell(Item)
	
	If Items.PanelBudget.CurrentPage <> Items.List Then
		Return;
	EndIf;
	
	CurrentData = Items.BudgetEditList.CurrentData;
	If CurrentData = Undefined Then
		NoteToTheValue = "";
		Items.EditingListGroupNote.CurrentPage = Items.NoteEntryIsUnavailable;
		Return;
	EndIf;
	
	CurListItem = Items.BudgetEditList.CurrentItem;
	ColumnName = CurListItem.Name;
	YouCanEnterANote = Not StrFind(EditedListColumns, ColumnName) And Not CurListItem.ReadOnly;
	
	If YouCanEnterANote Then
		NoteToTheValue = CurrentData[ColumnName + "Note"];
		Items.EditingListGroupNote.CurrentPage = Items.YouCanEnterANote;
	Else
		NoteToTheValue = "";
		Items.EditingListGroupNote.CurrentPage = Items.NoteEntryIsUnavailable;
	EndIf;
	
EndProcedure

&AtClient
Procedure BudgetEditListBeforeDeleteRow(Item, Cancel)
	
	DeleteRelatedBudgetLinesOnServer(Item.CurrentRow);
	
EndProcedure

&AtClient
Procedure MoveUp(Command)
	
	MoveToServer(-1);
	
EndProcedure

&AtClient
Procedure MoveDown(Command)
	
	MoveToServer(1);
	
EndProcedure

&AtClient
Procedure SortInAscendingOrder(Command)
	
	OrganizeOnServer(Items.BudgetEditList.CurrentItem.Name, "ASC");
	
EndProcedure

&AtClient
Procedure SortInDescendingOrder(Command)
	
	OrganizeOnServer(Items.BudgetEditList.CurrentItem.Name, "DESC");
	
EndProcedure

&AtClient
Procedure NoteToTheValueOnChange(Item)
	
	ColumnName = Items.BudgetEditList.CurrentItem.Name;
	CurrentData = Items.BudgetEditList.CurrentData;
	CurrentData[ColumnName + "Note"] = NoteToTheValue;
	ThereAreChangesInRelatedCells = False;
	ReflectChangesToData(Items.BudgetEditList.CurrentRow,
		ColumnName,
		ThereAreChangesInRelatedCells);
	StartReflectingBudgetChanges(ThereAreChangesInRelatedCells);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAdjustmentsByBudgetItems

&AtClient
Procedure AdjustmentsByBudgetItemsOnChange(Item)
	
	CalculateTotalAmountsOfAdjustment(ThisObject);
	SetVisibilityOfColumnsByAdjustments(ThisObject);
	
EndProcedure

&AtClient
Procedure AdjustmentsByBudgetItemsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)

	If Not ValueIsFilled(Object.BudgetProfile) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa chỉ ra dạng ngân sách.';
										|ru = 'Не указан вид бюджета.';
										|en = 'Budget profile is not specified.'; fa = 'Budget profile is not specified.';
										|it = 'Не указан вид бюджета.';
										|pl = 'Budget profile is not specified.';
										|tr = 'Bütçe profili belirtilmemiş.'"), , "BudgetProfile", "Object", Cancel);
	EndIf;

EndProcedure

&AtClient
Procedure AdjustmentsByBudgetItemsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		Item.CurrentData.Currency = ScenarioCurrency;
	EndIf;
	
	If ValueIsFilled(Item.CurrentData.BudgetFlowItem) Then
		ArticleDetails_1 = ItemParameterCache.Get(Item.CurrentData.BudgetFlowItem);
		MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
		For Counter = 1 To MaximumNumberOfAnalysts Do
			ChoiceParametersArray = New Array;
			If ValueIsFilled(Item.CurrentData["DimensionKind"+Counter]) Then
				TypeOfAnalyticsDescriptionOfTypes = ArticleDetails_1["DimensionKind"+Counter+"ValueType"];
				Items["AdjustmentsByBudgetItemsAnalytics"+Counter].TypeRestriction = TypeOfAnalyticsDescriptionOfTypes;
				If TypeOfAnalyticsDescriptionOfTypes.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
					ChoiceParametersArray.Add(New ChoiceParameter("Filter.Owner",
						ArticleDetails_1["DimensionKind" + Counter + "AdditionalProperty"]));
				EndIf;
			EndIf;
			Items["AdjustmentsByBudgetItemsAnalytics"
				+ Counter].ChoiceParameters = New FixedArray(ChoiceParametersArray);
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustmentsByBudgetItemsBudgetFlowItemOnChange(Item)
	
	CurrentRow = Items.AdjustmentsByBudgetItems.CurrentData;
	
	ProcessLineOfAdjustmentsForAnalyticsBudgetItems(CurrentRow);
	
	If Not CurrentRow.RecordByCurrency Then
		CurrentRow.AmountInCurrencyDecrease = 0;
		CurrentRow.AmountInCurrencyIncrease = 0;
	EndIf;
	If Not CurrentRow.RecordByQuantity Then
		CurrentRow.QuantityReduction = 0;
		CurrentRow.QuantityIncrease = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustmentsByBudgetItemsPlanningPeriodOnChange(Item)
	
	CurrentRow = Items.AdjustmentsByBudgetItems.CurrentData;
	If CurrentRow.PlanningPeriod < Object.BeginOfPeriod Then
		CurrentRow.PlanningPeriod = Object.BeginOfPeriod;
	ElsIf CurrentRow.PlanningPeriod > Object.PeriodEnding Then
		CurrentRow.PlanningPeriod = Object.PeriodEnding;
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustmentsByBudgetItemsAmountIncreaseOnChange(Item)
	
	CurrentRow = Items.AdjustmentsByBudgetItems.CurrentData;
	CurrentRow.AmountDecrease = 0;
	If CurrentRow.Currency <> ScenarioCurrency Then
		RecalculateAmountsInCurrencyByLineAtRatesOfScenario(Items.AdjustmentsByBudgetItems.CurrentRow);
	Else
		CurrentRow.AmountInCurrencyIncrease = CurrentRow.AmountIncrease;
		CurrentRow.AmountInCurrencyDecrease = CurrentRow.AmountDecrease;
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustmentsByBudgetItemsCurrencyOnChange(Item)
	
	RecalculateAmountsInCurrencyByLineAtRatesOfScenario(Items.AdjustmentsByBudgetItems.CurrentRow);
	
EndProcedure

&AtClient
Procedure AdjustmentsByBudgetItemsAmountDecreaseOnChange(Item)
	
	CurrentRow = Items.AdjustmentsByBudgetItems.CurrentData;
	CurrentRow.AmountIncrease = 0;
	If CurrentRow.Currency <> ScenarioCurrency Then
		RecalculateAmountsInCurrencyByLineAtRatesOfScenario(Items.AdjustmentsByBudgetItems.CurrentRow);
	Else
		CurrentRow.AmountInCurrencyIncrease = CurrentRow.AmountIncrease;
		CurrentRow.AmountInCurrencyDecrease = CurrentRow.AmountDecrease;
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustmentsByBudgetItemsAmountInCurrencyIncreaseOnChange(Item)
	
	CurrentRow = Items.AdjustmentsByBudgetItems.CurrentData;
	CurrentRow.AmountInCurrencyDecrease = 0;
	If CurrentRow.Currency <> ScenarioCurrency Then
		RecalculateAmountsPerLineByScriptCourses(Items.AdjustmentsByBudgetItems.CurrentRow);
	Else
		CurrentRow.AmountIncrease = CurrentRow.AmountInCurrencyIncrease;
		CurrentRow.AmountDecrease = CurrentRow.AmountInCurrencyDecrease;
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustmentsByBudgetItemsAmountInCurrencyDecreaseOnChange(Item)
	
	CurrentRow = Items.AdjustmentsByBudgetItems.CurrentData;
	CurrentRow.AmountInCurrencyIncrease = 0;
	If CurrentRow.Currency <> ScenarioCurrency Then
		RecalculateAmountsPerLineByScriptCourses(Items.AdjustmentsByBudgetItems.CurrentRow);
	Else
		CurrentRow.AmountIncrease = CurrentRow.AmountInCurrencyIncrease;
		CurrentRow.AmountDecrease = CurrentRow.AmountInCurrencyDecrease;
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustmentsByBudgetItemsQuantityIncreaseOnChange(Item)
	
	CurrentRow = Items.AdjustmentsByBudgetItems.CurrentData;
	CurrentRow.QuantityReduction = 0;
	
EndProcedure

&AtClient
Procedure AdjustmentsByBudgetItemsQuantityReductionOnChange(Item)
	
	CurrentRow = Items.AdjustmentsByBudgetItems.CurrentData;
	CurrentRow.QuantityIncrease = 0;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject,
		Item,
		DragParameters,
		StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	FilesOperationsClient.PreviewFieldDrag(ThisObject,
		Item,
		DragParameters,
		StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure UpdateYourBudgetInteractively(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.BudgetEntryForm.DocumentForm.Command.UpdateBudget",,
		True);
	
	ResetParameterCache();
	UpdateBudget();
	
EndProcedure

&AtClient
Procedure SetDateInterval()
	
	PeriodParameter_ = New StandardPeriod;
	PeriodParameter_.StartDate = Object.BeginOfPeriod;
	PeriodParameter_.EndDate = Object.PeriodEnding;
	
	Dialog = New StandardPeriodEditDialog;
	Dialog.Period = PeriodParameter_;
	Dialog.Show(New CallbackDescription("EditPeriodCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure EditAsAList(Command)
	GroupingID = Undefined;
	
	If Items.EditAsAList.Title = NStr("vi = 'Soạn trong danh sách';
										|ru = 'Редактировать в списке';
										|en = 'Edit in the list'; fa = 'ویرایش در فهرست';
										|it = 'Editare nell''elenco';
										|pl = 'Edytuj na liście';
										|tr = 'Listede düzenle'") Then
		
		Details = Budget.Area(Budget.CurrentArea.Top, 1).Details;
		If Details <> Undefined Then
			Details = BudgetReportingServerCall.DetailsValue(Details, DetailsDataAddress);
		EndIf;
		
		If TypeOf(Details) = Type("Structure") 
			And Details.Property("GroupingID", GroupingID) Then
			
			FoundRow = FinancialReportingClient.SubordinateElementOfFormElement(BudgetItemTree,
				"GroupingID", GroupingID);
			
		Else
			TreeRows = BudgetItemTree.GetItems();
			If TreeRows.Count() > 0 Then
				FoundRow	= TreeRows[0];
			EndIf;
		EndIf;
		
	Else
		
		CurrentRow = Items.BudgetItemTree.CurrentRow;
		If CurrentRow = Undefined Then
			CurrentRow = 0;
		EndIf;
		
		If CurrentRow <> Undefined Then
			StringOfBudgetItems = BudgetItemTree.FindByID(CurrentRow);
			If StringOfBudgetItems <> Undefined Then
				BudgetArea = BudgetAreaByLine(Budget, DetailsDataAddress, StringOfBudgetItems.GroupingID);
				If BudgetArea <> Undefined Then
					Items.Budget.CurrentArea = Budget.Area(BudgetArea, 1);
				EndIf;
			EndIf;
		EndIf;
		
		Items.PanelBudget.CurrentPage = Items.List;
		
	EndIf;
	
	SetPage();
	
	If Items.BudgetItemTree.Visible Then
		If FoundRow <> Undefined Then
			Parent = FoundRow.GetParent();
			If Parent <> Undefined And Not Items.BudgetItemTree.Expanded(Parent.GetID()) = True Then
				While Parent <> Undefined Do
					Items.BudgetItemTree.Expand(Parent.GetID());
					Parent = Parent.GetParent();
				EndDo;
			EndIf;
			Items.BudgetItemTree.CurrentRow = FoundRow.GetID();
			SetInputListParameters();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportToExcel(Command)
	TableID = Undefined;
	ColumnsByDimension = Undefined;
	
	#If WebClient Then
		WarningText = NStr("vi = 'Chức năng không được hỗ trợ trong web-client';
							|ru = 'Функциональность не поддерживается в веб-клиенте';
							|en = 'This functionality is not supported in Web client'; fa = 'This functionality is not supported in Web client';
							|it = 'La funzionalità non è supportata in web client';
							|pl = 'Ta funkcja nie jest obsługiwana w kliencie webowym';
							|tr = 'Fonksiyonellik web istemcisinde desteklenmiyor'");
		ShowMessageBox(,WarningText);
		Return;
	#EndIf
	#If MobileClient Then
		WarningText = NStr("vi = 'Chức năng không được hỗ trợ trong máy khách di động';
							|ru = 'Функциональность не поддерживается в мобильном клиенте';
							|en = 'This functionality is not supported in mobile client'; fa = 'This functionality is not supported in mobile client';
							|it = 'La funzionalità non è supportata nel client mobile';
							|pl = 'Ta funkcja nie jest obsługiwana w kliencie mobilnym';
							|tr = 'Fonksiyonellik mobil istemcide desteklenmiyor'");
		ShowMessageBox(,WarningText);
		Return;
	#EndIf
	
	If Object.Ref.IsEmpty() Then
		WarningText = NStr("vi = 'Trước khi kết xuất ra Excel, cần ghi lại chứng từ';
							|ru = 'Перед выгрузкой в эксель документ следует записать';
							|en = 'Save the document before export it to Excel'; fa = 'Save the document before export it to Excel';
							|it = 'Prima di scaricare in Excel bisogna salvare il documento';
							|pl = 'Przed wyeksportowaniem do Excelu dokument należy zapisać';
							|tr = 'Belge Excel''e yüklenmeden önce kaydedilmeli'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	If Not YouCanUnloadCurTable(Budget.CurrentArea.Top, TableID, ColumnsByDimension) Then
		WarningText = NStr("vi = 'Không thể tải bảng hiện tại vào một tệp có cấu trúc đồng nhất';
							|ru = 'Невозможно выгрузить текущую таблицу в однородный структурированный файл';
							|en = 'Cannot export the current table to homogeneous structured file'; fa = 'Cannot export the current table to homogeneous structured file';
							|it = 'Non è possibili caricare la tabella attuale nel file omogeneo strutturato';
							|pl = 'Nie można wyeksportować bieżącej tabeli do jednorodnego pliku strukturalnego';
							|tr = 'Mevcut tablo homojen yapılı belgeye yüklenemez'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription(
		"UploadToExcelExtensionEnabled",
		ThisObject,
		New Structure("TableID, ColumnsByDimension", TableID, ColumnsByDimension));
	
	FileSystemClient.Attach1CEnterpriseExtension(CallbackDescription);
	
EndProcedure

&AtClient
Procedure ImportFromExcel(Command)
	
	#If WebClient Then
		ShowMessageBox(,NStr("vi = 'Không hỗ trợ chức năng trong web-client';
							|ru = 'Функциональность не поддерживается в веб-клиенте';
							|en = 'This functionality is not supported in Web client'; fa = 'This functionality is not supported in Web client';
							|it = 'La funzionalità non è supportata in web client';
							|pl = 'Ta funkcja nie jest obsługiwana w kliencie webowym';
							|tr = 'Fonksiyonellik web istemcisinde desteklenmiyor'"));
		Return;
	#EndIf
	#If MobileClient Then
		WarningText = NStr("vi = 'Không hỗ trợ chức năng trong ứng dụng di động';
							|ru = 'Функциональность не поддерживается в мобильном клиенте';
							|en = 'This functionality is not supported in mobile client'; fa = 'This functionality is not supported in mobile client';
							|it = 'La funzionalità non è supportata nel client mobile';
							|pl = 'Ta funkcja nie jest obsługiwana w kliencie mobilnym';
							|tr = 'Fonksiyonellik mobil istemcide desteklenmiyor'");
		ShowMessageBox(, WarningText);
		Return;
	#EndIf
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription(
		"DownloadFromExcelExtensionEnabled",
		ThisObject);
	
	FileSystemClient.Attach1CEnterpriseExtension(CallbackDescription);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInAccordingToBudgetingData(Command)
	
	CheckPossibilityOfFillingInAccordingToBudgetingData();
	
EndProcedure

&AtClient
Procedure FillInAccordingToBudgetingDataCompletion(Result, AdditionalParameters) Export 
	
	BackgroundTaskBudgetPreparation = StartFillingInAccordingToBudgetingData();
	JobID = BackgroundTaskBudgetPreparation.JobID;
	StorageAddress = BackgroundTaskBudgetPreparation.ResultAddress;
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	AdditionalParameters.Insert("FillingInAccordingToInfobaseData", True);
	
	If FileInformationSecurity Then
		LoadPreparedData(, AdditionalParameters);
		JobID = Undefined;
	EndIf;
	
	RunReportExecutionCheck(AdditionalParameters);
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	Result - StandardPeriod -
// 	AdditionalParameters - Structure -
&AtClient
Procedure EditPeriodCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Object.BeginOfPeriod = Result.StartDate;
	Object.PeriodEnding = Result.EndDate;
	Object.BeginOfPeriod = ?(Object.BeginOfPeriod > Object.PeriodEnding, Object.PeriodEnding, Object.BeginOfPeriod);
	
	OnPeriodChangeServer();
	UpdateBudget();
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfBudgetingModel()
	
	NumberOfActiveModels
		= Catalogs.BudgetingModels.NumberOfExistingBudgetingModels();
		
	TMCommonUseClientServer.SetFormItemProperty(
		Items, 
		"BudgetingModel", 
		"Visible", 
		NumberOfActiveModels <> 1 Or Not ValueIsFilled(Object.BudgetingModel));
	
EndProcedure

&AtServer
Procedure CheckData_BeforeWrite(CurrentObject)
	
	If Not ValueIsFilled(CurrentObject.BudgetProfile) 
		Or Not ValueIsFilled(CurrentObject.Scenario) Then
			Return;
	EndIf;
	
	If Items.PanelBudget.CurrentPage = Items.List Then
		GenerateReportServer(True);
	EndIf;
	
	ObjectAndCalculationParameters = BudgetReportingClientServer.StructureByBudgetInstanceObject(ThisObject);
	DetailsData = GetFromTempStorage(DetailsDataAddress);
	
	BudgetingServer.CheckFixTSInstanceBudget(CurrentObject, ObjectAndCalculationParameters, Budget, DetailsData);
	
EndProcedure

&AtServer
Procedure ResetParameterCache()
	
	StructureBudgetViewOutputParameters = GetFromTempStorage(BudgetProfileDisplayParameters);
	If StructureBudgetViewOutputParameters <> Undefined Then
		StructureBudgetViewOutputParameters = BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView(
			Object.BudgetProfile, Enums.ModesOfBudgetReportGeneration.Document);
	EndIf;
	PutToTempStorage(StructureBudgetViewOutputParameters, BudgetProfileDisplayParameters);
	AddressOfExchangeRateTable = Undefined;
	
EndProcedure

&AtClient
Procedure Insert(Command)
	MessageText = Undefined;
	
	If Not InsertOnServer(MessageText) Then
		ShowMessageBox(,MessageText);
		Return;
	EndIf;
	
	If AutomaticUpdateOfTheBudget Then
		SetLabelForUpdatingTotals(True);
		RunChangeCalculationCheck();
	Else
		SetLabelForUpdatingTotals();
	EndIf;
	
EndProcedure

&AtClient
Procedure Copy(Command)
	CopyCellsOnServer();
	Notify("CopyingLinesToClipboard");
EndProcedure

&AtClient
Procedure Clear(Command)
	
	ClearCellsOnServer();
	
	If AutomaticUpdateOfTheBudget Then
		SetLabelForUpdatingTotals(True);
		RunChangeCalculationCheck();
	Else
		SetLabelForUpdatingTotals();
	EndIf;
	
EndProcedure

&AtClient
Procedure CopyByPeriods(Command)
	
	If Items.PanelBudget.CurrentPage = Items.List Then
		
		CurrentRow = Items.BudgetEditList.CurrentRow;
		If CurrentRow = Undefined Then
			Return;
		EndIf;
		
	EndIf;
	
	CopyCompleted = CopyByPeriodOnServer();
	
	If Not CopyCompleted Then
		ShowMessageBox(, NStr("vi = 'Khu vực hiện tại không có sẵn để sao chép!';
								|ru = 'Текущая область недоступна для копирования!';
								|en = 'Current area is not available for copying.'; fa = 'Current area is not available for copying.';
								|it = 'L''area attuale non può essere copiata!';
								|pl = 'Bieżący obszar nie jest dostępny do kopiowania!';
								|tr = 'Mevcut alan kopyalanamaz!'"));
	EndIf;
	
	If Items.PanelBudget.CurrentPage = Items.Table Then
		
		RunReportExecutionCheck();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

////////////////////////////////////////////////////////////////////////////////
// Handlers of indicator calculation commands.

&AtClient
Procedure SelectIndicatorClick(Item)

	Menu = MenuOfIndicatorTypes(Items.IndicatorsKindsCommands);
	ShowChooseFromMenu(New CallbackDescription("AfterSelectingTheIndicator", ThisObject), Menu, Item);

EndProcedure

&AtClient
Procedure CalculateAmount(Command)
	CalculateIndicators(Command.Name);
EndProcedure

&AtClient
Procedure CalculateCount(Command)
	CalculateIndicators(Command.Name);
EndProcedure

&AtClient
Procedure CalculateAverage(Command)
	CalculateIndicators(Command.Name);
EndProcedure

&AtClient
Procedure CalculateMin(Command)
	CalculateIndicators(Command.Name);
EndProcedure

&AtClient
Procedure CalculateMax(Command)
	CalculateIndicators(Command.Name);
EndProcedure

&AtClient
Procedure CalculateAllIndicators(Command)
	ExpandIndicatorsArea = Not Items.CalculateAllIndicators.Check;
	CommonInternalClient.SetIndicatorsPanelVisibiility(Items, ExpandIndicatorsArea);
EndProcedure

&AtClient
Procedure CollapseIndicators(Command)
	CommonInternalClient.SetIndicatorsPanelVisibiility(Items);
EndProcedure

&AtClient
Procedure SelectBudgetItems(Command)
	
	FormParameters = New Structure(BudgetingClientServer.NamesOfBudgetAttributes());
	FillPropertyValues(FormParameters, Object);
	FormParameters.Date = FormParameters.Date - 1;
	FormParameters.Insert("ArrayOfBudgetItems",
		TMCommonUseClientServer.ConvertMatchOrStructureToArray(ItemParameterCache));
	
	CallbackDescription = New CallbackDescription("AfterSelectingTurnoverByBudgetItems", ThisObject,
		New Structure("NumberOfLinesBeforeSelection", AdjustmentsByBudgetItems.Count()));
	OpenForm("Document.BudgetEntryForm.Form.FormForSelectingBudgetFlowItems", FormParameters, ThisObject,
		UUID, , , CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetDocumentHeaderFields()
	
	BudgetsByBusinessUnits = GetFormFunctionalOption("GenerateBudgetsByBusinessUnits");
	BudgetsByCompanies = GetFormFunctionalOption("GenerateBudgetsByCompanies");
	ThereIsBoundaryOfFact = Catalogs.BudgetProfiles.BudgetViewUsesActualDataBoundary(Object.BudgetProfile);
	
	StartFromRightColumn = (Number(BudgetsByCompanies Or BudgetsByBusinessUnits) + Number(ThereIsBoundaryOfFact)) % 2;
	LeftColumn = Not StartFromRightColumn;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	BudgetProfilesHeaderDimensions.LineNumber AS LineNumber,
		|	BudgetProfilesHeaderDimensions.DimensionKind,
		|	BudgetProfilesHeaderDimensions.DimensionKind.ValueType AS ValueType,
		|	BudgetProfilesHeaderDimensions.DimensionKind.Description AS Description,
		|	BudgetProfilesHeaderDimensions.DimensionKind.AdditionalProperty AS AdditionalProperty
		|FROM
		|	Catalog.BudgetProfiles.HeaderDimensions AS BudgetProfilesHeaderDimensions
		|WHERE
		|	BudgetProfilesHeaderDimensions.Ref = &BudgetProfile";
	
	Query.SetParameter("BudgetProfile", Object.BudgetProfile);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	MatchingDependentTypes = FinancialReportingCached.MatchingSelectionsByOwner();
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		Item = Items.Find("AnalyticsHeader_" + Cnt);
		If Item <> Undefined Then
			Items.Delete(Item);
		EndIf;
	EndDo;
	
	ArrayOfSuperiors = New Array;
	
	HeaderDimensionList.Clear();
	
	While Selection.Next() Do
		
		HeaderDimensionList.Add(Selection.DimensionKind);
		
		DimensionNumber = Selection.LineNumber;
		If LeftColumn Then
			NewItem = Items.Add("AnalyticsHeader_" + DimensionNumber, Type("FormField"), Items.HeaderLeftGroup);
		Else
			NewItem = Items.Add("AnalyticsHeader_" + DimensionNumber, Type("FormField"), Items.HeaderRightGroup);
		EndIf;
		NewItem.DataPath = "Object.Dimension" + DimensionNumber;
		NewItem.Title = Selection.Description;
		NewItem.Type = FormFieldType.InputField;
		NewItem.TypeRestriction = Selection.ValueType;
		NewItem.SetAction("OnChange", "Attachable_WhenChangingHeaderAnalytics");
		NewItem.HorizontalStretch = False;
		NewItem.Width = 28;
		NewItem.InputHint = BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(
			Selection.DimensionKind,
			"OtherItems");
		
		LeftColumn = Not LeftColumn;
		
		ArrayOfLinks = New Array();
		For Each UpstreamAnalytics In ArrayOfSuperiors Do
			
			For Each Type In Selection.ValueType.Types() Do
				
				OwnerParameters = MatchingDependentTypes[Type];
				If OwnerParameters = Undefined Then
					Continue;
				EndIf;
				
				ThereIsOwnerInUpstreamAnalysts = False;
				
				For Each OwnerParameter In OwnerParameters Do
					If UpstreamAnalytics.Types.Find(OwnerParameter.Type) <> Undefined Then
						ThereIsOwnerInUpstreamAnalysts = True;
						Break;
					EndIf;
				EndDo;
				
				If Not ThereIsOwnerInUpstreamAnalysts Then
					Continue;
				EndIf;
			
				NewLink = New ChoiceParameterLink("Filter." + OwnerParameter.Attribute, "Object.Dimension" + UpstreamAnalytics.DimensionNumber);
				ArrayOfLinks.Add(NewLink);
			
			EndDo;
		
		EndDo;
		
		NewLinks = New FixedArray(ArrayOfLinks);
		NewItem.ChoiceParameterLinks = NewLinks;
		
		If Selection.ValueType.Types().Find(Type("CatalogRef.ObjectsPropertiesValues")) <> Undefined Then
			
			ChoiceParameter = New ChoiceParameter("Filter.Owner", Selection.AdditionalProperty);
			Array = CommonClientServer.ValueInArray(ChoiceParameter);
			NewItem.ChoiceParameters = New FixedArray(Array);
			
		EndIf;
		
		ArrayOfSuperiors.Add(New Structure("DimensionNumber, Types", DimensionNumber, Selection.ValueType.Types()));
		
	EndDo;
	
EndProcedure

&AtClient
Procedure Attachable_WhenChangingHeaderAnalytics(Item)
	
	ResetParameterCache();
	UpdateBudget();
	
EndProcedure

&AtClient
Procedure SetFactBoundary(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		Object.ActualDataLimit = Result;
		SetFactBoundaryServer();
		UpdateBudget();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function BudgetingModelWorks(Model)
	
	Return Common.ObjectAttributeValue(Model, "Status") = 
						Enums.BudgetingModelStatuses.Valid;
	
EndFunction

&AtClient
Procedure ProcessLineOfAdjustmentsForAnalyticsBudgetItems(AdjustmentLine)
	
	ArticleDetails_1 = ItemParameterCache.Get(AdjustmentLine.BudgetFlowItem);
	If ArticleDetails_1 <> Undefined Then
		FillPropertyValues(AdjustmentLine, ArticleDetails_1);
	Else
		AdjustmentLine.RecordByCurrency = False;
		AdjustmentLine.RecordByQuantity = False;
	EndIf;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	NumberOfAnalysts = 0;
	For Counter = 1 To MaximumNumberOfAnalysts Do
		ChoiceParametersArray = New Array;
		If ArticleDetails_1 <> Undefined And ValueIsFilled(ArticleDetails_1["DimensionKind"+Counter]) Then
			TypeOfAnalyticsDescriptionOfTypes = ArticleDetails_1["DimensionKind"+Counter+"ValueType"];
			Items["AdjustmentsByBudgetItemsAnalytics"+Counter].TypeRestriction = TypeOfAnalyticsDescriptionOfTypes;
			AdjustmentLine["Dimension" + Counter] = TypeOfAnalyticsDescriptionOfTypes.AdjustValue(
				AdjustmentLine["Dimension"+ Counter]);
			If TypeOfAnalyticsDescriptionOfTypes.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
				ChoiceParametersArray.Add(New ChoiceParameter("Filter.Owner", ArticleDetails_1["DimensionKind"
					+ Counter + "AdditionalProperty"]));
			EndIf;
			NumberOfAnalysts = Counter;
		Else
			AdjustmentLine["DimensionKind"+Counter] = Undefined;
			AdjustmentLine["Dimension"+Counter] = Undefined;
		EndIf;
		Items["AdjustmentsByBudgetItemsAnalytics"
			+ Counter].ChoiceParameters = New FixedArray(ChoiceParametersArray);
		If ValueIsFilled(AdjustmentLine["DimensionKind" + Counter]) Then
			AdjustmentLine["PresentationOfOtherAnalytics"
				+ Counter] = BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(
				ArticleDetails_1["DimensionKind" + Counter], "OtherItems");
		Else
			AdjustmentLine["PresentationOfOtherAnalytics"+Counter] = "";
		EndIf;
	EndDo;
	AdjustmentLine.NumberOfAnalysts = NumberOfAnalysts;
	
EndProcedure

&AtClient
Procedure ActionOnChangeCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		CheckPossibilityOfFillingInAccordingToBudgetingData(AdditionalParameters);
	Else
		If AdjustmentsByBudgetItems.Count() > 0 Then
			Object.Action = PredefinedValue(
				"Enum.TypesOfBudgetEntryFormActions.AdjustByBudgetFlowItems");
		Else
			Object.Action = PredefinedValue(
				"Enum.TypesOfBudgetEntryFormActions.EnterBudgetEntryForm");
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterSelectingTurnoverByBudgetItems(Result, AdditionalParameters) Export
	
	If Not AdjustmentsByBudgetItems.Count() Then
		Return;
	EndIf;
	
	For Counter = AdditionalParameters.NumberOfLinesBeforeSelection To AdjustmentsByBudgetItems.Count()-1 Do
		ProcessLineOfAdjustmentsForAnalyticsBudgetItems(AdjustmentsByBudgetItems[Counter]);
	EndDo;
	
	CalculateTotalAmountsOfAdjustment(ThisObject);
	SetVisibilityOfColumnsByAdjustments(ThisObject);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	For Counter = 1 To MaximumNumberOfAnalysts Do
	
		//
	
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items["AdjustmentsByBudgetItemsAnalytics"+Counter].Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("AdjustmentsByBudgetItems.DimensionKind"+Counter);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
		ItemFilter.LeftValue = New DataCompositionField("AdjustmentsByBudgetItems.Dimension"+Counter);
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		Item.Appearance.SetParameterValue("Text",
			New DataCompositionField("AdjustmentsByBudgetItems.PresentationOfOtherAnalytics" + Counter));
	
		//
	
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items["AdjustmentsByBudgetItemsAnalytics"+Counter].Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("AdjustmentsByBudgetItems.DimensionKind"+Counter);
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		Item.Appearance.SetParameterValue("ReadOnly", True);
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
														|ru = '<не используется>';
														|en = '<not used>'; fa = '<استفاده نمی‌شود>';
														|it = '<не используется>';
														|pl = '<nie używa się>';
														|tr = '<kullanılmıyor>'"));
		Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	EndDo;

	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentsByBudgetItemsCurrency.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentsByBudgetItemsAmountInCurrencyIncrease.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentsByBudgetItemsAmountInCurrencyDecrease.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentsByBudgetItems.RecordByCurrency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentsByBudgetItemsQuantityIncrease.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AdjustmentsByBudgetItemsQuantityReduction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdjustmentsByBudgetItems.RecordByQuantity");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

// StandardSubsystems.Properties
&AtServerNoContext
Function AbilityToReadAttachedFile(AttachedFile)
	
	FileAttributes = Common.ObjectAttributesValues(AttachedFile, "ServiceFileType, Extension");
	
	Result = New Structure("ReadingIsPossible, ErrorText", True, "");
	If ValueIsFilled(FileAttributes.ServiceFileType) Then
		Result.ReadingIsPossible = False;
		Result.ErrorText    = NStr("vi = 'Các tập tin là một tập tin dịch vụ, cấm chọn.';
									|ru = 'Файл является служебным, выбор запрещен.';
									|en = 'File is service, selection is prohibited.'; fa = 'File is service, selection is prohibited.';
									|it = 'Il file è di servizio, la selezione è vietata.';
									|pl = 'To jest plik serwisowy, wybór jest zabroniony.';
									|tr = 'Bu dosya bir hizmet dosyasıdır, seçilmesine izin verilmemektedir.'");
	ElsIf Lower(FileAttributes.Extension) <> "xls"
		And Lower(FileAttributes.Extension) <> "xlsx"
		And Lower(FileAttributes.Extension) <> "ods" Then
		Result.ReadingIsPossible = False;
		Result.ErrorText    = NStr("vi = 'Tệp không phải là tệp Excel hoặc Open Office (ods), cấm chọn.';
									|ru = 'Файл не является файлом формата Excel или Open Office (ods), выбор запрещен.';
									|en = 'The file is not an Excel or Open Office (ods) format file, selection prohibited.'; fa = 'The file is not an Excel or Open Office (ods) format file, selection prohibited.';
									|it = 'Il file non è un file Excel o Open Office (ods), la selezione non è consentita.';
									|pl = 'Plik nie jest plikiem formatu Excel lub Open Office (ods), wybór jest zabroniony.';
									|tr = 'Bu dosya Excel veya Open Office (ods) formatında değildir, seçilmesine izin verilmemektedir.'");
	EndIf;
	
	Return Result;
	
EndFunction
// End StandardSubsystems.Properties

#Region FillingBudget

&AtServer
Function PrepareReportParameters(FillType = False, Details = Undefined)
	
	GenerationMode = ?(FillType,
							Enums.ModesOfBudgetReportGeneration.FillType,
							Enums.ModesOfBudgetReportGeneration.Document);
	
	DataParameters = Documents.BudgetEntryForm.ParametersForDisplayingBudgetViewInTableDocument(Object,
				HeaderDimensionList,
				ScenarioCurrency,
				GetFromTempStorage(BudgetProfileDisplayParameters),
				GenerationMode,
				GetFromTempStorage(AddressOfCellData));
	
	If ValueIsFilled(Details) Then
		
		DataParameters.Insert("Details", Details);
		
	EndIf;
	
	DataParameters.Insert("ItemParameterCache", New Map);
	
	Return DataParameters;
	
EndFunction

&AtClient
Procedure UpdateBudget(RecalculateRelated = False)
	
	DurationOfTheLastCalculation = 0;
	GenerateReportServer(Items.PanelBudget.CurrentPage = Items.List);
	If Items.PanelBudget.CurrentPage <> Items.List Then
		RunReportExecutionCheck();
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckPossibilityOfFillingInAccordingToBudgetingData(AdditionalParameters = Undefined)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.BudgetFlowItemTurnovers;
	CheckParameters.CheckedAttributes.Insert("BudgetingModel", NStr("vi = 'Mô hình lập ngân sách';
																	|ru = 'Модель бюджетирования';
																	|en = 'Budgeting model'; fa = 'مدل بودجه‌بندی';
																	|it = 'Модель бюджетирования';
																	|pl = 'Model budżetowania';
																	|tr = 'Bütçeleme modeli'"));
	CheckParameters.CheckedAttributes.Insert("BeginOfPeriod", NStr("vi = 'Đầu kỳ';
																	|ru = 'Начало периода';
																	|en = 'Period start'; fa = 'شروع دوره';
																	|it = 'Начало периода';
																	|pl = 'Początek okresu';
																	|tr = 'Dönem başı'"));
	CheckParameters.CheckedAttributes.Insert("PeriodEnding", NStr("vi = 'Kết thúc kỳ';
																	|ru = 'Окончание периода';
																	|en = 'Period end'; fa = 'پایان دوره';
																	|it = 'Окончание периода';
																	|pl = 'Koniec okresu';
																	|tr = 'Dönem sonu'"));
	CheckParameters.CheckedAttributes.Insert("Scenario", NStr("vi = 'Kịch bản';
																|ru = 'Сценарий';
																|en = 'Scenario'; fa = 'سناریو';
																|it = 'Сценарий';
																|pl = 'Scenariusz';
																|tr = 'Senaryo'"));
	CheckParameters.CheckedAttributes.Insert("BudgetProfile", NStr("vi = 'Dạng ngân sách';
																	|ru = 'Вид бюджета';
																	|en = 'Budget profile'; fa = 'پروفایل بودجه';
																	|it = 'Вид бюджета';
																	|pl = 'Rodzaj budżetu';
																	|tr = 'Bütçe profili'"));
	If GetFormFunctionalOption("GenerateBudgetsByCompanies") Then
		CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																		|ru = 'Организация';
																		|en = 'Company'; fa = 'Company';
																		|it = 'Организация';
																		|pl = 'Organizacja';
																		|tr = 'İş yeri'"));
	EndIf;
	If GetFormFunctionalOption("GenerateBudgetsByBusinessUnits") Then
		CheckParameters.CheckedAttributes.Insert("Department", NStr("vi = 'Bộ phận';
																	|ru = 'Подразделение';
																	|en = 'Business unit'; fa = 'Business unit';
																	|it = 'Подразделение';
																	|pl = 'Dział';
																	|tr = 'Departman'"));
	EndIf;
	Notification = New CallbackDescription("FillInAccordingToBudgetingDataCompletion", ThisObject, AdditionalParameters);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisObject, Notification, CheckParameters);
	
EndProcedure

&AtServer
Function StartFillingInAccordingToBudgetingData()
	
	TimeConsumingOperations.CancelJobExecution(JobID);
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.RunNotInBackground1 = FileInformationSecurity;
	ExecutionParameters.RunInBackground = Not ExecutionParameters.RunNotInBackground1;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Điền ngân sách theo dữ liệu CSTT';
														|ru = 'Заполнение бюджета по данным ИБ';
														|en = 'Fill in budget by infobase data'; fa = 'Fill in budget by infobase data';
														|it = 'Fill in budget by infobase data';
														|pl = 'Fill in budget by infobase data';
														|tr = 'Infobase verilerine göre bütçenin doldurulması'");
	
	ReportParameters = PrepareReportParameters(True);
	ReportParameters.Insert("PeriodEnding", ReportParameters.EndOfPeriod);
	
	Return TimeConsumingOperations.ExecuteFunction(ExecutionParameters,
		"Documents.BudgetEntryForm.BudgetInstanceDataWithTabularParts", ReportParameters);
	
EndFunction

&AtServer
Procedure ReflectBudgetChanges(Mode = "", BaseLines = Undefined, Details = Undefined,
	UpdatedCellData = False)
	
	If Items.Budget.StatePresentation.Visible Then
		// the budget has not been formed
		Return;
	EndIf;
	
	If ValueIsFilled(JobID) Then
		Return;
	EndIf;
	
	UpdateCellData_ = Mode = "UpdateCellData_";
	Recalculate = Mode = "Recalculate";
	
	ThereAreChangesForRecording = False;
	ReportParameters = PrepareReportParameters(,Details);
	
	If BaseLines <> Undefined Then
		ReportParameters.Insert("BaseLines", BaseLines);
	EndIf;
	
	If Not UpdateCellData_ Then
		ReportParameters.Insert("OnlyCalculated", True);
	EndIf;
	
	If Not ItemParameterCache = Undefined Then
		ReportParameters.Insert("ItemParameterCache", ItemParameterCache);
	EndIf;
	
	If Not IsBlankString(CellDataSortingString) Then
		ReportParameters.Insert("CellDataSortingString", CellDataSortingString);
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunNotInBackground1 = FileInformationSecurity Or UpdateCellData_ Or Recalculate;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Chuẩn bị ngân sách';
														|ru = 'Подготовка бюджета';
														|en = 'Budgeting'; fa = 'بودجه‌بندی';
														|it = 'Elaborazione del bilancio.';
														|pl = 'Przygotowanie budżetu';
														|tr = 'Bütçe hazırlığı'");

	ExecutionResult = TimeConsumingOperations.ExecuteInBackground(
		"BudgetReportingDisplayServer.PlaceBudgetInstanceChangesInStorage",
		ReportParameters,
		ExecutionParameters);
		
	BackgroundTaskBudgetPreparation = ExecutionResult;
		
	JobID = ExecutionResult.JobID;
	StorageAddress = ExecutionResult.ResultAddress;
		
	If ExecutionResult.Status = "Completed2" Then
		BudgetInstanceChanges = GetFromTempStorage(StorageAddress);
		UploadResultOfCalculatingChanges(Mode, BudgetInstanceChanges);
		UpdatedCellData = True;
	Else
		ExecutingTheChangeCalculationJob = True;
	EndIf;

EndProcedure

&AtServer
Procedure GenerateReportServer(Directly = False, RecalculateRelated = False, ConsiderAdditionalSelectionByHierarchy = False)
	
	If Not YouCanUpdateYourBudget() Then
		Return;
	EndIf;
	
	TimeConsumingOperations.CancelJobExecution(JobID);
	
	ReportParameters = PrepareReportParameters();
	ReportParameters.ConsiderAdditionalSelectionByHierarchy = ConsiderAdditionalSelectionByHierarchy;
	
	JobID = Undefined;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunNotInBackground1 = Directly Or FileInformationSecurity;
	ExecutionParameters.RunInBackground = Not ExecutionParameters.RunNotInBackground1;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Chuẩn bị ngân sách';
														|ru = 'Подготовка бюджета';
														|en = 'Budgeting'; fa = 'بودجه‌بندی';
														|it = 'Elaborazione del bilancio.';
														|pl = 'Przygotowanie budżetu';
														|tr = 'Bütçe hazırlığı'");

	ExecutionResult = TimeConsumingOperations.ExecuteInBackground(
		"BudgetReportingDisplayServer.PlaceBudgetInstanceDataInStorage",
		ReportParameters,
		ExecutionParameters);
		
	JobID = ExecutionResult.JobID;
	StorageAddress = ExecutionResult.ResultAddress;
	
	BackgroundTaskBudgetPreparation = ExecutionResult;

	If ExecutionParameters.RunNotInBackground1 Then
		
		BudgetInstanceData = GetFromTempStorage(StorageAddress);
		
		LoadPreparedData(BudgetInstanceData);
		If Items.PanelBudget.CurrentPage = Items.List Then
			SetInputListParametersOnServer(False);
		ElsIf BudgetInstanceData.Property("CellTotalsNeedToBeRecalculated")
			And Not RecalculateRelated Then
			GenerateReportServer(True, True);
		EndIf;
		JobID = Undefined;
	Else
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Budget, "ReportGeneration");
		Items.Budget.ReadOnly = True;
	EndIf;
	
	ExecutingTheChangeCalculationJob = False;
	
EndProcedure

&AtServer
Function YouCanUpdateYourBudget(CheckingWithWarnings = True)
	Cancel = False;
	MessageText = Undefined;
	
	BlankFields = New Array;
	If Not ValueIsFilled(Object.BudgetProfile) Then
		BlankFields.Add(NStr("vi = 'Dạng ngân sách';
							|ru = 'Вид бюджета';
							|en = 'Budget profile'; fa = 'پروفایل بودجه';
							|it = 'Tipologia di bilancio';
							|pl = 'Rodzaj budżetu';
							|tr = 'Bütçe profili'"));
	EndIf;
	
	If Not ValueIsFilled(Object.Scenario) Then
		BlankFields.Add(NStr("vi = 'Kịch bản';
							|ru = 'Сценарий';
							|en = 'Scenario'; fa = 'سناریو';
							|it = 'Scenario';
							|pl = 'Scenariusz';
							|tr = 'Senaryo'"));
	EndIf;
	
	If Not ValueIsFilled(Object.BeginOfPeriod) Or Not ValueIsFilled(Object.PeriodEnding) Then
		BlankFields.Add(NStr("vi = 'Kỳ';
							|ru = 'Период';
							|en = 'Period'; fa = 'دوره';
							|it = 'Periodo';
							|pl = 'Okres';
							|tr = 'Dönem'"));
	EndIf;
	
	If Not ValueIsFilled(Object.Organization) Then
		FOParameters = New Structure("BudgetingModel", Object.BudgetingModel);
		GenerateBudgetsByCompanies = GetFunctionalOption("GenerateBudgetsByCompanies", FOParameters);
		If GenerateBudgetsByCompanies Then
			BlankFields.Add(NStr("vi = 'Doanh nghiệp';
								|ru = 'Организация';
								|en = 'Company'; fa = 'Company';
								|it = 'Azienda';
								|pl = 'Organizacja';
								|tr = 'İş yeri'"));
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Object.Department) Then
		FOParameters = New Structure("BudgetingModel", Object.BudgetingModel);
		GenerateBudgetsByBusinessUnits = GetFunctionalOption("GenerateBudgetsByBusinessUnits", FOParameters);
		If GenerateBudgetsByBusinessUnits Then
			BlankFields.Add(NStr("vi = 'Bộ phận';
								|ru = 'Подразделение';
								|en = 'Business unit'; fa = 'Business unit';
								|it = 'Reparto';
								|pl = 'Dział';
								|tr = 'Departman'"));
		EndIf;
	EndIf;
	
	StatePresentation = Items.Budget.StatePresentation;
	
	If BlankFields.Count() > 0 Then
		If CheckingWithWarnings Then
			Budget.Clear();
			
			StateMessageTemplate = ?(BlankFields.Count() = 1,
				NStr("vi = 'Điền trường %1';
					|ru = 'Заполните поле %1';
					|en = 'Fill in field %1'; fa = 'Fill in field %1';
					|it = 'Compilate il campo %1';
					|pl = 'Wypełnij pole %1';
					|tr = 'Alanı doldur %1'"), NStr("vi = 'Điền trường: %1';
														|ru = 'Заполните поля: %1';
														|en = 'Fill in fields: %1'; fa = 'Fill in fields: %1';
														|it = 'Compilate i campi: %1';
														|pl = 'Wypełnij pole: %1';
														|tr = 'Alanı doldur: %1'"));
			
			StatePresentation.Visible = True;
			StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
			StatePresentation.Picture  = New Picture;
			StatePresentation.Text     = StringFunctionsClientServer.SubstituteParametersToString(
				StateMessageTemplate,
				StrConcat(BlankFields, ", "));
		EndIf;
		
		Return False;
		
	Else
		
		CheckFillInCourseTable(Cancel, MessageText);
		
		If Cancel = True Then
			
			If CheckingWithWarnings Then
				Budget.Clear();
				
				StatePresentation.Visible  = True;
				StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
				StatePresentation.Picture   = New Picture;
				StatePresentation.Text  = MessageText;
			EndIf; 
			
			Return False;
			
		EndIf;
		
	EndIf;
	
	StatePresentation.Visible = False;
	
	Return True;
	
EndFunction

#EndRegion

#Region ElementEventHandlersServer

&AtServer
Procedure WhenScriptChangesServer()
	
	SetScriptParameters();
	ResetParameterCache();
	
	SetAvailabilityOfItemsAfterCheckingFill();
EndProcedure

&AtServer
Procedure WhenBudgetingModelChangesServer()
	
	OptionsParameters = New Structure("BudgetingModel", Object.BudgetingModel);
	SetFormFunctionalOptionParameters(OptionsParameters);
	UseBudgetConfirmation = GetFormFunctionalOption("UseBudgetConfirmation");
	
	BudgetViewModel = Common.ObjectAttributeValue(Object.BudgetProfile, "Owner");
	If BudgetViewModel <> Object.BudgetingModel Then
		Object.BudgetProfile = Undefined;
	EndIf;
	
	Dimensions = Documents.BudgetEntryForm.DefaultBudgetMeasurements(Object.BudgetingModel, Object.EmployeeResponsible);
	For Each Dimension In Dimensions Do
		If Not ValueIsFilled(Object[Dimension.Key]) Then
			Object[Dimension.Key] = Dimension.Value;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure WhenChangingBudgetTypeServer()
	
	Object.BudgetFlowItemTurnovers.Clear();
	Object.BudgetFlowItemsDimension.Clear();
	AdjustmentsByBudgetItems.Clear();
	ParametersStructure = PrepareParametersForBudgetViewOutput();
	ItemParameterCache = BudgetingServer.FillCacheOfArticleParameters(ParametersStructure);
	
	Catalogs.BudgetProfiles.AlignDatesByBudgetFrequency(Object.BudgetProfile, Object.BeginOfPeriod, Object.PeriodEnding);
	Object.ActualDataLimit = Catalogs.BudgetProfiles.BorderOfActualDataByBudgetType(Object.BudgetProfile, Object.BeginOfPeriod);
	Catalogs.BudgetProfiles.ConfigureGroupOfPeriodElements(Object.BudgetProfile, Items, Object.ActualDataLimit);
	SetDocumentHeaderFields();
	
	If ValueIsFilled(Object.Ref) Then
		BudgetingServer.DeleteSavedBudgetTemplates(Object.Ref);
	EndIf;
	
	WhenChangingBudgetEditingMethod();
	
	SetAvailabilityOfItemsAfterCheckingFill();
	SetParametersForSelectingBudgetItemToAdjustTurnover();
	
EndProcedure

&AtServer
Procedure OnPeriodChangeServer()
	
	ArrayToDelete = New Array;
	For Each RowOfRevolutions In Object.BudgetFlowItemTurnovers Do
		If RowOfRevolutions.PlanningPeriod < Object.BeginOfPeriod
			Or RowOfRevolutions.PlanningPeriod > Object.PeriodEnding Then
			ArrayToDelete.Add(RowOfRevolutions);
		EndIf;
	EndDo;
	For Each ArrayRow In ArrayToDelete Do
		Object.BudgetFlowItemTurnovers.Delete(ArrayRow);
	EndDo;
	IDs = Object.BudgetFlowItemTurnovers.Unload(,"RowID");
	IDs.GroupBy("RowID");
	IDs.Indexes.Add("RowID");
	ArrayToDelete = New Array;
	For Each AnalyticsLine_ In Object.BudgetFlowItemsDimension Do
		If IDs.Find(AnalyticsLine_.RowID) = Undefined Then
			ArrayToDelete.Add(AnalyticsLine_);
		EndIf;
	EndDo;
	For Each ArrayRow In ArrayToDelete Do
		Object.BudgetFlowItemsDimension.Delete(ArrayRow);
	EndDo;
	ArrayToDelete = New Array;
	For Each AnalyticsLine_ In Object.DimensionValues_ Do
		If IDs.Find(AnalyticsLine_.RowID) = Undefined Then
			ArrayToDelete.Add(AnalyticsLine_);
		EndIf;
	EndDo;
	For Each ArrayRow In ArrayToDelete Do
		Object.DimensionValues_.Delete(ArrayRow);
	EndDo;
	ArrayToDelete = New Array;
	For Each AdjustmentLine In AdjustmentsByBudgetItems Do
		If AdjustmentLine.PlanningPeriod < Object.BeginOfPeriod
			Or AdjustmentLine.PlanningPeriod > Object.PeriodEnding Then
			ArrayToDelete.Add(AdjustmentLine);
		EndIf;
	EndDo;
	For Each ArrayRow In ArrayToDelete Do
		AdjustmentsByBudgetItems.Delete(ArrayRow);
	EndDo;
	
	ModelIsValid = Catalogs.BudgetingModels.BudgetingModelWorks(Object.BudgetingModel);
		
	If Not ModelIsValid Then
		Object.BudgetingModel = Catalogs.BudgetingModels.DefaultBudgetingModel();
		WhenBudgetingModelChangesServer();
	EndIf;
	
	SetAvailabilityOfBudgetingModel();
	
	Catalogs.BudgetProfiles.AlignDatesByBudgetFrequency(Object.BudgetProfile, Object.BeginOfPeriod, Object.PeriodEnding);
	Object.ActualDataLimit = Catalogs.BudgetProfiles.BorderOfActualDataByBudgetType(Object.BudgetProfile, Object.BeginOfPeriod);
	Catalogs.BudgetProfiles.ConfigureGroupOfPeriodElements(Object.BudgetProfile, Items, Object.ActualDataLimit);
	
	ResetParameterCache();
	
	SetAvailabilityOfItemsAfterCheckingFill();
EndProcedure

&AtServer
Function ViewAndProcessSelectionOnServer(ValueSelected, UseToEnterPlan)
	
	UseToEnterPlan = ValueSelected.UseToEnterPlan;
	
	If Not UseToEnterPlan Then
		Return False;
	EndIf;
	
	If Not Catalogs.BudgetProfiles.BudgetViewIsFilledInCorrectly(ValueSelected) Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	ResetParameterCache();
	
	SetAvailabilityOfItemsAfterCheckingFill();
EndProcedure

&AtServer
Procedure DivisionWhenChangedOnServer()
	
	ResetParameterCache();
	
	SetAvailabilityOfItemsAfterCheckingFill();
EndProcedure

&AtServer
Procedure MoveToServer(Direction)
	
	ObjectAndCalculationParameters = BudgetReportingClientServer.StructureByBudgetInstanceObject(ThisObject);
	
	IDOfCurLine = Items.BudgetEditList.CurrentRow;
	CurrentRow = BudgetEditList.FindByID(IDOfCurLine);
	IndexOf = BudgetEditList.IndexOf(CurrentRow);
	
	If IndexOf + Direction < 0 Or 
		IndexOf + Direction >= BudgetEditList.Count() Then
		Return;
	EndIf;
	
	EditParameters = GetFromTempStorage(AddressOfLineEditingParameters);
	OffsetString = BudgetEditList[IndexOf + Direction];
	
	For Each KeyAndValue In EditParameters.StructureAnalogDecryption Do
		
		If KeyAndValue.Value.Property("Calculated") Then
			Continue;
		EndIf;
		
		Details = DecryptionOfReportByLine(KeyAndValue.Value, CurrentRow, EditParameters.VariableMeasurements);
		CurDataLine = BudgetReportingClientServer.FindTurnoverStringByDecryption(ObjectAndCalculationParameters, Details);
		Details = DecryptionOfReportByLine(KeyAndValue.Value, OffsetString, EditParameters.VariableMeasurements);
		PreviousDataLine = BudgetReportingClientServer.FindTurnoverStringByDecryption(ObjectAndCalculationParameters, Details);
		
		TMPs = CurDataLine.SerialNumber;
		CurDataLine.SerialNumber = PreviousDataLine.SerialNumber;
		PreviousDataLine.SerialNumber = TMPs;
	
	EndDo;
	
	BudgetEditList.Move(IndexOf, Direction);
	
	ReflectBudgetChanges("UpdateCellData_", EditParameters.ColumnsByDimension.BaseLines);
	
EndProcedure

&AtServer
Procedure OrganizeOnServer(TagName, Order)
	
	ObjectAndCalculationParameters = BudgetReportingClientServer.StructureByBudgetInstanceObject(ThisObject);
	
	EditParameters = GetFromTempStorage(AddressOfLineEditingParameters);
	For Each ListLine In BudgetEditList Do
		For Each KeyAndValue In EditParameters.StructureAnalogDecryption Do
		
			If KeyAndValue.Value.Property("Calculated") Then
				Continue;
			EndIf;
			
			Details = DecryptionOfReportByLine(KeyAndValue.Value, ListLine, EditParameters.VariableMeasurements);
			DataString1 = BudgetReportingClientServer.FindTurnoverStringByDecryption(ObjectAndCalculationParameters, Details);
			DataString1.SerialNumber = 0;
			
		EndDo;
	EndDo;
	
	SerialNumber = BudgetReportingClientServer.MaximumNumberInOrder(Object);
	
	BudgetEditList.Sort(TagName + " " + Order);
	
	For Each ListLine In BudgetEditList Do
		SerialNumber = SerialNumber + 1;
		For Each KeyAndValue In EditParameters.StructureAnalogDecryption Do
		
			If KeyAndValue.Value.Property("Calculated") Then
				Continue;
			EndIf;
			
			Details = DecryptionOfReportByLine(KeyAndValue.Value, ListLine, EditParameters.VariableMeasurements);
			DataString1 = BudgetReportingClientServer.FindTurnoverStringByDecryption(ObjectAndCalculationParameters, Details);
			DataString1.SerialNumber = SerialNumber;
			
		EndDo;
	EndDo;
	
	ReflectBudgetChanges("UpdateCellData_", EditParameters.ColumnsByDimension.BaseLines);
	
EndProcedure

&AtServer
Procedure CopyByPeriodByDecryption(Details, Value, ExcludingPeriods = Undefined)
	
	StructureOfOutputParameters = GetFromTempStorage(BudgetProfileDisplayParameters);
	
	Periodicity_ = StructureOfOutputParameters.ColumnStructureOfDataTable.Periodicity_;
	
	MinimumPeriodicity = BudgetReportingClientServer.MinimumPeriodicity(Periodicity_);
	WorkingTranscript = Common.CopyRecursive(Details);
	
	BeginOfPeriod = Undefined;
	Details.Property(FinancialReportingClientServer.PeriodStrings(MinimumPeriodicity).Period, BeginOfPeriod);
	If BeginOfPeriod = Undefined Then
		Return;
	EndIf;
	ArrayOfPeriods = BudgetReportingDisplayServer.BudgetReportPeriods(
		BeginOfPeriod,
		Object.PeriodEnding,
		MinimumPeriodicity);
	
	For Each Period In ArrayOfPeriods Do
		
		ColumnName = FinancialReportingClientServer.PeriodStrings(MinimumPeriodicity).Period;
		If Period = Details[ColumnName]
		 Or (Not ExcludingPeriods = Undefined And Not ExcludingPeriods.Find(Period) = Undefined) Then
			Continue;
		EndIf;
		
		For Each Periodicity In Periodicity_ Do
			WorkingTranscript.Insert(FinancialReportingClientServer.PeriodStrings(Periodicity).Period,
				WorkingWithClientServerPeriods.BeginningDateOfPeriod(Period, Periodicity));
		EndDo;
		ReflectionResult = ReflectCellChange(WorkingTranscript, Value);
		
		DecryptionOfRelated = Common.CopyRecursive(WorkingTranscript);
		DecryptionOfRelated.Delete("DataLineIndex");
		DecryptionOfRelated.Delete("Value");
		For Each KeyAndValue In DecryptionOfRelated.AnalystValues Do
			DecryptionOfRelated.Insert(FinancialReportingCached.NameOfBudgetReportField(KeyAndValue.Key), KeyAndValue.Value);
		EndDo;
		DecryptionOfRelated.Delete("AnalystValues");
		DecryptionOfRelated.Delete("AbbreviatedDigits");
		
		ReportParameters = BudgetReportingClientServer.PeriodParameters_(Object);
		BudgetInstanceChanges = BudgetReportingDisplayServer.CalculateRelatedBudgetItems(
			StructureOfOutputParameters,
			AddressOfCellData,
			ReportParameters,
			DecryptionOfRelated,
			ReflectionResult);
		UploadResultOfCalculatingChanges(, BudgetInstanceChanges);
		
	EndDo;
	
EndProcedure

&AtServer
Function CopyByPeriodOnServer()
	
	CopyCompleted = False;
	
	Modified = True;
	
	BudgetViewParameters = GetFromTempStorage(BudgetProfileDisplayParameters);
	
	Periodicity_ = BudgetViewParameters.ColumnStructureOfDataTable.Periodicity_;
	MinimumPeriodicity = BudgetReportingClientServer.MinimumPeriodicity(Periodicity_);
	
	If Items.PanelBudget.CurrentPage = Items.Table Then
		
		ActiveArea = Items.Budget.CurrentArea;
		
		ExcludingPeriods = New Array();
		For String = ActiveArea.Top To ActiveArea.Bottom Do
			For Column = ActiveArea.Left To ActiveArea.Right Do
				ValueArea = Budget.Area(String, Column);
				If ValueArea.ContainsValue Then
					
					Details = BudgetReportingServerCall.DetailsValue(ValueArea.Details, DetailsDataAddress);
					Period = Undefined;
					Details.Property(FinancialReportingClientServer.PeriodStrings(
						MinimumPeriodicity).Period, Period);
					If ExcludingPeriods.Find(Period) = Undefined Then
						ExcludingPeriods.Add(Period);
					EndIf;
				EndIf;
			EndDo;
		EndDo;
		
		For String = ActiveArea.Top To ActiveArea.Bottom Do
			For Column = ActiveArea.Left To ActiveArea.Right Do
				ValueArea = Budget.Area(String, Column);
				If ValueArea.ContainsValue Then
					
					Details = BudgetReportingServerCall.DetailsValue(ValueArea.Details, DetailsDataAddress);
					
					Value = ValueArea.Value;
					AbbreviatedDigits = 0;
					If Details.Property("AbbreviatedDigits", AbbreviatedDigits) Then
						Value = Value * Pow(10, AbbreviatedDigits);
					EndIf;
					CopyByPeriodByDecryption(Details, Value, ExcludingPeriods);
					
					CopyCompleted = True;
					
				EndIf;
			EndDo;
		EndDo;
		
		GenerateReportServer();
		
	Else
		
		ColumnName = Items.BudgetEditList.CurrentItem.Name;
		EditParameters = GetFromTempStorage(AddressOfLineEditingParameters);
		LineToEdit = BudgetEditList.FindByID(Items.BudgetEditList.CurrentRow);
		
		If Not EditParameters.StructureAnalogDecryption.Property(ColumnName) Then
			Return CopyCompleted;
		EndIf;
		
		ColumnValues = EditParameters.StructureAnalogDecryption[ColumnName];
		Details = DecryptionOfReportByLine(ColumnValues, LineToEdit, EditParameters.VariableMeasurements);
		Details.Insert("String", EditParameters.ColumnsByDimension.BaseLines);
		
		CopyByPeriodByDecryption(Details, LineToEdit[ColumnName]);
		
		ReflectBudgetChanges("UpdateCellData_", EditParameters.ColumnsByDimension.BaseLines);
		LoadListData(EditParameters.ColumnsByDimension,
				EditParameters.FixedValues,
				EditParameters.StructureAnalogDecryption);
		
		CopyCompleted = True;
		
	EndIf;
	
	Return CopyCompleted;
	
EndFunction

&AtServer
Function InsertOnServer(WarningText)
	
	Clipboard = Common.RowsFromClipboard();
	
	If Clipboard.Source <> "BudgetCells" Or Not ValueIsFilled(Clipboard.Data) Then
		WarningText = NStr("vi = 'Không có dữ liệu để chèn';
							|ru = 'Нет данных для вставки';
							|en = 'No data to insert'; fa = 'No data to insert';
							|it = 'Non ci sono dati da inserire';
							|pl = 'Brak danych do wstawienia';
							|tr = 'Ekleme için veri yok'");
		Return False; //nothing to insert
	ElsIf Clipboard.Data.Count() = 1 Then
		If Clipboard.Data[0].Count() = 1 Then
			UnitValue = True;
			Value = Clipboard.Data[0][0];
		Else
			WarningText = NStr("vi = 'Trong dữ liệu để chèn một giá trị không phải là số';
								|ru = 'В данных для вставки нечисловое значение';
								|en = 'Paste data contains a non-numeric value'; fa = 'Paste data contains a non-numeric value';
								|it = 'Nei dati per l''aliquota vi è un valore non numerico';
								|pl = 'W danych do wklejenia jest wartość nieliczbowa';
								|tr = 'Sayı olmayan bir değer eklemek için verilerde olan'");
			Return False; //inserting only numbers is supported
		EndIf;
	Else
		UnitValue = False;
		Value = Clipboard.Data;
	EndIf;
	
	ObjectAndCalculationParameters = BudgetReportingClientServer.StructureByBudgetInstanceObject(ThisObject);
	
	CalculationParameters = BudgetReportingClientServer.ObjectStructureForCellCalculation();
	CalculationParameters.ScenarioCurrency 							= ScenarioCurrency;
	CalculationParameters.ItemParameterCache 						= ItemParameterCache;
	CalculationParameters.RequireExchangeRatesSpecificationForEachPeriod	= RequireExchangeRatesSpecificationForEachPeriod;
	CalculationParameters.AddressOfExchangeRateTable 						= AddressOfExchangeRateTable;
	CalculationParameters.BudgetProfileDisplayParameters					= BudgetProfileDisplayParameters;
	CalculationParameters.Insert("ReportParameters", 				BudgetReportingClientServer.PeriodParameters_(Object));
	CalculationParameters.Insert("BudgetProfileDisplayParameters",		BudgetProfileDisplayParameters);
	CalculationParameters.Insert("AddressOfCellData", 				AddressOfCellData);
	CalculationParameters.Insert("StorageAddress", 				StorageAddress);
		
	ActiveArea = Items.Budget.CurrentArea;
	If UnitValue Then
		For String = ActiveArea.Top To ActiveArea.Bottom Do
			For Column = ActiveArea.Left To ActiveArea.Right Do
				ValueArea = Budget.Area(String, Column);
				If ValueArea.ContainsValue Then
					ValueArea.Value = Value;
					Details = BudgetReportingServerCall.DetailsValue(ValueArea.Details, DetailsDataAddress);
					ReflectionResult = BudgetReportingClientServer.ReflectCellChange(ObjectAndCalculationParameters, Details, ValueArea.Value);
					
					CalculationParameters.Insert("AreaName", 					ValueArea.Name);
					CalculationParameters.Insert("ReflectionResult", 			ReflectionResult);
					CalculationParameters.Insert("Details", 					Details);
					If AutomaticUpdateOfTheBudget Then
						BudgetWhenChangingServerAutoRecalculation(CalculationParameters);
					Else
						ResultingStructure = BudgetWhenServerChanges(CalculationParameters);
						If ResultingStructure <> Undefined Then
							ObjectAndCalculationParameters = BudgetReportingClientServer.StructureByBudgetInstanceObject(ThisObject);
							LoadResultOfCalculatingChangesOnClient(ObjectAndCalculationParameters, Budget, ResultingStructure);
						EndIf;
					EndIf;

				EndIf;
			EndDo;
		EndDo;
	Else
		LeftCorner = ActiveArea.Left;
		UpperCorner = ActiveArea.Top;
		For String = 0 To Value.UBound() Do
			For Column = 0 To Value[0].UBound() Do
				ValueArea = Budget.Area(UpperCorner + String, LeftCorner + Column);
				If ValueArea.ContainsValue Then
					ValueArea.Value = Value[String][Column];
					Details = BudgetReportingServerCall.DetailsValue(ValueArea.Details, DetailsDataAddress);
					ReflectionResult = BudgetReportingClientServer.ReflectCellChange(ObjectAndCalculationParameters, Details, ValueArea.Value);
					
					CalculationParameters.Insert("AreaName", 					ValueArea.Name);
					CalculationParameters.Insert("ReflectionResult", 			ReflectionResult);
					CalculationParameters.Insert("Details", 					Details);
					If AutomaticUpdateOfTheBudget Then
						BudgetWhenChangingServerAutoRecalculation(CalculationParameters);
					Else							
						ResultingStructure = BudgetWhenServerChanges(CalculationParameters);
						If ResultingStructure <> Undefined Then
							ObjectAndCalculationParameters = BudgetReportingClientServer.StructureByBudgetInstanceObject(ThisObject);
							LoadResultOfCalculatingChangesOnClient(ObjectAndCalculationParameters, Budget, ResultingStructure);
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
		
	Return True;
	
EndFunction

&AtServer
Procedure CopyCellsOnServer()
	
	ActiveArea = Items.Budget.CurrentArea;
	RowsArray = New Array;
	For String = ActiveArea.Top To ActiveArea.Bottom Do
		ColumnsArray1 = New Array;
		For Column = ActiveArea.Left To ActiveArea.Right Do
			ValueArea = Budget.Area(String, Column);
			Value = Undefined;
			If ValueArea.ContainsValue Then
				Value = ValueArea.Value;
			Else
				If Not IsBlankString(ValueArea.Text) Then
					Try
						Value = Number(ValueArea.Text);
					Except
						// The platform's capabilities are used in terms of converting a string to a number.
						// It is impractical to analyze a string for the possibility of converting to a number in the code
						// It is also impractical to register any entries in the registration log.
						Value = Undefined;
					EndTry;
				EndIf;
			EndIf;
			ColumnsArray1.Add(Value);
		EndDo;
		RowsArray.Add(ColumnsArray1);
	EndDo;
	
	Common.CopyToClipboard(RowsArray, "BudgetCells");
	
EndProcedure

&AtServer
Procedure ClearCellsOnServer()
	
	ActiveArea = Items.Budget.CurrentArea;
	For String = ActiveArea.Top To ActiveArea.Bottom Do
		For Column = ActiveArea.Left To ActiveArea.Right Do
			ValueArea = Budget.Area(String, Column);
			If ValueArea.ContainsValue Then
				ValueArea.Value = Undefined;
				Details = BudgetReportingServerCall.DetailsValue(ValueArea.Details, DetailsDataAddress);
				ReflectionResult = ReflectCellChange(Details, ValueArea.Value);
				ReportParameters = BudgetReportingClientServer.PeriodParameters_(Object);
				BudgetInstanceChanges = BudgetReportingDisplayServer.CalculateRelatedBudgetItems(
						BudgetProfileDisplayParameters,
						AddressOfCellData, 
						ReportParameters,
						ValueArea.Name,
						ReflectionResult);
				UploadResultOfCalculatingChanges(, BudgetInstanceChanges);
			EndIf;
		EndDo;
	EndDo;
	
	ReflectBudgetChanges();
	
EndProcedure

&AtServer
Procedure SetFactBoundaryServer()
	
	Catalogs.BudgetProfiles.ConfigureGroupOfPeriodElements(Object.BudgetProfile, Items, Object.ActualDataLimit);
	ResetParameterCache();
	
EndProcedure

&AtServer
Procedure RecalculateAtServer()
	
	BaseLines = Undefined;
	If Items.PanelBudget.CurrentPage = Items.List Then
		EditParameters = GetFromTempStorage(AddressOfLineEditingParameters);
		If EditParameters = Undefined Then
			Return;
		EndIf;
		BaseLines = EditParameters.ColumnsByDimension.BaseLines;
		If Not AutomaticUpdateOfTheBudget Then
			ReflectBudgetChanges("UpdateCellData_");
		EndIf;
	EndIf;
	
	ReportParameters = PrepareReportParameters();
	CellData_ = GetFromTempStorage(AddressOfCellData);
	If CellData_ <> Undefined Then
		BudgetInstanceChanges = BudgetReportingDisplayServer.CalculateRelatedBudgetItems(
				BudgetProfileDisplayParameters,
				CellData_, 
				ReportParameters,
				Undefined,
				Undefined,
				True);
		UploadResultOfCalculatingChanges(, BudgetInstanceChanges);
		ReportParameters = PrepareReportParameters();
	EndIf;
	
	If Items.PanelBudget.CurrentPage = Items.Table Then
		ReflectBudgetChanges("Recalculate", BaseLines);
	Else
		ReflectBudgetChanges("UpdateCellData_", BaseLines);
		LoadListData(EditParameters.ColumnsByDimension,
				EditParameters.FixedValues,
				EditParameters.StructureAnalogDecryption,
				True);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("Insert");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		Not Common.EmptyClipboard("BudgetCells"));
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("Copy");
	ItemArray.Add("Insert");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

&AtServer
Procedure WhenChangingActionServer(FillInBudget = True)

	If Object.Action = Enums.TypesOfBudgetEntryFormActions.AdjustByBudgetFlowItems Then
		FillInTableOfAdjustmentsByBudgetItems();
		CalculateTotalAmountsOfAdjustment(ThisObject);
		SetVisibilityOfColumnsByAdjustments(ThisObject);
	Else
		AdjustmentsByBudgetItems.Clear();
	EndIf;
	
	WhenChangingBudgetEditingMethod(FillInBudget);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateTotalAmountsOfAdjustment(Form)
	
	Form.TotalAmountOfIncrease = Form.AdjustmentsByBudgetItems.Total("AmountIncrease");
	Form.TotalAmountOfReduction = Form.AdjustmentsByBudgetItems.Total("AmountDecrease");
	Form.TotalAmountOfAdjustment = Form.TotalAmountOfIncrease - Form.TotalAmountOfReduction;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityOfColumnsByAdjustments(Form)
	
	RecordByCurrency = Form.AdjustmentsByBudgetItems.FindRows(New Structure("RecordByCurrency",
		True)).Count() > 0;
	RecordByQuantity = Form.AdjustmentsByBudgetItems.FindRows(New Structure("RecordByQuantity",
		True)).Count() > 0;
	
	Form.Items.AdjustmentsByBudgetItemsCurrency.Visible = RecordByCurrency;
	Form.Items.AdjustmentsByBudgetItemsAmountInCurrency.Visible = RecordByCurrency;
	Form.Items.AdjustmentsByBudgetItemsNumber.Visible = RecordByQuantity;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	NumberOfAnalyticsIsUsed = False;
	For Counter = 0 To MaximumNumberOfAnalysts-1 Do
		NumberOfAnalysts = MaximumNumberOfAnalysts - Counter;
		If Not NumberOfAnalyticsIsUsed Then
			NumberOfAnalyticsIsUsed = Form.AdjustmentsByBudgetItems.FindRows(
				New Structure("NumberOfAnalysts", NumberOfAnalysts)).Count() > 0;
		EndIf;
		Form.Items["AdjustmentsByBudgetItemsAnalytics"
			+ NumberOfAnalysts].Visible = NumberOfAnalyticsIsUsed;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingBudgetItemToAdjustTurnover()
	
	ArrayOfArticles = TMCommonUseClientServer.ConvertMatchOrStructureToArray(ItemParameterCache);
	
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.Ref", New FixedArray(ArrayOfArticles)));
	Items.AdjustmentsByBudgetItemsBudgetFlowItem.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	TypesOfArticlesAndIndicators = New Array;
	For Each ArrayElement In ArrayOfArticles Do
		If TypesOfArticlesAndIndicators.Find(TypeOf(ArrayElement)) = Undefined Then
			TypesOfArticlesAndIndicators.Add(TypeOf(ArrayElement));
		EndIf;
	EndDo;
	
	Items.AdjustmentsByBudgetItemsBudgetFlowItem.TypeRestriction = New TypeDescription(TypesOfArticlesAndIndicators);
	
EndProcedure

&AtServer
Procedure FillInTableOfAdjustmentsByBudgetItems()
	
	TheStructureOfTheSearch = New Structure;
	
	For Each StringRevolutions In Object.BudgetFlowItemTurnovers Do
		
		TheStructureOfTheSearch.Insert("RowID", StringRevolutions.RowID);
		AnalyticsLine = Object.BudgetFlowItemsDimension.FindRows(TheStructureOfTheSearch);
		If AnalyticsLine.Count() = 0 Then
			Continue;
		EndIf;
		
		NewRow = AdjustmentsByBudgetItems.Add();
		FillPropertyValues(NewRow, StringRevolutions);
		FillPropertyValues(NewRow, AnalyticsLine[0]);
		If StringRevolutions.Sum < 0 Then
			NewRow.AmountDecrease = -StringRevolutions.Sum;
			NewRow.AmountInCurrencyDecrease = -StringRevolutions.AmountInCurrency;
			NewRow.QuantityReduction = -StringRevolutions.Count;
		Else
			NewRow.AmountIncrease = StringRevolutions.Sum;
			NewRow.AmountInCurrencyIncrease = StringRevolutions.AmountInCurrency;
			NewRow.QuantityIncrease = StringRevolutions.Count;
		EndIf;
		
		If Not ValueIsFilled(NewRow.BudgetFlowItem) Then
			Continue;
		EndIf;
		
		ArticleDetails_1 = ItemParameterCache.Get(NewRow.BudgetFlowItem);
		FillPropertyValues(NewRow, ArticleDetails_1);
		
		MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
		NumberOfAnalysts = 0;
		For Counter = 1 To MaximumNumberOfAnalysts Do
			If ValueIsFilled(NewRow["DimensionKind"+Counter]) Then
				NewRow["PresentationOfOtherAnalytics"
					+ Counter] = BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(
					ArticleDetails_1["DimensionKind" + Counter], "OtherItems");
				NumberOfAnalysts = Counter;
			Else
				NewRow["PresentationOfOtherAnalytics"+Counter] = "";
			EndIf;
		EndDo;
		NewRow.NumberOfAnalysts = NumberOfAnalysts;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure WriteDownTableOfAdjustmentsByBudgetItems(DocumentObject)
	
	DocumentObject.BudgetFlowItemTurnovers.Clear();
	DocumentObject.BudgetFlowItemsDimension.Clear();
	
	TableOfAdjustmentsByBudgetItems = AdjustmentsByBudgetItems.Unload();
	ObjectAndCalculationParameters = New Structure("Object, ScenarioCurrency", DocumentObject, ScenarioCurrency);
	SearchData_ = New Structure("BudgetFlowItem, Currency");
	
	SerialNumber = 1;
	For Each TableRow In TableOfAdjustmentsByBudgetItems Do
		For Counter = 1 To TableRow.NumberOfAnalysts Do
			If Not ValueIsFilled(TableRow["Dimension"+Counter]) Then
				TableRow["Dimension"+Counter] = BudgetingClientServer.EmptyDimensionValue();
			EndIf;
			SearchData_.Insert("Dimension"+Counter);
		EndDo;
		If Not ValueIsFilled(TableRow.Currency) Then
			TableRow.Currency = ScenarioCurrency;
			TableRow.AmountInCurrencyIncrease = TableRow.AmountIncrease;
			TableRow.AmountInCurrencyDecrease = TableRow.AmountDecrease;
		EndIf;
		FillPropertyValues(SearchData_, TableRow);
		RowID = BudgetReportingClientServer.IDOfBudgetItemAnalytics(
			ObjectAndCalculationParameters, SearchData_);
		StringRevolutions = DocumentObject.BudgetFlowItemTurnovers.Add();
		FillPropertyValues(StringRevolutions, TableRow);
		StringRevolutions.RowID = RowID;
		If ValueIsFilled(TableRow.AmountIncrease) Then
			StringRevolutions.Sum = TableRow.AmountIncrease;
		Else
			StringRevolutions.Sum = -TableRow.AmountDecrease;
		EndIf;
		If ValueIsFilled(TableRow.AmountInCurrencyIncrease) Then
			StringRevolutions.AmountInCurrency = TableRow.AmountInCurrencyIncrease;
		Else
			StringRevolutions.AmountInCurrency = -TableRow.AmountInCurrencyDecrease;
		EndIf;
		If ValueIsFilled(TableRow.QuantityIncrease) Then
			StringRevolutions.Count = TableRow.QuantityIncrease;
		Else
			StringRevolutions.Count = -TableRow.QuantityReduction;
		EndIf;
		StringRevolutions.SerialNumber = SerialNumber;
		SerialNumber = SerialNumber + 1;
	EndDo;
	
EndProcedure

&AtServer
Procedure RecalculateAmountsPerLineByScriptCourses(CurrentRow)
	
	AdjustmentLine = AdjustmentsByBudgetItems.FindByID(CurrentRow);
	
	ObjectAndCalculationParameters = BudgetReportingClientServer.StructureByBudgetInstanceObject(ThisObject);
	AdjustmentLine.AmountIncrease = BudgetReportingServerCall.RecalculateAccordingToCourseTable(
		ObjectAndCalculationParameters, AdjustmentLine.AmountInCurrencyIncrease, AdjustmentLine.PlanningPeriod,
		AdjustmentLine.Currency, ScenarioCurrency);
	AdjustmentLine.AmountDecrease = BudgetReportingServerCall.RecalculateAccordingToCourseTable(
		ObjectAndCalculationParameters, AdjustmentLine.AmountInCurrencyDecrease, AdjustmentLine.PlanningPeriod,
		AdjustmentLine.Currency, ScenarioCurrency);
	
EndProcedure

&AtServer
Procedure RecalculateAmountsInCurrencyByLineAtRatesOfScenario(CurrentRow)
	
	AdjustmentLine = AdjustmentsByBudgetItems.FindByID(CurrentRow);
	
	ObjectAndCalculationParameters = BudgetReportingClientServer.StructureByBudgetInstanceObject(ThisObject);
	AdjustmentLine.AmountInCurrencyIncrease = BudgetReportingServerCall.RecalculateAccordingToCourseTable(
		ObjectAndCalculationParameters, AdjustmentLine.AmountInCurrencyIncrease, AdjustmentLine.PlanningPeriod,
		ScenarioCurrency, AdjustmentLine.Currency);
	AdjustmentLine.AmountInCurrencyDecrease = BudgetReportingServerCall.RecalculateAccordingToCourseTable(
		ObjectAndCalculationParameters, AdjustmentLine.AmountInCurrencyDecrease, AdjustmentLine.PlanningPeriod,
		ScenarioCurrency, AdjustmentLine.Currency);
	
EndProcedure

#EndRegion

#Region UnloadingToExcel

&AtServer
Function YouCanUnloadCurTable(TopOfCurArea, TableID, ColumnsByDimension)
	CurrentRow = Undefined;
	GroupingID = Undefined;
	
	If Items.PanelBudget.CurrentPage = Items.Table Then
		
		Details = Budget.Area(TopOfCurArea, 1).Details;
		Details = BudgetReportingServerCall.DetailsValue(Details, DetailsDataAddress);
		If TypeOf(Details) = Type("Structure") 
			And Details.Property("GroupingID", GroupingID) Then
			
			CurrentRow = FinancialReportingServer.SubordinateItem(BudgetItemTree,
				"GroupingID", GroupingID);
			
		Else
			
			TreeRows = BudgetItemTree.GetItems();
			If Not TreeRows.Count() Then
				Return False;
			EndIf;
			
			CurrentRow = TreeRows[0];
			
		EndIf;
		
	ElsIf Items.PanelBudget.CurrentPage = Items.List Then
		
		IndexOfCurRow = Items.BudgetItemTree.CurrentRow;
		If IndexOfCurRow = Undefined Then
			Return False;
		EndIf;
		
		CurrentRow = BudgetItemTree.FindByID(IndexOfCurRow);
		
	EndIf;
	
	If CurrentRow = Undefined Then
		
		Return False;
		
	EndIf;
	
	While CurrentRow.GetParent() <> Undefined Do
		
		CurrentRow = CurrentRow.GetParent();
		
	EndDo;
	
	BudgetInstanceParameters = GetFromTempStorage(BudgetProfileDisplayParameters);
	ParametersList = BudgetInstanceParameters.InputListDescriptionStructure;
	
	ColumnsByDimension = Undefined;
	If Not Documents.BudgetEntryForm.CompositionOfRootElementColumns(CurrentRow, ParametersList, ColumnsByDimension) Then
		Return False;
	EndIf;
	
	TableID = CurrentRow.TableID;
	
	Return True;
	
EndFunction

&AtServer
Function CreateAttachedXLS97File(TableID, ColumnsByDimension)
	TreeDepth = Undefined;
	
	DataCompositionSchema = Documents.BudgetEntryForm.GetDCSForPrintingDocumentWithoutDimensions(TableID, ColumnsByDimension, 
		TreeDepth, GetFromTempStorage(BudgetProfileDisplayParameters));
	
	// output of the layout result to the report
	
	Settings = DataCompositionSchema.DefaultSettings;
	DetailsData = New DataCompositionDetailsData;
	TemplateComposer = New DataCompositionTemplateComposer;
	
	CompositionTemplate = TemplateComposer.Execute(
		DataCompositionSchema, Settings, DetailsData);
	
	CellParameters = GetFromTempStorage(BudgetProfileDisplayParameters).StructureOfReportDescription.CellParameters;
	ExternalData = New Structure("CellData_, CellParameters", GetFromTempStorage(AddressOfCellData), CellParameters);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(
		CompositionTemplate, ExternalData, DetailsData);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	// We output the result in a tabular document
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(SpreadsheetDocument);
	
	OutputProcessor.Output(DataCompositionProcessor);
	
	TempFileName = GetTempFileName();
	SpreadsheetDocument.Write(TempFileName, SpreadsheetDocumentFileType.XLS97);
	
	FileAddressInTempStorage = PutToTempStorage(New BinaryData(TempFileName), UUID);
	
	PresentationOfCurDateForFileName = Format(CurrentSessionDate(),
		StrTemplate(NStr("vi = 'ДФ=''%1 %2''';
						|ru = 'ДФ=''%1 %2''';
						|en = 'DF=''%1 %2'''; fa = 'DF=''%1 %2''';
						|it = 'DF=''%1 %2''';
						|pl = 'DF=''%1 %2''';
						|tr = 'DF=''%1 %2'''"), "dd.MM.yyyy", "HH.mm.ex"));
		
	FileName = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Ngân sách %1';
			|ru = 'Бюджет от %1';
			|en = 'Budget from %1'; fa = 'Budget from %1';
			|it = 'Budget del %1';
			|pl = 'Budżet z dnia%1';
			|tr = '%1 itibarıyla bütçe'"),
		PresentationOfCurDateForFileName);
	
	ReplaceForbiddenCharacters(FileName);
	
	FileParameters = New Structure();
	FileParameters.Insert("Author", Users.AuthorizedUser());
	FileParameters.Insert("FilesOwner", Object.Ref);
	FileParameters.Insert("BaseName", FileName);
	FileParameters.Insert("ExtensionWithoutPoint", "xls");
	FileParameters.Insert("ModificationTimeUniversal", Undefined);
	
	File = FilesOperations.AppendFile(FileParameters, FileAddressInTempStorage, Undefined);
	
	DeleteFiles(TempFileName);
	
	Return File;
	
EndFunction

&AtClientAtServerNoContext
Procedure ReplaceForbiddenCharacters(FileName)
	ForbiddenCharacters = New Array;
	ForbiddenCharacters.Add("/");
	ForbiddenCharacters.Add("\");
	ForbiddenCharacters.Add("[");
	ForbiddenCharacters.Add("]");
	ForbiddenCharacters.Add(":");
	ForbiddenCharacters.Add(";");
	ForbiddenCharacters.Add("|");
	ForbiddenCharacters.Add("=");
	ForbiddenCharacters.Add("?");
	ForbiddenCharacters.Add("*");
	ForbiddenCharacters.Add("<");
	ForbiddenCharacters.Add(">");
	
	For Each ForbiddenCharacter In ForbiddenCharacters Do
		FileName = StrReplace(FileName, ForbiddenCharacter, "_");
	EndDo;
	
EndProcedure

&AtClient
Procedure UploadToExcelExtensionEnabled(Result, AdditionalParameters) Export
	
	File = CreateAttachedXLS97File(AdditionalParameters.TableID, AdditionalParameters.ColumnsByDimension);
	
	FilesOperationsClient.OpenFileForm(File);
	
EndProcedure

#EndRegion

#Region LoadingFromExcel

&AtServerNoContext
Function GetFileData(AttachedFile, UUID)
	
	Return FilesOperations.FileData(AttachedFile, UUID, True);
	
EndFunction

&AtClient
Function DownloadFromExcelOnClient(AttachedFile)
	TableID = Undefined;
	ColumnsByDimension = Undefined;
	
	If Not YouCanUnloadCurTable(Budget.CurrentArea.Top, TableID, ColumnsByDimension) Then
		WarningText = NStr("vi = 'Không thể tải vào bảng hiện tại vì cấu trúc của nó không đồng nhất!';
							|ru = 'Невозможно загрузить в текущую таблицу, т.к. ее структура не однородна!';
							|en = 'Cannot import to the current table as its structure is not homogeneous.'; fa = 'Cannot import to the current table as its structure is not homogeneous.';
							|it = 'Non è possibile scaricare nella tabella attuale, perché la sua struttura non è omogenea!';
							|pl = 'Nie można załadować do bieżącej tabeli, ponieważ jej struktura nie jest jednolita!';
							|tr = 'Mevcut tablo, yapısı homojen olmadığı için indirilemez!'");
		ShowMessageBox(, WarningText);
		Return False;
	EndIf;
	
	Status(NStr("vi = 'Đọc dữ liệu từ tập tin của họ. Xin vui lòng chờ ...';
				|ru = 'Выполняется чтение данных их файла. Пожалуйста подождите...';
				|en = 'Reading data from the file. Please wait...'; fa = 'Reading data from the file. Please wait...';
				|it = 'In corso la lettura dei dati del file. Attendere prego...';
				|pl = 'Trwa wczytywanie danych z pliku. Proszę czekać ...';
				|tr = 'Verilerin dosyadan okunması işlemi gerçekleştiriliyor. Lütfen bekleyiniz...'") , , , PictureLib.Information32);
	
	FileData = GetFileData(AttachedFile, UUID);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TableID", TableID);
	AdditionalParameters.Insert("ColumnsByDimension", ColumnsByDimension);
	AdditionalParameters.Insert("FileExtention", FileData.Extension);
	
	If Not FileData.CurrentUserEditsFile Then
		
		Notification = New CallbackDescription(
			"LoadFromExcelOnClient",
			ThisObject,
			AdditionalParameters);
		
		FilesOperationsClient.GetAttachedFile(
			Notification,
			AttachedFile,
			UUID,
			New Structure("FileData, ForEditing", FileData, False));
		
	Else
		
		// No need to get the file to disk so as not to erase unsaved changes
		UserWorkingDirectory = FilesOperationsInternalClient.UserWorkingDirectory();
		TempFileName = UserWorkingDirectory + FileData.RelativePath + FileData.FileName;
		
		LoadFromExcelOnClient(
			New Structure("ErrorDescription, FullFileName", "", TempFileName),
			AdditionalParameters);
		
	EndIf;
	
EndFunction

&AtClient
Procedure LoadFromExcelOnClient(Result, AdditionalParameters) Export
	
	If Not IsBlankString(Result.ErrorDescription) Then
		Raise Result.ErrorDescription;
	EndIf;
	
	TableID = AdditionalParameters.TableID;
	ColumnsByDimension = AdditionalParameters.ColumnsByDimension;
	
	FormParameters = New Structure();
	
	BinaryData = New BinaryData(Result.FullFileName);
	AddressOfVH = PutToTempStorage(BinaryData, UUID);
	FileExtention = AdditionalParameters.FileExtention;
	If Not ValueIsFilled(FileExtention) Then
		CharacterNumber = StrFind(Result.FullFileName, ".", SearchDirection.FromEnd);
		If CharacterNumber > 0 Then
			FileExtention = Mid(Result.FullFileName, CharacterNumber+1);
		EndIf;
	EndIf;
	
	FormParameters.Insert("DataFileAddress", AddressOfVH);
	FormParameters.Insert("FileExtention", FileExtention);
	
	FormParameters.Insert("TableID", TableID);
	FormParameters.Insert("ColumnsByDimension", ColumnsByDimension);
	FormParameters.Insert("BudgetProfileDisplayParameters", BudgetProfileDisplayParameters); 
	FormParameters.Insert("ResultAddress", PutToTempStorage(Undefined, UUID)); 
	FormParameters.Insert("BeginOfPeriod", Object.BeginOfPeriod);
	FormParameters.Insert("PeriodEnding", Object.PeriodEnding);
	
	OpenForm("Document.BudgetEntryForm.Form.FormOfMappingOfImportedDataFromExcel", FormParameters, ThisObject);
	
EndProcedure

&AtServer
Procedure UploadBudgetToServer(AddressInTempStorage)
	
	Result = GetFromTempStorage(AddressInTempStorage);
	
	FoundRow = FinancialReportingServer.SubordinateItem(BudgetItemTree, "TableID", Result.TableID);
	Items.BudgetItemTree.CurrentRow = FoundRow.GetID();
	
	SetInputListParametersOnServer();
	
	PreviousAutomaticUpdate = AutomaticUpdateOfTheBudget;
	AutomaticUpdateOfTheBudget = False;
	
	While BudgetEditList.Count() Do
		
		DeleteRelatedBudgetLinesOnServer(BudgetEditList[0].GetID(),,False);
		BudgetEditList.Delete(0);
		
	EndDo;
	
	MaximumNumberInOrder = 0;
	For Each RowOfRevolutions In Object.BudgetFlowItemTurnovers Do
		MaximumNumberInOrder = Max(RowOfRevolutions.SerialNumber, MaximumNumberInOrder);
	EndDo;
	
	ThereAreChangesInRelatedCells = False;
	For Each ResultRow In Result.BudgetEditList Do
		NewRow = BudgetEditList.Add();
		FillPropertyValues(NewRow, ResultRow);
		ReflectChangesToData(NewRow.GetID(),,
			ThereAreChangesInRelatedCells,
			MaximumNumberInOrder);
	EndDo;
	StartReflectingBudgetChanges(ThereAreChangesInRelatedCells);
	
	AutomaticUpdateOfTheBudget = PreviousAutomaticUpdate;
	
	FoundRow = FinancialReportingServer.SubordinateItem(BudgetItemTree, "TableID", Result.TableID);
	Items.BudgetItemTree.CurrentRow = FoundRow.GetID();
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	SetAvailabilityOfItemsByStatusServer(True);
	
EndProcedure

&AtClient
Procedure AutomaticRecalculation(Command)
	
	AutomaticUpdateOfTheBudget = Not AutomaticUpdateOfTheBudget;
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"AutomaticRecalculation",
		"Check",
		AutomaticUpdateOfTheBudget);
	
	DurationOfTheLastCalculation = 0;
	
	If AutomaticUpdateOfTheBudget Then
		
		UpdateBudget();
		
	EndIf;

EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer(CheckForChangesToEditingMethod=False)
	
	ItemsAvailability = 
		Not UseBudgetConfirmation 
		Or (Object.Status <> Enums.PlanStatuses.Upholded);
		
	Items.BudgetingModel.ReadOnly = Not ItemsAvailability;
	Items.BudgetProfile.ReadOnly = Not ItemsAvailability;
	Items.Scenario.ReadOnly = Not ItemsAvailability;
	Items.BeginOfPeriod.ReadOnly = Not ItemsAvailability;
	Items.EndOfPeriod.ReadOnly = Not ItemsAvailability;
	Items.SelectPeriod.Enabled = ItemsAvailability;
	Items.Organization.ReadOnly = Not ItemsAvailability;
	Items.Department.ReadOnly = Not ItemsAvailability;
	Items.Action.ReadOnly = Not ItemsAvailability;
	Items.Budget.ReadOnly = False;
	Items.Budget.Edit = ItemsAvailability;
	Items.EmployeeResponsible.ReadOnly = Not ItemsAvailability;
	Items.BudgetEditList.ReadOnly = Not ItemsAvailability;
	Items.BudgetItemTree.ReadOnly = Not ItemsAvailability;
	
	Items.EditAsAList.Enabled = ItemsAvailability;
	Items.FillInAccordingToBudgetingData.Enabled = ItemsAvailability;
	Items.ImportFromExcel.Enabled = ItemsAvailability;
	Items.Insert.Enabled = ItemsAvailability;
	Items.CopyByPeriods.Enabled = ItemsAvailability;
	Items.AddRow.Enabled = ItemsAvailability;
	Items.DeleteRow.Enabled = ItemsAvailability;
	Items.ShouldRecalculate.Enabled = ItemsAvailability;
	Items.AutomaticRecalculation.Enabled = ItemsAvailability;
	Items.UpdateBudget.Enabled = ItemsAvailability;
	Items.Budget.ContextMenu.Enabled = ItemsAvailability;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		Item = Items.Find("AnalyticsHeader_" + Cnt);
		If Item = Undefined Then
			Continue;
		EndIf;
		Items["AnalyticsHeader_" + Cnt].ReadOnly = Not ItemsAvailability;
	EndDo;
	SetAvailabilityOfItemsForBudgetTaskServer();
	If CheckForChangesToEditingMethod And Items.PanelBudget.CurrentPage = Items.List And   
		Not ItemsAvailability Then
		WhenChangingBudgetEditingMethod();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsAfterCheckingFill()
	
	YouCanUpdateYourBudget = YouCanUpdateYourBudget(False);
	Items.GroupCommandPanelBudget.Enabled = YouCanUpdateYourBudget;
	Items.Budget.ContextMenu.Enabled = YouCanUpdateYourBudget;
	
EndProcedure

&AtServer
Procedure CheckFillInCourseTable(Cancel, MessageText)
	
	If ValueIsFilled(AddressOfExchangeRateTable) Then
		Return;
	EndIf;
	
	ParametersStructure = GetFromTempStorage(BudgetProfileDisplayParameters);
	If ParametersStructure = Undefined Then
		Return;
	EndIf;
	
	ObjectAndCalculationParameters = BudgetReportingClientServer.StructureByBudgetInstanceObject(ThisObject);
	RateTable = BudgetReportingServerCall.RateTable(ObjectAndCalculationParameters, ParametersStructure, Undefined, Cancel, MessageText);
	
	If Not Cancel = True Then
		AddressOfExchangeRateTable = PutToTempStorage(RateTable, UUID);
	EndIf;
	
EndProcedure

&AtServer
Function SetScriptParameters()
	
	AttributesValues = Common.ObjectAttributesValues(Object.Scenario, 
		"Currency, RequireExchangeRatesSpecificationForEachPeriod");
	ScenarioCurrency = AttributesValues.Currency;
	RequireExchangeRatesSpecificationForEachPeriod = AttributesValues.RequireExchangeRatesSpecificationForEachPeriod;
	
	Return AttributesValues;
	
EndFunction

&AtClient
Procedure ScenarioChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	Message = Undefined;
	If ValueSelected = PredefinedValue("Catalog.BudgetingScenarios.ActualData") Then
		Message = NStr("vi = 'Kịch bản ""Dữ liệu thực tế"" không dành cho nhập dữ liệu';
						|ru = 'Сценарий ""Фактические данные"" не предназначен для ввода данных';
						|en = 'The ""Actual data"" scenario is not designed for entering data'; fa = 'The ""Actual data"" scenario is not designed for entering data';
						|it = 'Lo scenario ""Dati effettivi"" non è destinato per inserimento dati';
						|pl = 'Scenariusz ""Dane faktyczne"" nie jest przeznaczony do wprowadzania danych';
						|tr = '""Gerçek Veriler"" senaryosu veri girişi için tasarlanmadı'");
	ElsIf ValueSelected = PredefinedValue("Catalog.BudgetingScenarios.BudgetFulfillment") Then
		Message = NStr("vi = 'Kịch bản ""Thực hiện ngân sách"" không dành cho nhập dữ liệu';
						|ru = 'Сценарий ""Исполнение бюджета"" не предназначен для ввода данных';
						|en = 'The ""Budget implementation"" scenario is not designed for entering data'; fa = 'The ""Budget implementation"" scenario is not designed for entering data';
						|it = 'Lo scenario ""Esecuzione del budget"" non è destinato per inserimento dati';
						|pl = 'Scenariusz ""Wykonanie budżetu"" nie jest przeznaczony do wprowadzania danych';
						|tr = '""Bütçenin uygulanması"" senaryosu veri girişi için tasarlanmadı'");
	EndIf;
	
	If Message <> Undefined Then
		ShowMessageBox(,Message);
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure DownloadFromExcelExtensionEnabled(Result, AdditionalParameters) Export
	
	FilesOperationsClient.OpenFileChoiceForm(Object.Ref, ThisObject);
	
EndProcedure

#EndRegion

#Region OutputAndDisplayOfTabularBudget

&AtClient
Procedure CheckCompletionOfNotificationTask(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		Try
			
			LoadPreparedData(, AdditionalParameters);
			Budget.FixedTop = FixedTop;
			Budget.FixedLeft = FixedLeft;
			If Items.BudgetItemTree.Visible Then
				AttachIdleHandler("Attachable_ExpandTreeOfBudgetItems", 1, True);
			EndIf;
			
			Items.FormPostAndClose.Enabled = True;
			Items.FormWrite.Enabled = True;
			Items.FormPost.Enabled = True;
			
		Except
			
			JobID = Undefined;
			
			StatePresentation = Items.Budget.StatePresentation;
			If Not StatePresentation.Visible Then
				
				StatePresentation.Visible = True;
				StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
				StatePresentation.Picture = New Picture;
				StatePresentation.Text = NStr("vi = 'Lỗi lập ngân sách';
												|ru = 'Ошибка формирования бюджета';
												|en = 'Budgeting error'; fa = 'Budgeting error';
												|it = 'Errore durante la generazione del budget';
												|pl = 'Błąd tworzenia budżetu';
												|tr = 'Bütçe oluşturma hatası'");
				
			EndIf;
			
			Items.FormPostAndClose.Enabled = True;
			Items.FormWrite.Enabled = True;
			Items.FormPost.Enabled = True;
			
		EndTry;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CancelCompletedTasks(Val JobID)
	
	TimeConsumingOperations.CancelJobExecution(JobID);
	
EndProcedure

&AtClient
Procedure RunChangeCalculationCheck()
		
	If ValueIsFilled(JobID) Then
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		CallbackOnCompletion = New CallbackDescription("CheckCalculationOfChangesNotification", ThisObject);

		TimeConsumingOperationsClient.WaitCompletion(
			BackgroundTaskBudgetPreparation, CallbackOnCompletion, IdleParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckCalculationOfChangesNotification(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		StartTaskAgain = False;
		
		If ThereAreChangesForRecording Then
			StartTaskAgain = True;
		EndIf;
		
		UploadResultOfCalculatingChanges();
		
		If StartTaskAgain Then
			TimeOfTheLastCalculation = CurrentDate(); //this value is used only to calculate the calculation time on the client and affects only the interface
			SetLabelForUpdatingTotals(True);
			ReflectBudgetChanges();
			RunChangeCalculationCheck();
		Else
			SetLabelForUpdatingTotals();
		EndIf;
	EndIf;
		
EndProcedure

&AtClient
Procedure SetLabelForUpdatingTotals(ProcessStart = False)
	
	If Not AutomaticUpdateOfTheBudget Then
		Items.LabelCalculationStatus.Visible = False;
		Return;
	EndIf;
	
	If ProcessStart Then
		CalculationStartTime = CurrentDate(); //this value is used only to calculate the calculation time on the client and affects only the interface
	Else
		TimeOfTheLastCalculation = CurrentDate(); //this value is used only to calculate the calculation time on the client and affects only the interface
		DurationOfTheLastCalculation = TimeOfTheLastCalculation - CalculationStartTime;
	EndIf;
		
	If DurationOfTheLastCalculation > 5 Then
		LabelText = NStr("vi = 'Việc tính toán mất %1 giây: Nên tắt tự động cập nhật tổng số';
						|ru = 'Расчет занимает %1 сек.: рекомендуется отключить автообновление итогов';
						|en = 'Calculation takes %1 sec.: it is recommended that you disable total auto update'; fa = 'Calculation takes %1 sec.: it is recommended that you disable total auto update';
						|it = 'Il calcolo impiega %1 secondi: si consiglia di disattivare l''aggiornamento automatico dei bilanci';
						|pl = 'Obliczenia trwają %1 sekund: zaleca się wyłączenie automatycznej aktualizacji wynikow';
						|tr = 'Hesaplama %1 saniye sürüyor: toplamların otomatik güncelleştirmelerini devre dışı bırakmanız önerilmektedir'");
		LabelText = StringFunctionsClientServer.SubstituteParametersToString(
									LabelText, DurationOfTheLastCalculation);
	EndIf;
	
	If DurationOfTheLastCalculation > 5 Then
		If ProcessStart Then
			Items.DecorationIsPerformedDisableAutoCalculation.Title = LabelText;
			Items.LabelCalculationStatus.CurrentPage = Items.TheCalculationIsPerformedWithErrors;
		Else
			Items.DecorationItIsRecommendedThatYouDisableAutoCalculation.Title = LabelText;
			Items.LabelCalculationStatus.CurrentPage = Items.ItIsRecommendedThatYouDisableAutoCalculation;
		EndIf;
	EndIf;
	
	Items.LabelCalculationStatus.Visible = DurationOfTheLastCalculation > 5;
	
EndProcedure

&AtClient
Procedure RunReportExecutionCheck(AdditionalParameters = Undefined)
	
	If Not FileInformationSecurity Then
		If Items.PanelBudget.CurrentPage <> Items.List Then
			Items.FormPostAndClose.Enabled = False;
			Items.FormWrite.Enabled = False;
			Items.FormPost.Enabled = False;
		EndIf;
		
		If ValueIsFilled(JobID) Then
			IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
			IdleParameters.OutputIdleWindow = False;
			CallbackOnCompletion = New CallbackDescription("CheckCompletionOfNotificationTask", ThisObject,
				AdditionalParameters);
		
			TimeConsumingOperationsClient.WaitCompletion(
				BackgroundTaskBudgetPreparation, CallbackOnCompletion, IdleParameters);
		EndIf;
		
	Else
		Action = Undefined;
		If TypeOf(AdditionalParameters) = Type("Structure") And AdditionalParameters.Property("Action") Then
			Action = AdditionalParameters.Action;
		EndIf;
		If Action = PredefinedValue("Enum.TypesOfBudgetEntryFormActions.CorrectBudgetEntryForm") Then
			WhenChangingActionServer(False);
		EndIf;
		Budget.FixedTop = FixedTop;
		Budget.FixedLeft = FixedLeft;
		If Items.BudgetItemTree.Visible Then
			AttachIdleHandler("Attachable_ExpandTreeOfBudgetItems", 1, True);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure LoadPreparedData(Val ExecutionResult = Undefined, AdditionalParameters = Undefined)
	
	CurrentRow = Items.BudgetItemTree.CurrentRow;
	RowIndex = Undefined;
	If CurrentRow <> Undefined Then
		CurrentData = BudgetItemTree.FindByID(CurrentRow);
		If CurrentData <> Undefined Then
			RowIndex = BudgetAreaByLine(Budget, DetailsDataAddress, CurrentData.GroupingID);
		EndIf;
	EndIf;
	
	If ExecutionResult = Undefined Then
		ExecutionResult = GetFromTempStorage(StorageAddress);
	EndIf;
	
	DownloadableTableParts = StrSplit("BudgetFlowItemsDimension,BudgetFlowItemTurnovers,DimensionValues_", ",");
	For Each TabularSection In DownloadableTableParts Do
		If ExecutionResult.Property(TabularSection) Then
			Object[TabularSection].Load(ExecutionResult[TabularSection]);
		EndIf;
	EndDo;
	
	Budget = ExecutionResult.Result;
	Items.Budget.ReadOnly = False;
	Items.Budget.Edit = True;
	FixedLeft = Budget.FixedLeft;
	FixedTop = Budget.FixedTop;
	
	RestoreCellSizes();
	
	PutToTempStorage(ExecutionResult.BudgetProfileDisplayParameters, 	BudgetProfileDisplayParameters);
	PutToTempStorage(ExecutionResult.CellData_, 					AddressOfCellData);
	
	DetailsData = ExecutionResult.DetailsData;
	PutToTempStorage(DetailsData, DetailsDataAddress);
	
	If ExecutionResult.Property("TableColumns") Then
		OutputParameters = GetFromTempStorage(BudgetProfileDisplayParameters);
		If Not OutputParameters.Property("TableColumns") Then
			OutputParameters.Insert("TableColumns", ExecutionResult.TableColumns);
			PutToTempStorage(OutputParameters, BudgetProfileDisplayParameters);
		EndIf;
	EndIf;
	
	ValueToFormAttribute(ExecutionResult.TreeOfEditListRows, "BudgetItemTree");
	
	SubordinateTreeItems = BudgetItemTree.GetItems();
	Items.BudgetItemTree.CurrentRow = SubordinateTreeItems[0].GetID();
	
	If RowIndex <> Undefined Then
		GroupingID = Undefined;
		Details = DetailsData[Budget.Area(RowIndex, 1).Details];
		If Details <> Undefined Then
			Details = BudgetReportingServerCall.DetailsValue(Details, DetailsDataAddress);
			If TypeOf(Details) = Type("Structure") 
				And Details.Property("GroupingID", GroupingID) Then
				
				FoundRow = FinancialReportingServer.SubordinateItem(BudgetItemTree,
					"GroupingID", GroupingID);
				If FoundRow <> Undefined Then
					Items.BudgetItemTree.CurrentRow = FoundRow.GetID();
				EndIf;
				
			EndIf;
		EndIf;
	EndIf;
	
	If ExecutionResult.Property("CellDataSortingString") Then
		CellDataSortingString = ExecutionResult.CellDataSortingString;
	EndIf;
	
	Items.BudgetItemTree.Refresh();
	
	ConditionalAppearanceItems = ConditionalAppearance.Items;
	
	ConditionalAppearanceForDeletion = New Array;
	For Each UOElement In ConditionalAppearanceItems Do
		If StrFind(UOElement.Presentation, "AddedUOOfElementTree_") Then
			ConditionalAppearanceForDeletion.Add(UOElement);
		EndIf;
	EndDo;
	
	For Each UOElement In ConditionalAppearanceForDeletion Do
		ConditionalAppearance.Items.Delete(UOElement);
	EndDo;
	
	For Each StyleKeys In ExecutionResult.LevelStyle Do
		
		Styles = StyleKeys.Value; // See BudgetReportingDisplayServer.GetCacheOfEditingListLineStyles
		
		For Each KeyAndValue In Styles Do
			
			Item = ConditionalAppearanceItems.Add();
			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue 	= New DataCompositionField("BudgetItemTree.Level");
			ItemFilter.ComparisonType 		= DataCompositionComparisonType.Equal;
			ItemFilter.RightValue 	= KeyAndValue.Key;
			
			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue 	= New DataCompositionField("BudgetItemTree.TableID");
			ItemFilter.ComparisonType 		= DataCompositionComparisonType.Equal;
			ItemFilter.RightValue 	= StyleKeys.Key;
			
			Value = KeyAndValue.Value;
			
			Item.Appearance.SetParameterValue("BackColor", Value.BackColor);
			
			FormattedField = Item.Fields.Items.Add();
			FormattedField.Field = New DataCompositionField("BudgetItemTreePresentation");
			
			Item.Use = True;
			Item.Presentation = "AddedUOOfElementTree_" + KeyAndValue.Key;
			
		EndDo;
		
	EndDo;
	
	JobID = Undefined;
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Budget, "DontUse");
	DeleteFromTempStorage(StorageAddress);
	
	SetAvailabilityOfItemsByStatusServer();
	
	Action = Undefined;
	If TypeOf(AdditionalParameters) = Type("Structure") And AdditionalParameters.Property("Action") Then
		Action = AdditionalParameters.Action;
	EndIf;
	If Action = Enums.TypesOfBudgetEntryFormActions.CorrectBudgetEntryForm Then
		WhenChangingActionServer(False);
	EndIf;
	
	If ExecutionResult.Property("ConsiderAdditionalSelectionByHierarchy")
		And ExecutionResult.ConsiderAdditionalSelectionByHierarchy Then
		ObjectAndCalculationParameters = BudgetReportingClientServer.StructureByBudgetInstanceObject(ThisObject);
		BudgetingServer.CheckFixTSInstanceBudget(Object, ObjectAndCalculationParameters, Budget, DetailsData);
	EndIf;
	
	If AdditionalParameters <> Undefined And AdditionalParameters.Property("FillingInAccordingToInfobaseData") Then
		If Items.PanelBudget.CurrentPage = Items.List Then
			SetInputListParametersOnServer(False);
		ElsIf ExecutionResult.Property("CellTotalsNeedToBeRecalculated") Then
			GenerateReportServer(True, True);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure UploadResultOfCalculatingChanges(Val Mode = "", ExecutionResult = Undefined)
	
	ExecutingTheChangeCalculationJob = False;
	
	If ExecutionResult = Undefined Then
		Return;
	EndIf;
	
	PutToTempStorage(ExecutionResult.BudgetProfileDisplayParameters, BudgetProfileDisplayParameters);
	PutToTempStorage(ExecutionResult.CellData_, AddressOfCellData);
	
	JobID = Undefined;
	ThereAreChangesForRecording = False;
	
	UpdateCellData_ = Mode = "UpdateCellData_";
	
	If Not UpdateCellData_ Then
		
		ObjectAndCalculationParameters = BudgetReportingClientServer.StructureByBudgetInstanceObject(ThisObject);
		LoadResultOfCalculatingChangesOnClient(ObjectAndCalculationParameters, Budget, ExecutionResult.Result);
		
	EndIf;
	
EndProcedure

&AtServer
Function ParametersForOpeningDecryptionReport()
	
	Try
		Details = Items.Budget.CurrentArea.Details;
		Details = BudgetReportingServerCall.DetailsValue(Details, DetailsDataAddress);
	Except
		Return Undefined;
	EndTry;
	
	If TypeOf(Details) <> Type("Structure") Then
		Return Undefined;
	EndIf;
	
	ReportParameters = PrepareReportParameters();
	Return BudgetReportingServerCall.ParametersForOpeningDecryptionReport(ReportParameters, Details, AddressOfCellData);
	
EndFunction

&AtClient
Procedure AfterSavingDocumentBeforeDecrypting(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Modified Or Object.Ref.IsEmpty() Then
		Write(New Structure("WriteMode", DocumentWriteMode.Posting));
	EndIf;
	
	OpeningParameters = ParametersForOpeningDecryptionReport();
	If OpeningParameters <> Undefined Then
		BudgetReportingClient.OpenReportForm(OpeningParameters, ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region OutputDisplayAndEditBudgetList

&AtServer
Procedure AddTranscriptForArticleParameters(Details)
	Value = Undefined;
	ObjectOfCurrencyAccounting = Undefined;
	
	AnalystValues = New Map;
	ColumnStructureOfDataTable = GetFromTempStorage(BudgetProfileDisplayParameters).ColumnStructureOfDataTable;
	DimensionKinds = ColumnStructureOfDataTable.DimensionKinds;
	For Each DimensionKind In DimensionKinds Do
		DimensionKey = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
		If Details.Property(DimensionKey, Value) Then
			AnalystValues.Insert(DimensionKind, Value);
		EndIf;
	EndDo;
	
	Details.Insert("AnalystValues", AnalystValues);
	
	If Not Details.Property("Currency") Then
		
		If Details.Property("BudgetFlowItem") Then
			ArticleParameterValues = ItemParameterCache[Details.BudgetFlowItem];
			If ArticleParameterValues.CurrencyIsDeterminedByDimension Then
				If Details.Property(ArticleParameterValues.NameAndCurrency, ObjectOfCurrencyAccounting) Then
					If ValueIsFilled(ObjectOfCurrencyAccounting) Then
						CellCurrency = Common.ObjectAttributeValue(ObjectOfCurrencyAccounting, ArticleParameterValues.PathToCurrencyAnalytics);
						Details.Insert("Currency", CellCurrency);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function DecryptionOfReportByLine(DecryptionOfColumn, CurrentRow, Dimensions)
	
	Details = Common.CopyRecursive(DecryptionOfColumn);
	For Each Dimension In Dimensions Do
		If Not ValueIsFilled(CurrentRow[Dimension]) Then
			CurrentRow[Dimension] = Undefined;
		EndIf;
		Details.Insert(Dimension, CurrentRow[Dimension]);
	EndDo;
	
	AddTranscriptForArticleParameters(Details);
	
	Return Details;
	
EndFunction

&AtServer
Procedure LoadListData(ColumnsByDimension, FixedValues, StructureAnalogDecryption, OnlyUpdate = False)
	
	CellData_ = GetFromTempStorage(AddressOfCellData); // See BudgetReportingDisplayServer.GetSelectionOfCellsHierarchically.CellData_
	BudgetInstanceParameters = GetFromTempStorage(BudgetProfileDisplayParameters);
	CellDataTableIndexes = BudgetInstanceParameters.CellDataTableIndexes;
	CellParameters = BudgetInstanceParameters.StructureOfReportDescription.CellParameters;
	
	If Not OnlyUpdate Then
		BudgetEditList.Clear();
		ProcessingTable = BudgetEditList.Unload(New Array).CopyColumns();
		ProcessingTable.Columns.Add("MinimumNumberInOrder");
	EndIf;
	
	For Each String In ColumnsByDimension.BaseLines Do
		
		TheStructureOfTheSearch = New Structure("MainItem, String", True, String);
		For Each KeyAndValue In FixedValues Do
			TheStructureOfTheSearch.Insert(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
		
		CellDataRows = CellData_.Copy(TheStructureOfTheSearch);
		CellDataRows.Sort("MinimumNumberInOrder");
		
		ConvolutionString = StrConcat(ColumnsByDimension.Dimensions, ",");
		DataRows = CellDataRows.Copy();
		If IsBlankString(ConvolutionString) Then
			DataRows = New Array;
			DataRows.Add(New Structure);
		Else
			DataRows.GroupBy(ConvolutionString);
		EndIf;
		
		For Each DataString1 In DataRows Do
			
			SumStructure = New Structure;
			StructureOfNotes = New Structure;
			
			ThereAreMeaningfulColumns = False;
			
			For Each Details In StructureAnalogDecryption Do
				TextIndex = "MainItem,String";
				TheStructureOfTheSearch = New Structure("MainItem, String", True, String);
				For Each Dimension In ColumnsByDimension.Dimensions Do
					MeasurementColumn     = ColumnsByDimension.ColumnSettings[Dimension];
					Type = MeasurementColumn.ValueType;
					Value = BudgetingClientServer.ReducedAnalyticsValue(DataString1[Dimension], Type);
					TheStructureOfTheSearch.Insert(Dimension, Value);
					TextIndex = TextIndex + "," + Dimension;
				EndDo;
				IndicatorName = "Sum";
				For Each KeyAndValue In Details.Value Do
					If KeyAndValue.Key = "Calculated" Then
						// supporting information
						Continue;
					EndIf;
					If KeyAndValue.Key = "IndicatorName" Then
						IndicatorName = KeyAndValue.Value;
						Continue;
					EndIf;
					TheStructureOfTheSearch.Insert(KeyAndValue.Key, KeyAndValue.Value);
					TextIndex = TextIndex + "," + KeyAndValue.Key;
				EndDo;
				
				If CellDataTableIndexes[TextIndex] = Undefined Then
					CellData_.Indexes.Add(TextIndex);
					CellDataTableIndexes.Insert(TextIndex, True);
				EndIf;
				
				FoundRows = CellData_.FindRows(TheStructureOfTheSearch);
				
				Value = 0; Note = "";
				If FoundRows.Count() > 1 Then
					ErrorText = NStr("vi = 'Lỗi trong cấu trúc của loại ngân sách';
									|ru = 'Ошибка в структуре вида бюджета';
									|en = 'Error in the budget profile structure'; fa = 'Error in the budget profile structure';
									|it = 'Errore nella struttura della tipologia di budget';
									|pl = 'Błąd w strukturze typu budżetu';
									|tr = 'Bütçe profili yapısında hata'");
					Raise ErrorText;
				ElsIf FoundRows.Count() = 1 Then
					CellDataString = FoundRows[0];
					If IndicatorName = "Sum" And ValueIsFilled(CellDataString.Currency) Then
						IndicatorName = "SumCurr";
					EndIf;
					ParametersString1 = CellParameters.Find(CellDataString.RowIndex, "RowIndex");
					If CellDataString.ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem Then
						Value = CellDataString.Value;
					ElsIf CellDataString.ItemKind = Enums.FinancialReportItemKinds.EditedValue Then
						Value = CellDataString.Value;
					ElsIf ParametersString1.TableComplex_ Then
						Value = Undefined;
						If ParametersString1.FlagSum Then
							Value = CellDataString[IndicatorName];
						ElsIf ParametersString1.FlagCount Then
							Value = CellDataString.Count;
						EndIf;
						If Not ValueIsFilled(Value) Then
							Value = 0;
						EndIf;
					Else
						Value = ?(CellDataString[IndicatorName]=Undefined,0,CellDataString[IndicatorName]);
					EndIf;
					Note = CellDataString.Note;
				EndIf;
				
				If ValueIsFilled(Value) Or OnlyUpdate Then
					If Not Details.Value.Property("Calculated") Then
						ThereAreMeaningfulColumns = True;
					EndIf;
					SumStructure.Insert(Details.Key, Value);
				EndIf;
				
				If ValueIsFilled(Note) Then
					StructureOfNotes.Insert(Details.Key + "Note", Note);
					StructureOfNotes.Insert(Details.Key + "PictureNote", PictureLib.Comment);
				EndIf;
				
			EndDo;
			
			If OnlyUpdate Or ThereAreMeaningfulColumns Or StructureOfNotes.Count() Then
				ArrayOfDimensions_ = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ConvolutionString);
				
				ListSearchStructure = New Structure();
				DataSearchStructure = New Structure();
				
				For Each Dimension In ArrayOfDimensions_ Do
					Value = DataString1[Dimension];
					DataSearchStructure.Insert(Dimension, Value);
					Type = ColumnsByDimension.ColumnSettings[Dimension].ValueType;
					Value = BudgetingClientServer.ReducedAnalyticsValue(Value, Type);
					ListSearchStructure.Insert(Dimension, Value);
				EndDo;
				
				If OnlyUpdate Then
					FoundRows = BudgetEditList.FindRows(ListSearchStructure);
					If FoundRows.Count() Then
						NewRow = FoundRows[0];
					Else
						Continue;
					EndIf;
				Else
					NewRow = ProcessingTable.Add();
					FillPropertyValues(NewRow, DataString1);
					DataSearchStructure.Insert("ItemKind", Enums.FinancialReportItemKinds.BudgetFlowItem);
					RowsToSearchForNumbersInOrder = CellDataRows.FindRows(DataSearchStructure);
					For Each NumberLine In RowsToSearchForNumbersInOrder Do
						If NumberLine.MinimumNumberInOrder <> Null Then
							NewRow.MinimumNumberInOrder = NumberLine.MinimumNumberInOrder;
							Break;
						EndIf;
					EndDo;
				EndIf;
				
				FillPropertyValues(NewRow, SumStructure);
				FillPropertyValues(NewRow, StructureOfNotes);
			EndIf;
			
		EndDo;
		
	EndDo;
	
	If Not OnlyUpdate Then
		ProcessingTable.Sort("MinimumNumberInOrder");
		BudgetEditList.Load(ProcessingTable);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetInputListParametersOnServer(ManageVisibilityOfElementTree = True)
	
	PreviousLineOfItemTree = Items.BudgetItemTree.CurrentRow;
	
	MessageText = NStr("vi = 'Không thể chỉnh sửa cho dòng hiện tại. Chọn một dòng khác';
						|ru = 'Редактирование для текущей строки не предусмотрено. Выберите другую строку бюджета';
						|en = 'The selected line cannot be edited. Select another budget line'; fa = 'سطر انتخاب‌شده قابل ویرایش نیست. سطر بودجه دیگری انتخاب کنید';
						|it = 'La modifica non è prevista per la riga corrente. Scegli un''altra linea di budget';
						|pl = 'Nie jest dostępne edytowanie dla bieżącego wiersza. Wybierz inny wiersz budżetu';
						|tr = 'Mevcut satır düzenlenemedi. Başka bir bütçe satırı seçiniz'");
	Cancel = False;
	CheckFillInCourseTable(Cancel, MessageText);
	If Not YouCanUpdateYourBudget() Then
		Cancel = True;
	EndIf;
	
	If Cancel Then
		Items.NoteToTheCurrentLine.Title = MessageText;
		Items.BudgetEditingListGroup.CurrentPage = Items.LineInformation;
		Return;
	EndIf;
	
	BudgetInstanceParameters = GetFromTempStorage(BudgetProfileDisplayParameters);
	ParametersList = BudgetInstanceParameters.InputListDescriptionStructure;
	TableColumns = BudgetInstanceParameters.TableColumns;
	
	IndexOfCurRow = Items.BudgetItemTree.CurrentRow;
	If IndexOfCurRow = Undefined Then
		Items.NoteToTheCurrentLine.Title = MessageText;
		Items.BudgetEditingListGroup.CurrentPage = Items.LineInformation;
		Return;
	EndIf;
	
	CurrentRow = BudgetItemTree.FindByID(IndexOfCurRow);
	
	If CurrentRow.GetParent() = Undefined Then
		
		ColumnsByDimension = Undefined;
		If Not Documents.BudgetEntryForm.CompositionOfRootElementColumns(CurrentRow, ParametersList, ColumnsByDimension) Then
			Items.NoteToTheCurrentLine.Title = MessageText;
			Items.BudgetEditingListGroup.CurrentPage = Items.LineInformation;
			If ManageVisibilityOfElementTree Then
				Items.ShowHideBudgetTree.Check = True;
				Items.BudgetItemTree.Visible = Items.ShowHideBudgetTree.Check;
			EndIf;
			Return;
		Else
			If ManageVisibilityOfElementTree Then
				Items.ShowHideBudgetTree.Check = False;
				Items.BudgetItemTree.Visible = Items.ShowHideBudgetTree.Check;
			EndIf;
			Items.BudgetEditingListGroup.CurrentPage = Items.EditingList;
		EndIf;
		
	Else
		
		ColumnsByDimension = ParametersList[CurrentRow.String];
		
	EndIf;
	
	If ColumnsByDimension = Undefined Then
		Items.NoteToTheCurrentLine.Title = MessageText;
		Items.BudgetEditingListGroup.CurrentPage = Items.LineInformation;
		Return;
	EndIf;
	
	Items.BudgetEditingListGroup.CurrentPage = Items.EditingList;
	
	RowDescription = GetFromTempStorage(AddressOfLineEditingParameters);
	
	// Setting fixed values for a row
	// if grouping values are already defined in the tree hierarchy.
	DetailsData = GetFromTempStorage(DetailsDataAddress); 
	FixedValues = New Structure;
	CalculationLine = CurrentRow;
	While CalculationLine <> Undefined Do
		If ValueIsFilled(CalculationLine.DimensionName) Then
			If ColumnsByDimension.ColumnSettings.Property(CalculationLine.DimensionName) Then
				Value = Undefined;
				If Not CalculationLine.ThisIsDimensionOther Then
					Value = CalculationLine.FixedValue;
				EndIf;
				Type = ColumnsByDimension.ColumnSettings[CalculationLine.DimensionName].ValueType;
				Value = BudgetingClientServer.ReducedAnalyticsValue(Value, Type);
				FixedValues.Insert(CalculationLine.DimensionName, Value);
			EndIf;
		EndIf;
		
		// Let's add the analytics of the combined rows
		If CalculationLine.ThisIsACombinedDimension And ValueIsFilled(CurrentRow.Details) Then
			ExcludingAnalytics = New Map();
			If CalculationLine.GetItems().Count() > 0 Then
				SubordinateRow = CalculationLine.GetItems()[0];
				If ValueIsFilled(SubordinateRow.Details) Then
					SubordinateAnalysts = DetailsData[SubordinateRow.Details].AnalystValues;
					For Each KeyValue In SubordinateAnalysts Do
						ExcludingAnalytics.Insert(KeyValue.Key, True);
					EndDo;
				EndIf;
			EndIf;
			
			AnalystValues = DetailsData[CurrentRow.Details].AnalystValues;
			For Each KeyValue In AnalystValues Do
				If ExcludingAnalytics.Get(KeyValue.Key) = Undefined And ColumnsByDimension.ColumnSettings.Property(KeyValue.Key) Then
					FixedValues.Insert(KeyValue.Key, KeyValue.Value);
				EndIf;
			EndDo;
		EndIf;
		
		CalculationLine = CalculationLine.GetParent();
	EndDo;
	
	ItemsToAdd1 = New Array; // Array of FormAttribute
	ColumnsToAdd = New Array; // Array of FormAttribute
	Documents.BudgetEntryForm.CalculateBudgetListItemsToAdd(
							ItemsToAdd1, ColumnsToAdd, ColumnsByDimension, FixedValues);
	
	If EditMeasurementsMatch(RowDescription, ColumnsByDimension, CurrentRow.TableID) Then
		
		StructureAnalogDecryption = RowDescription.StructureAnalogDecryption;
		For Each Column In ColumnsToAdd Do
			
			Documents.BudgetEntryForm.SetAvailabilityColumnSelectionList(Items[Column.Name], Column, FixedValues);
			
		EndDo;
		
	Else
		
		// columns of the current table
		ColumnStructure1 = TableColumns[CurrentRow.TableID];
		
		// structure with field keys of the current column
		StructureAnalogDecryption = New Structure;
		
		ParametersForAddingColumns = Documents.BudgetEntryForm.TemplateForParametersForAddingColumnsToBudgetList();
		ParametersForAddingColumns.ItemsToAdd1        = ItemsToAdd1;
		ParametersForAddingColumns.ColumnsToAdd         = ColumnsToAdd;
		ParametersForAddingColumns.ColumnsByDimension        = ColumnsByDimension;
		ParametersForAddingColumns.ColumnStructure1           = ColumnStructure1;
		ParametersForAddingColumns.StructureAnalogDecryption = StructureAnalogDecryption;
		Documents.BudgetEntryForm.AddBudgetListColumnsByTable(ParametersForAddingColumns);
		
		Documents.BudgetEntryForm.ReflectChangesToBudgetListColumnsOnForm(ThisObject, ItemsToAdd1, ColumnsToAdd, FixedValues);
		
		FixColumnsOnLeft = ColumnsByDimension.Dimensions.Count();
		If FixColumnsOnLeft <= 3 Then
			Items.BudgetEditList.FixedLeft = FixColumnsOnLeft;
		EndIf;
		
	EndIf;
	
	LoadListData(ColumnsByDimension, FixedValues, StructureAnalogDecryption);
	
	RowDescription = New Structure();
	RowDescription.Insert("FixedValues", FixedValues);
	RowDescription.Insert("StructureAnalogDecryption", StructureAnalogDecryption);
	RowDescription.Insert("VariableMeasurements", ColumnsByDimension.Dimensions);
	RowDescription.Insert("ColumnsByDimension", ColumnsByDimension);
	RowDescription.Insert("TableID", CurrentRow.TableID);
	
	PutToTempStorage(RowDescription, AddressOfLineEditingParameters);
	
	EditedListColumns = StrConcat(ColumnsByDimension.Dimensions, ",");
	
EndProcedure

&AtServer
Procedure ReflectChangesToData(RowIndex, ColumnName = "", ThereAreChangesInRelatedCells = False, MaximumNumberInOrder = Undefined)
	
	EditParameters = GetFromTempStorage(AddressOfLineEditingParameters);
	LineToEdit = BudgetEditList.FindByID(RowIndex);
	
	If ColumnName = "" Then
		
		For Each KeyAndValue In EditParameters.StructureAnalogDecryption Do
			
			ColumnName = KeyAndValue.Key;
			Details = DecryptionOfReportByLine(KeyAndValue.Value, LineToEdit, EditParameters.VariableMeasurements);
			If Details.Property("Calculated") Then
				Continue;
			EndIf;
			
			ReflectCellChange(Details,
				LineToEdit[ColumnName],
				LineToEdit[ColumnName + "Note"],
				MaximumNumberInOrder);
			
		EndDo;
		
	Else
		
		If Not EditParameters.StructureAnalogDecryption.Property(ColumnName) Then
			Return;
		EndIf;
		
		If ValueIsFilled(LineToEdit[ColumnName + "Note"]) Then
			LineToEdit[ColumnName + "PictureNote"] = PictureLib.Comment;
		Else
			LineToEdit[ColumnName + "PictureNote"] = Undefined;
		EndIf;
		
		ColumnValues = EditParameters.StructureAnalogDecryption[ColumnName];
		Details = DecryptionOfReportByLine(ColumnValues, LineToEdit, EditParameters.VariableMeasurements);
		ReflectionResult = ReflectCellChange(Details,
			LineToEdit[ColumnName],
			LineToEdit[ColumnName + "Note"],
			MaximumNumberInOrder);
		
		If AutomaticUpdateOfTheBudget Then
			
			// To fill in the corresponding values of the NFP and Derived Indicators
			// , the data must be filled in in the cells.
			ReflectBudgetChanges("UpdateCellData_", EditParameters.ColumnsByDimension.BaseLines);
			
		EndIf;
		
		Details.Delete("AnalystValues");
		Details.Insert("BaseLines", EditParameters.ColumnsByDimension.BaseLines);
		ReportParameters = BudgetReportingClientServer.PeriodParameters_(Object);
		BudgetInstanceChanges = BudgetReportingDisplayServer.CalculateRelatedBudgetItems(
			BudgetProfileDisplayParameters,
			AddressOfCellData,
			ReportParameters,
			Details,
			ReflectionResult,,
			ThereAreChangesInRelatedCells);
		UploadResultOfCalculatingChanges(, BudgetInstanceChanges); // reflection of the calculation of "recalculated"
		
	EndIf;
	
EndProcedure

&AtServer
Procedure StartReflectingBudgetChanges(ThereAreChangesInRelatedCells)
	
	EditParameters = GetFromTempStorage(AddressOfLineEditingParameters);
	
	ReflectBudgetChanges("UpdateCellData_", EditParameters.ColumnsByDimension.BaseLines);
	
	If AutomaticUpdateOfTheBudget Or ThereAreChangesInRelatedCells Then
	
		// If there were changes in the "linked" cells, we will reflect the changes in the list
		LoadListData(EditParameters.ColumnsByDimension,
				EditParameters.FixedValues,
				EditParameters.StructureAnalogDecryption,
				True);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearDataOfChangedColumns(CurrentRow)
	
	LineToEdit = BudgetEditList.FindByID(CurrentRow);
	
	ClearingValuesIsRequired = False;
	EditParameters = GetFromTempStorage(AddressOfLineEditingParameters);
	DecryptionAtBeginningOfEditing = GetFromTempStorage(AddressOfEditedValuesOfListLine);
	For Each Dimension In EditParameters.VariableMeasurements Do
		If LineToEdit[Dimension] <> DecryptionAtBeginningOfEditing[Dimension] Then
			ClearingValuesIsRequired = True;
			Break;
		EndIf;
	EndDo;
	
	If ClearingValuesIsRequired Then
		DecryptionAtBeginningOfEditing.Insert("Currency", Undefined);
		DeleteRelatedBudgetLinesOnServer(CurrentRow, DecryptionAtBeginningOfEditing);
	EndIf;
	
EndProcedure

&AtServer
Function EditMeasurementsMatch(RowDescription, ColumnsByDimension, TableID)
	
	If RowDescription = Undefined Then
		Return False;
	EndIf;
	
	Dimensions = ColumnsByDimension.Dimensions;
	
	MeasurementListIsOld = StrConcat(RowDescription.VariableMeasurements, ",");
	MeasurementListIsNew = StrConcat(Dimensions, ",");
	
	If MeasurementListIsOld <> MeasurementListIsNew Then
		Return False;
	EndIf;
	
	If RowDescription.TableID <> TableID Then
		Return False;
	EndIf;
	
	If RowDescription.ColumnsByDimension.Property("BudgetFlowItems") Then
	
		For Each ColumnDetails In RowDescription.StructureAnalogDecryption Do
			
			Column = ColumnDetails.Value.Column;
			
			ComparedValuesAreOld = RowDescription.ColumnsByDimension.BudgetFlowItems[Column];
			ComparedValuesAreNew = ColumnsByDimension.BudgetFlowItems[Column];
			
			If ComparedValuesAreOld = Undefined
				And ComparedValuesAreNew = Undefined Then
				
				Continue;
				
			EndIf;
			
			If ComparedValuesAreOld = Undefined
				And ComparedValuesAreNew <> Undefined 
				Or 
				ComparedValuesAreOld <> Undefined
				And ComparedValuesAreNew = Undefined Then
				
				Return False;
				
			EndIf;
			
			If ComparedValuesAreOld.BudgetFlowItem <> ComparedValuesAreNew.BudgetFlowItem
				Or ComparedValuesAreOld.EditedValue <> ComparedValuesAreNew.EditedValue
				Or ComparedValuesAreOld.IndicatorName <> ComparedValuesAreNew.IndicatorName Then
				
				Return False;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return True;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	Result - DialogReturnCode -
// 	AdditionalParameters - Structure - Possible Values:
// 		* Id - Number -
// 		* ColumnName    - String -
//
&AtClient
Procedure SelectingLineIncrease(Result, AdditionalParameters) Export
	
	DoubleQuestionDialogIsOpen = False;
	
	If Result = DialogReturnCode.Yes Then
		
		DisconnectionTime = True;
		ChangesToListAreReflectedInDocument = True;
		Items.BudgetEditList.EndEditRow(False);
		
		IncreaseValueOfStringOnServer(AdditionalParameters.Id);
		
		TableRow = BudgetEditList.FindByID(AdditionalParameters.Id);
		If TableRow <> Undefined Then
			BudgetEditList.Delete(BudgetEditList.IndexOf(TableRow));
		EndIf;
		
		Items.BudgetEditList.Refresh();
		
	ElsIf Result = DialogReturnCode.No Then
		
		DisconnectionTime = True;
		Items.BudgetEditList.EndEditRow(True);
		TableRow = BudgetEditList.FindByID(AdditionalParameters.Id);
		If TableRow <> Undefined Then
			BudgetEditList.Delete(BudgetEditList.IndexOf(TableRow));
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function ReflectCellChange(Details, ValueText, Note = Undefined, MaximumNumberInOrder = Undefined)
	
	ObjectAndCalculationParameters = BudgetReportingClientServer.StructureByBudgetInstanceObject(ThisObject);
	If TypeOf(MaximumNumberInOrder) = Type("Number") Then
		ObjectAndCalculationParameters.Insert("MaximumNumberInOrder", MaximumNumberInOrder);
	EndIf;
	Result = BudgetReportingClientServer.ReflectCellChange(ObjectAndCalculationParameters, Details, ValueText, Note);
	
	Return Result;
	
EndFunction

&AtServer
Procedure IncreaseValueOfStringOnServer(RowIndex)
	
	EditParameters = GetFromTempStorage(AddressOfLineEditingParameters);
	LineToEdit = BudgetEditList.FindByID(RowIndex);
	
	TheStructureOfTheSearch = New Structure(EditedListColumns);
	FillPropertyValues(TheStructureOfTheSearch, LineToEdit);
	
	FoundRows = BudgetEditList.FindRows(TheStructureOfTheSearch);
	For Each FoundRow In FoundRows Do
		
		If FoundRow = LineToEdit Then
			Continue;
		EndIf;
		
		For Each KeyAndValue In EditParameters.StructureAnalogDecryption Do
			
			If KeyAndValue.Value.Property("Calculated") Then
				Continue;
			EndIf;
			
			FoundRow[KeyAndValue.Key] = FoundRow[KeyAndValue.Key] + LineToEdit[KeyAndValue.Key];
			Details = DecryptionOfReportByLine(KeyAndValue.Value, FoundRow, EditParameters.VariableMeasurements);
			ReflectCellChange(Details, FoundRow[KeyAndValue.Key]);
			
		EndDo;
		
	EndDo;
	
	ReflectBudgetChanges("UpdateCellData_", EditParameters.ColumnsByDimension.BaseLines);
	
EndProcedure

&AtServer
Procedure DeleteRelatedBudgetLinesOnServer(RowIndex, Val DecryptingString = Undefined, UpdateCellData = True)
	Value = Undefined;
	
	EditParameters = GetFromTempStorage(AddressOfLineEditingParameters);
	LineToEdit = BudgetEditList.FindByID(RowIndex);
	
	If DecryptingString <> Undefined Then
		
		AnalystValues = New Map;
		DimensionKinds = GetFromTempStorage(BudgetProfileDisplayParameters).ColumnStructureOfDataTable.DimensionKinds;
		For Each DimensionKind In DimensionKinds Do
			DimensionKey = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
			If DecryptingString.Property(DimensionKey, Value) Then
				AnalystValues.Insert(DimensionKind, Value);
			EndIf;
		EndDo;
		
		DecryptingString.Insert("AnalystValues", AnalystValues);
		
	EndIf;
	
	For Each StructureColumn In EditParameters.StructureAnalogDecryption Do
	
		If StructureColumn.Value.Property("Calculated") Then
			Continue;
		EndIf;
		
		If DecryptingString <> Undefined Then
			Details = DecryptionOfReportByLine(StructureColumn.Value,
				DecryptingString, EditParameters.VariableMeasurements);
		Else
			Details = DecryptionOfReportByLine(StructureColumn.Value,
				LineToEdit, EditParameters.VariableMeasurements);
		EndIf;
		
		ProcessColumn = Details.Property("BudgetFlowItem") And ValueIsFilled(Details.BudgetFlowItem);
		ProcessColumn = ProcessColumn Or Details.Property("EditedValue");
		
		If ProcessColumn Then
			ReflectCellChange(Details, 0, "");
		EndIf;
		
	EndDo;
	
	If UpdateCellData Then
		ReflectBudgetChanges("UpdateCellData_", EditParameters.ColumnsByDimension.BaseLines);
	EndIf;
	
EndProcedure

&AtServer
Function AfterEnteringValueThereWillBeDouble(CurrentRow)
	
	If EditedListColumns = ""
		And BudgetEditList.Count() > 1 Then
		Return True;
	EndIf;
	
	LineToEdit = BudgetEditList.FindByID(CurrentRow);
	
	If LineToEdit = Undefined Then
		Return False;
	EndIf;
	
	TheStructureOfTheSearch = New Structure(EditedListColumns);
	
	FillPropertyValues(TheStructureOfTheSearch, LineToEdit);
	
	ValidationLines = BudgetEditList.FindRows(TheStructureOfTheSearch);
	
	If ValidationLines.Count() > 1 Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

&AtServer
Function ThereAreInaccessibleValuesInCells(CurrentRow, ColumnNamesOfAnalystTypes)
	
	CellStructure = GetFromTempStorage(BudgetProfileDisplayParameters).StructureOfReportDescription.CellStructure;
	CurrentData = BudgetEditList.FindByID(CurrentRow);
	Dimensions = StringFunctionsClientServer.SplitStringIntoSubstringsArray(EditedListColumns);
	
	SearchTable = CellStructure;
	For Each Dimension In Dimensions Do
		If BudgetReportingClientServer.ThisIsPeriodField(Dimension) Then
			Continue;
		EndIf;
		Value = CurrentData[Dimension];
		If Not ValueIsFilled(Value) Then
			CurrentData[Dimension] = Undefined;
			Value = CurrentData[Dimension];
			
			ThisIsAnalyticsColumn = ColumnNamesOfAnalystTypes.Find(Dimension) <> Undefined;
			If ThisIsAnalyticsColumn Then
				Value = BudgetingClientServer.EmptyDimensionValue();
			EndIf;
		EndIf;
		TheStructureOfTheSearch = New Structure(Dimension, Value);
		TemporarySearchTable = SearchTable.Copy(TheStructureOfTheSearch);
		If Not TemporarySearchTable.Count() Then
			TheStructureOfTheSearch = New Structure("Flag" + Dimension, "document");
			TemporarySearchTable = SearchTable.Copy(TheStructureOfTheSearch);
			If Not TemporarySearchTable.Count() Then
				Return Dimension;
			EndIf;
		EndIf;
		SearchTable = TemporarySearchTable;
	EndDo;
	
	Return Undefined;
	
EndFunction

&AtServer
Function ThereAreElementsUnavailableForInput(CurrentRow, ColumnWithError = Undefined)
	
	ColumnsArray1 = StringFunctionsClientServer.SplitStringIntoSubstringsArray(EditedListColumns);
	LineToEdit = BudgetEditList.FindByID(CurrentRow);
	
	OutputParameters = GetFromTempStorage(BudgetProfileDisplayParameters);
	DimensionKinds = OutputParameters.ColumnStructureOfDataTable.DimensionKinds;
	ColumnNamesOfAnalystTypes = New Array;
	For Each DimensionKind In DimensionKinds Do
		ColumnNamesOfAnalystTypes.Add(FinancialReportingCached.NameOfBudgetReportField(DimensionKind));
	EndDo;
	
	For Each Column In ColumnsArray1 Do 
		If Items[Column].ChoiceList.Count() Then
			SearchValue = LineToEdit[Column];
			If Not ValueIsFilled(SearchValue) Then
				LineToEdit[Column] = Undefined;
				SearchValue = LineToEdit[Column];
				
				If ColumnNamesOfAnalystTypes.Find(Column) <> Undefined Then
					SearchValue = BudgetingClientServer.EmptyDimensionValue();
				EndIf;
			EndIf;
			If Items[Column].ChoiceList.FindByValue(SearchValue) = Undefined Then
				ColumnWithError = Column;
				Return True;
			EndIf;
		EndIf;
	EndDo;
	
	CheckResult = ThereAreInaccessibleValuesInCells(CurrentRow, ColumnNamesOfAnalystTypes);
	If CheckResult <> Undefined Then
		ColumnWithError = CheckResult;
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

&AtServer
Function ThereAreErrorsInBudgetEditLine(CurrentRow, CheckResult)
	ColumnWithError = Undefined;
	ValidCurrency = Undefined;
	
	If DifferentCurrency(CurrentRow, ValidCurrency) Then
		CheckResult = New Structure("Result, ValidCurrency", "DifferentCurrency", ValidCurrency);
		Return True;
	ElsIf AfterEnteringValueThereWillBeDouble(CurrentRow) Then
		CheckResult = New Structure("Result", "AfterEnteringValueThereWillBeDouble");
		Return True;
	ElsIf ThereAreElementsUnavailableForInput(CurrentRow, ColumnWithError) Then
		CheckResult = New Structure("Result, ColumnWithError", "ThereAreElementsUnavailableForInput", ColumnWithError);
		Return True;
	Else
		CheckResult = New Structure("Result", "OK");
	EndIf;
	
	Return False;
	
EndFunction

&AtServer
Function DifferentCurrency(CurrentRow, ValidCurrency)
	
	LineToEdit = BudgetEditList.FindByID(CurrentRow);
	EditParameters = GetFromTempStorage(AddressOfLineEditingParameters);
	
	CacheOfArticleDetails = New Map;
	For Each KeyAndValue In EditParameters.StructureAnalogDecryption Do 
		
		If ValueIsFilled(LineToEdit[KeyAndValue.Key]) Then
			
			DecryptionOfColumn = KeyAndValue.Value;
			Details = DecryptionOfReportByLine(DecryptionOfColumn,
				LineToEdit, EditParameters.VariableMeasurements);
			Currency = Undefined;
			If Details.Property("Currency", Currency) Then
				AnalyticsCurrency = Documents.BudgetEntryForm.CurrencyForEnteringAnalytics(Details, CacheOfArticleDetails);
				If AnalyticsCurrency <> Undefined Then
					If AnalyticsCurrency <> Currency Then
						ValidCurrency = AnalyticsCurrency;
						Return True;
					EndIf;
				EndIf;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

#EndRegion

#Region SwitchingTableListMode

&AtClientAtServerNoContext
Function BudgetAreaByLine(Budget, DetailsDataAddress, SearchRow)
	GroupingID = Undefined;
	
	MatchingTranscripts = New Array;
	For Cnt = 1 To Budget.PageHeight Do
		BudgetArea = Budget.Area(Cnt, 1);
		Details = BudgetArea.Details;
		MatchingTranscripts.Add(Details);
	EndDo;
	
	MatchingTranscripts = BudgetReportingServerCall.DetailsValue(MatchingTranscripts, DetailsDataAddress);
	
	For Cnt = 1 To Budget.PageHeight Do
		BudgetArea = Budget.Area(Cnt, 1);
		Details = MatchingTranscripts[BudgetArea.Details];
		If TypeOf(Details) = Type("Structure") 
			And Details.Property("GroupingID", GroupingID)
			And GroupingID = SearchRow Then
			
			Return BudgetArea.Top;
			
		EndIf;
	EndDo;
	
	Return Undefined
	
EndFunction

&AtServer
Procedure SetPage()
	
	If Items.PanelBudget.CurrentPage = Items.List Then
		Items.PanelBudget.CurrentPage = Items.Table;
		GenerateReportServer(True);
	Else
		Items.PanelBudget.CurrentPage = Items.List;
	EndIf;
	
	SetAccessibilityOfButtonsWhenChangingPage();
	
EndProcedure

&AtClient
Procedure SetInputListParameters(ManageVisibilityOfElementTree = True)
	
	If Items.PanelBudget.CurrentPage <> Items.List Then
		Return;
	EndIf;
	
	If Items.BudgetItemTree.CurrentRow <> PreviousLineOfItemTree Then
		SetInputListParametersOnServer(False);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessingActivationOfElementTreeRow()
	
	SetInputListParameters(False);
	
EndProcedure

&AtClient
Procedure AddNote(Command)
	
	ActiveArea = Items.Budget.CurrentArea;
	Note = Undefined;
	For Column = ActiveArea.Left To ActiveArea.Right Do
		For String = ActiveArea.Top To ActiveArea.Bottom Do
			If Note = Undefined Then
				Note = Budget.Area(String, Column).Comment.Text;
			Else
				NewNote = Budget.Area(String, Column).Comment.Text;
				If NewNote <> Note Then
					Note = "";
					Break;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	Notification = New CallbackDescription("NoteCompletingInput", ThisObject);
	ToolTipText = NStr("vi = 'Ghi chú';
						|ru = 'Примечание';
						|en = 'Note'; fa = 'یادداشت';
						|it = 'Nota';
						|pl = 'Adnotacja';
						|tr = 'Not'");
	ShowInputString(Notification, Note, ToolTipText, 500, True);
	
EndProcedure

&AtClient
Procedure RemoveTheNote(Command)
	
	DeleteNoteOnServer();
	
EndProcedure

&AtClient
Procedure NoteCompletingInput(Val EnteredText, Val AdditionalParameters) Export
	
	If EnteredText = Undefined Then
		Return;
	EndIf;
	
	NoteCompletingInputOnServer(EnteredText);
	Modified = True;
	
EndProcedure

&AtServer
Procedure NoteCompletingInputOnServer(EnteredText)
	
	ActiveArea = Items.Budget.CurrentArea;
	For Column = ActiveArea.Left To ActiveArea.Right Do
		For String = ActiveArea.Top To ActiveArea.Bottom Do
			Area = Budget.Area(String, Column);
			If Area.ContainsValue Then
				Details = BudgetReportingServerCall.DetailsValue(Area.Details, DetailsDataAddress);
				ReflectionResult = ReflectCellChange(Details, Area.Text, EnteredText);
				Area.Comment.Text = EnteredText;
				
				AreaName = Area.Name; 
				If TypeOf(AddressOfCellData) = Type("String") Then
					CellData_ = GetFromTempStorage(AddressOfCellData); // See BudgetReportingDisplayServer.GetSelectionOfCellsHierarchically.CellData_
				Else
					CellData_ = AddressOfCellData; // See BudgetReportingDisplayServer.GetSelectionOfCellsHierarchically.CellData_
				EndIf;
				
				If TypeOf(AreaName) = Type("String") Then
					
					CalculationLine = CellData_.Find(AreaName, "AreaNameSum");
					
					If CalculationLine = Undefined Then
						CalculationLine = CellData_.Find(AreaName, "AreaNameCount");
					EndIf;
					
					If CalculationLine = Undefined Then
						CalculationLine = CellData_.Find(AreaName, "AreaNameValue");
					EndIf;
					
					If Not CalculationLine = Undefined Then
						If ReflectionResult.Property("Note") Then
							CalculationLine.Note = ReflectionResult.Note;
						EndIf;
					EndIf;
				EndIf;
				
				PutToTempStorage(CellData_, AddressOfCellData);
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Procedure DeleteNoteOnServer()
	
	NoteCompletingInputOnServer("");
	Modified = True;
	
EndProcedure

&AtClient
Procedure ShouldRecalculate(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.BudgetEntryForm.DocumentForm.Command.ShouldRecalculate",,
		True);
	
	RecalculateAtServer();
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	ClearMessages();
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	If Object.Action = Enums.TypesOfBudgetEntryFormActions.AdjustByBudgetFlowItems Then
		CheckedAttributes.Add("AdjustmentsByBudgetItems");
		CheckedAttributes.Add("AdjustmentsByBudgetItems.BudgetFlowItem");
		CheckedAttributes.Add("AdjustmentsByBudgetItems.PlanningPeriod");
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit = True Then
		OnCloseAtServer(JobID,Object.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure BudgetSelection(Item, Area, StandardProcessing)
	
	If Area.ContainsValue Then
		If Not Items.Budget.Edit Then
			StandardProcessing = False;
		EndIf;
		Return;
	EndIf;
	
	Details = Area.Details;
	If Details = Undefined Then
		Return;
	EndIf;
	
	Details = BudgetReportingServerCall.DetailsValue(Area.Details, DetailsDataAddress);
	
	If TypeOf(Details) <> Type("Structure") Then
		Return;
	EndIf;
	
	If Details.Property("DataLineIndex") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	If Details.Property("Value") And ValueIsFilled(Details.Value) Then
		ShowValue(,Details.Value);
		Return;
	EndIf;
	
	AreaCells = CellsOfAreaToEdit(Area);
	
	RowsArray = AreaCells.RowsArray;
	
	If Not RowsArray.Count() Then
		Return;
	EndIf;
	
	EditParameters = StringEditingOptions(RowsArray, BudgetProfileDisplayParameters, True);	
	EditParameters = ConvertEditParametersToStructure(EditParameters, RowsArray, Area.Top);
	
	If EditParameters <> Undefined Then
		StandardProcessing = False;
		If Not Items.Budget.Edit Then
			Return;
		EndIf;
		AddRowInTableMode(EditParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowHideBudgetTree(Command)
	
	Items.ShowHideBudgetTree.Check = Not Items.ShowHideBudgetTree.Check;
	Items.BudgetItemTree.Visible = Items.ShowHideBudgetTree.Check;
	
	If Items.BudgetItemTree.Visible Then
		AttachIdleHandler("Attachable_ExpandTreeOfBudgetItems", 1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExpandTreeOfBudgetItems()
	
	TreeItems = BudgetItemTree.GetItems();
	For Each TreeRow In TreeItems Do
		Items.BudgetItemTree.Expand(TreeRow.GetID(), True);
	EndDo;
	
EndProcedure

&AtClient
Procedure AddRow(Command)
	
	AreaCells = CellsOfAreaToEdit(Budget.CurrentArea);
	RowsArray = AreaCells.RowsArray;
	If Not RowsArray.Count() Then
		Return;
	EndIf;
	
	EditParameters = AddRowAtServer(RowsArray, BudgetProfileDisplayParameters);
	
	EditParameters = ConvertEditParametersToStructure(EditParameters,
			RowsArray,
			Budget.CurrentArea.Top);
	If EditParameters <> Undefined Then
		AddRowInTableMode(EditParameters);
	Else
		WarningText = NStr("vi = 'Các giao dịch không có sẵn, chỉ số không chuẩn.';
							|ru = 'Операция не доступна, аналитика не динамическая.';
							|en = 'The operation is not available, dimension is not dynamic.'; fa = 'The operation is not available, dimension is not dynamic.';
							|it = 'L''operazione non è possibile, l''analitica non è dinamica.';
							|pl = 'Operacja nie jest dostępna, analityka nie są dynamiczna.';
							|tr = 'Operasyon kullanılamıyor, boyut dinamik değil.'");
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteRow(Command)
	
	AreaCells = CellsOfAreaToEdit(Budget.CurrentArea);
	RowsArray = AreaCells.RowsArray;
	ArrayOfAreas = AreaCells.ArrayOfAreas;
	If Not RowsArray.Count() Then
		Return;
	EndIf;
	
	SetLabelForUpdatingTotals(True);
	
	ShowItemHierarchy = False;
	SubordinateRows = GetSubordinateStrings(RowsArray, , ShowItemHierarchy);
	If SubordinateRows.Count() > 0 Then
		Area = Budget.CurrentArea;
		For String = Area.Bottom + 1 To Budget.TableHeight Do
			Column = Area.Right;
			BudgetArea = Budget.Area(String, Column);
			SubordinateAreaCells = CellsOfAreaToEdit(BudgetArea);
			ArrayOfSubordinateStrings = SubordinateAreaCells.RowsArray;
			ArrayOfSubordinateAreas = SubordinateAreaCells.ArrayOfAreas;
			AbortSearch = False;
			For Each Page1 In ArrayOfSubordinateStrings Do
				If SubordinateRows.Find(Page1) = Undefined Then
					AbortSearch = True;
				EndIf;
			EndDo;
			If Not AbortSearch Then
				CommonClientServer.SupplementArray(RowsArray, ArrayOfSubordinateStrings);
				CommonClientServer.SupplementArray(ArrayOfAreas, ArrayOfSubordinateAreas);
			Else
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	MatchingTranscripts = New Array;
	AreaNames = New Array;
	For Each BudgetArea In ArrayOfAreas Do
		
		For Cnt = 2 To Budget.TableWidth Do
			ValueArea = Budget.Area(BudgetArea.Bottom, Cnt);
			MatchingTranscripts.Add(ValueArea.Details);
			AreaNames.Add(ValueArea.Name);
		EndDo;
		
	EndDo;
	
	NumberOfSubordinateRowsInHierarchy = 0;
	
	If ShowItemHierarchy Then
		SubordinateBudgetAreas = New Map;
		AddSubordinateAreasInHierarchy(AreaNames, SubordinateBudgetAreas);
		For Each SubordinateArea In SubordinateBudgetAreas Do
			Area = Budget.Area("R" + SubordinateArea.Key + "C1:R" + SubordinateArea.Key + "C" + SubordinateArea.Value);
			
			SubordinateAreaCells = CellsOfAreaToEdit(Area);
			ArrayOfSubordinateBudgetLines = SubordinateAreaCells.RowsArray;
			ArrayOfSubordinateBudgetAreas = SubordinateAreaCells.ArrayOfAreas;
			If Not ArrayOfSubordinateBudgetLines.Count() Then
				Continue;
			EndIf;
			
			SubordinateRows = GetSubordinateStrings(ArrayOfSubordinateBudgetLines);
			If SubordinateRows.Count() > 0 Then
				For String = Area.Bottom + 1 To Budget.TableHeight Do
					Column = Area.Right;
					BudgetArea = Budget.Area(String, Column);
					SubordinateAreaCells = CellsOfAreaToEdit(BudgetArea);
					ArrayOfSubordinateStrings = SubordinateAreaCells.RowsArray;
					ArrayOfSubordinateAreas = SubordinateAreaCells.ArrayOfAreas;
					AbortSearch = False;
					For Each Page1 In ArrayOfSubordinateStrings Do
						If SubordinateRows.Find(Page1) = Undefined Then
							AbortSearch = True;
						EndIf;
					EndDo;
					If Not AbortSearch Then
						CommonClientServer.SupplementArray(ArrayOfSubordinateBudgetLines, ArrayOfSubordinateStrings);
						CommonClientServer.SupplementArray(ArrayOfSubordinateBudgetAreas, ArrayOfSubordinateAreas);
					Else
						Break;
					EndIf;
				EndDo;
			EndIf;
			
			For Each BudgetArea In ArrayOfSubordinateBudgetAreas Do
				
				For Cnt = 2 To Budget.TableWidth Do
					ValueArea = Budget.Area(BudgetArea.Bottom, Cnt);
					MatchingTranscripts.Add(ValueArea.Details);
				EndDo;
				
			EndDo;
			
			NumberOfSubordinateRowsInHierarchy = NumberOfSubordinateRowsInHierarchy + ArrayOfSubordinateBudgetLines.Count();
			
			CommonClientServer.SupplementArray(RowsArray, ArrayOfSubordinateBudgetLines);
			CommonClientServer.SupplementArray(ArrayOfAreas, ArrayOfSubordinateBudgetAreas);
			
		EndDo;
	EndIf;
	
	MatchingTranscripts = BudgetReportingServerCall.DetailsValue(MatchingTranscripts, DetailsDataAddress);
	
	ArrayOfDecryptionsByLines = New Array;
	For Each BudgetArea In ArrayOfAreas Do
		
		ArrayOfDecryptions = New Array;
		For Cnt = 2 To Budget.TableWidth Do
			ValueArea = Budget.Area(BudgetArea.Bottom, Cnt);
			Details = MatchingTranscripts[ValueArea.Details];
			If TypeOf(Details) = Type("Structure") Then
				If Details.Property("BudgetFlowItem")
					Or Details.Property("BudgetBalanceItem") 
					Or Details.Property("EditedValue") Then
					ArrayOfDecryptions.Add(Details);
				EndIf;
			EndIf;
		EndDo;
		ArrayOfDecryptionsByLines.Add(New Structure("LineNumber, ArrayOfDecryptions", BudgetArea.Bottom, ArrayOfDecryptions));
	EndDo;
	
	WeNeedToContinueSorting = True;
	While WeNeedToContinueSorting Do
		WeNeedToContinueSorting = False;
		For Cnt = 0 To ArrayOfDecryptionsByLines.UBound() - 1 Do
			If ArrayOfDecryptionsByLines[Cnt].LineNumber < ArrayOfDecryptionsByLines[Cnt + 1].LineNumber Then
				WeNeedToContinueSorting = True;
				
				CurValue_ = RowsArray[Cnt];
				RowsArray[Cnt] = RowsArray[Cnt + 1];
				RowsArray[Cnt + 1] = CurValue_;
				
				CurValue_ = ArrayOfDecryptionsByLines[Cnt];
				ArrayOfDecryptionsByLines[Cnt] = ArrayOfDecryptionsByLines[Cnt + 1];
				ArrayOfDecryptionsByLines[Cnt + 1] = CurValue_;
				
			EndIf;
		EndDo;
	EndDo;
	
	DeletedLines = 0;
	DeleteRowOnServer(RowsArray, ArrayOfDecryptionsByLines, BudgetProfileDisplayParameters, DeletedLines, NumberOfSubordinateRowsInHierarchy);
	If DeletedLines = 0 Then
		WarningText = NStr("vi = 'Không thể xóa các dòng đã chọn.';
							|ru = 'Нельзя удалить выбранные строки.';
							|en = 'Cannot delete the selected lines.'; fa = 'Cannot delete the selected lines.';
							|it = 'Impossibile eliminare le righe selezionate.';
							|pl = 'Nie można usunąć wybranych wierszy';
							|tr = 'Seçilen satırlar silinemez.'");
		ShowMessageBox(, WarningText);
	EndIf;
	
	RunChangeCalculationCheck();
	
EndProcedure

&AtServer
Function GetSubordinateStrings(RowsArray, Val ItemsTree=Undefined, ShowItemHierarchy = False)
	
	FirstIteration = False;
	If ItemsTree = Undefined Then
		ItemsTree = GetFromTempStorage(BudgetProfileDisplayParameters).OutputTree;
		FirstIteration = True;
	EndIf;
	
	ArrayOfSubordinateStrings = New Array();
	
	For Cnt = 0 To RowsArray.UBound() Do
		
		ArrayElement = RowsArray[Cnt];
		
		If TypeOf(ArrayElement) = Type("ValueTreeRow") Then
			TreeItem = ArrayElement;
		Else
			TreeItem = Undefined;
			FoundRows = ItemsTree.Rows.FindRows(New Structure("ReportItem", ArrayElement), True);
			If FoundRows.Count() Then
				TreeItem = FoundRows[0];
			Else
				Continue;
			EndIf;
		EndIf;
		
		If FirstIteration And Not ShowItemHierarchy Then
			ShowItemHierarchy = TreeItem.ShowItemHierarchy;
		EndIf;
		
		For Each Page1 In TreeItem.Rows Do
			If ValueIsFilled(Page1.ReportItem) Then
				ArrayOfSubordinateStrings.Add(Page1.ReportItem);
			EndIf;
			ArrayOfStringsToAdd = New Array;
			ArrayOfStringsToAdd.Add(Page1);
			PortionOfSubordinateStrings = GetSubordinateStrings(ArrayOfStringsToAdd, ItemsTree);
			CommonClientServer.SupplementArray(ArrayOfSubordinateStrings, PortionOfSubordinateStrings);
		EndDo;
		
	EndDo;
	
	Return ArrayOfSubordinateStrings;
	
EndFunction

// StandardSubsystems.Properties

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Function PrepareParametersForBudgetViewOutput()
	
	ParametersStructure = BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView(
		Object.BudgetProfile, Enums.ModesOfBudgetReportGeneration.Document);
		
	BudgetProfileDisplayParameters = PutToTempStorage(ParametersStructure, UUID);
	
	AddressOfCellData = PutToTempStorage(Undefined, UUID);
	StorageAddress = PutToTempStorage(Undefined, UUID);
	AddressOfLineEditingParameters = PutToTempStorage(Undefined, UUID);
	AddressOfEditedValuesOfListLine = PutToTempStorage(Undefined, UUID);
	
	ThereIsPeriodicity = False;
	If ParametersStructure <> Undefined Then
		ThereIsPeriodicity = ParametersStructure.ColumnStructureOfDataTable.Periodicity_.Count();
	EndIf;
	Items.CopyByPeriods.Visible = ThereIsPeriodicity;
	Items.BudgetContextMenuCopyByPeriods.Visible = ThereIsPeriodicity;
	Items.BudgetEditListContextMenuCopyByPeriods.Visible = ThereIsPeriodicity;
	
	Return ParametersStructure;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	ReflectionResult - Structure - LongDesc:
// * Note - String, Undefined -
// * Sum - Number -
// * AmountInCurrency - Number -
// * Count - Number -
// * Value - Number -
// 	Details - Map of KeyAndValue, Undefined - LongDesc:
// *Key - DataCompositionDetailsID, Number -
// *Value - DataCompositionFieldDetailsItem, DataCompositionGroupDetailsItem -
// 	AreaName - String - LongDesc
// Returns:
// 	Structure - LongDesc:
// * Details - Undefined -
// * Details - Map of KeyAndValue - :
// ** Key - DataCompositionDetailsID, Number -
// ** Value - DataCompositionFieldDetailsItem, DataCompositionGroupDetailsItem -
// * Details - Structure - :
// ** String - CatalogRef.FinancialReportItems - Budget line.
// * StorageAddress - String -
// * ReflectionResult - Structure -:
// ** Note - String, Undefined -
// ** Sum - Number -
// ** AmountInCurrency - Number -
// ** Count - Number -
// ** Value - Number -
// * AreaName - String -
// * AddressOfCellData - String -
// * BudgetProfileDisplayParameters - String -
// * ReportParameters - See BudgetReportingClientServer.PeriodParameters_
// * DetailsDataAddress - String - 
// * AddressOfExchangeRateTable - String -
// * RequireExchangeRatesSpecificationForEachPeriod - Boolean - 
// * ItemParameterCache - See BudgetingServer.FillCacheOfArticleParameters
// * ScenarioCurrency - CatalogRef.Currencies - 
// * Object - FormDataStructure - 
&AtClient
Function ParametersOfNonContextCall(ReflectionResult, Details, AreaName)
	
	CalculationParameters = BudgetReportingClientServer.ObjectStructureForCellCalculation();
	CalculationParameters.ScenarioCurrency 							= ScenarioCurrency;
	CalculationParameters.ItemParameterCache 						= ItemParameterCache;
	CalculationParameters.RequireExchangeRatesSpecificationForEachPeriod	= RequireExchangeRatesSpecificationForEachPeriod;
	CalculationParameters.AddressOfExchangeRateTable 						= AddressOfExchangeRateTable;
	CalculationParameters.BudgetProfileDisplayParameters					= BudgetProfileDisplayParameters;
	CalculationParameters.Insert("ReportParameters", 				BudgetReportingClientServer.PeriodParameters_(Object));
	CalculationParameters.Insert("AddressOfCellData", 				AddressOfCellData);
	If StrFind(AreaName, ":") > 0 Then
		ArrayOfAreaNames = New Array;
		BudgetArea = Budget.Area(AreaName);
		For LineNumber = BudgetArea.Top To BudgetArea.Bottom Do
			For ColumnNumber = BudgetArea.Left To BudgetArea.Right Do
				ArrayOfAreaNames.Add(StringFunctionsClientServer.SubstituteParametersToString("R%1C%2", Format(LineNumber,
					"NG=0"), Format(ColumnNumber, "NG=0")));
			EndDo;
		EndDo;
		CalculationParameters.Insert("AreaName", 				StrConcat(ArrayOfAreaNames, ";"));
	Else
		CalculationParameters.Insert("AreaName", 				AreaName);
	EndIf;
	CalculationParameters.Insert("ReflectionResult", 			ReflectionResult);
	CalculationParameters.Insert("StorageAddress", 				StorageAddress);
	CalculationParameters.Insert("Details", 					Details);
	
	Return CalculationParameters;
	
EndFunction

&AtServerNoContext
Function BudgetWhenServerChanges(ParametersOfNonContextCall)
	
	AreaName = ParametersOfNonContextCall.AreaName;
	If StrFind(AreaName, ";") > 0 Then
		ArrayOfAreaNames = StringFunctionsClientServer.SplitStringIntoSubstringsArray(AreaName, ";");
	Else
		ArrayOfAreaNames = CommonClientServer.ValueInArray(AreaName);
	EndIf;
	
	ResultForReflectionOnClient = New Array;
	
	For Each AreaName In ArrayOfAreaNames Do
		
		ExecutionResult = BudgetReportingDisplayServer.CalculateRelatedBudgetItems(
			ParametersOfNonContextCall.BudgetProfileDisplayParameters,
			ParametersOfNonContextCall.AddressOfCellData, 
			ParametersOfNonContextCall.ReportParameters,
			AreaName, 
			ParametersOfNonContextCall.ReflectionResult);
		
		If ExecutionResult = Undefined Then
			Continue;
		EndIf;
		
		For Each ResultString1 In ExecutionResult.Result Do
			ResultForReflectionOnClient.Add(Common.ValueTableRowToStructure(ResultString1));
		EndDo;
		
		PutToTempStorage(ExecutionResult.BudgetProfileDisplayParameters, ParametersOfNonContextCall.BudgetProfileDisplayParameters);
		PutToTempStorage(ExecutionResult.CellData_, ParametersOfNonContextCall.AddressOfCellData);
		
	EndDo;
	
	If ResultForReflectionOnClient.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	Return ResultForReflectionOnClient;
	
EndFunction

&AtServer
Procedure BudgetWhenChangingServerAutoRecalculation(ParametersOfNonContextCall)
	
	CalculationResult2 = BudgetWhenServerChanges(ParametersOfNonContextCall);
	If CalculationResult2 <> Undefined Then
		ObjectAndCalculationParameters = BudgetReportingClientServer.StructureByBudgetInstanceObject(ThisObject);
		LoadResultOfCalculatingChangesOnClient(ObjectAndCalculationParameters, Budget, CalculationResult2);
	EndIf;
	
	ReflectBudgetChanges( , CommonClientServer.ValueInArray(ParametersOfNonContextCall.Details.String),
				ParametersOfNonContextCall.Details);
	
EndProcedure

&AtClientAtServerNoContext
Procedure LoadResultOfCalculatingChangesOnClient(ObjectAndCalculationParameters, Budget, CalculationResult2)
	
	ElementStructure_ = True;
	If TypeOf(CalculationResult2) <> Type("Array") Then
		ElementStructure_ = False;
		ThereIsDecryption = CalculationResult2.Columns.Find("Details") <> Undefined;
	EndIf;
	
	For Each Update In CalculationResult2 Do
		
		Value = ?(ValueIsFilled(Update.Value), Update.Value, Undefined);
		
		If ElementStructure_ Then
			ThereIsDecryption = Update.Property("Details");
		EndIf;
		
		If ThereIsDecryption Then
			BudgetReportingClientServer.ReflectCellChange(ObjectAndCalculationParameters, Update.Details, Value);
			If ValueIsFilled(Update.AreaName) Then
				Area = Budget.Area(Update.AreaName);
				If Area.ContainsValue Then
					Area.Value = Value;
				Else
					Area.Text = Value;
				EndIf;
			EndIf;
		Else
			Area = Budget.Area(Update.AreaName);
			If Area.ContainsValue Then
				Area.Value = Value;
				Details = BudgetReportingServerCall.DetailsValue(Area.Details,
							ObjectAndCalculationParameters.DetailsDataAddress);
				BudgetReportingClientServer.ReflectCellChange(ObjectAndCalculationParameters, Details, Value);
			Else
				Area.Text = Value;
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure RestoreCellSizes()
	
	ColumnWidth_ = FormDataSettingsStorage.Load(FormName, "ColumnWidth__" + Object.Ref.UUID());
	
	If ColumnWidth_ <> Undefined Then 
		For ColumnNumber = 1 To ColumnWidth_.Count() Do
			ColumnWidth = ColumnWidth_.Get(ColumnNumber - 1).Value;
			Budget.Area(, ColumnNumber, , ColumnNumber).ColumnWidth = ColumnWidth;
		EndDo;
	EndIf;
	
	RowHeight = FormDataSettingsStorage.Load(FormName, "RowHeight_" + Object.Ref.UUID());
	
	If RowHeight <> Undefined Then
		For LineNumber = 1 To RowHeight.Count() Do
			RowHeight = RowHeight.Get(LineNumber - 1).Value;
			If RowHeight <> 0 Then
				VariableString = Budget.Area(LineNumber, , LineNumber, );
				VariableString.AutoRowHeight = False;
				VariableString.RowHeight = RowHeight;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function StringEditingOptions(RowsArray, AddressOfBudgetTypeParameters, Create)
	
	ItemsTree = GetFromTempStorage(AddressOfBudgetTypeParameters).OutputTree;
	Result = New Map;
	
	For Each CurrentRow In RowsArray Do
		
		ParametersOfLineToEdit = ItemsTree.Rows.Find(CurrentRow, "ReportItem", True);
		
		FirstRow = ParametersOfLineToEdit;
		While FirstRow.DisplayWithParent Do
			FirstRow = FirstRow.Parent;
		EndDo;
		
		ArrayOfAnalyticsTypes = New Array;
		While True Do
			If FirstRow.EditedValues Then
				ArrayOfAnalyticsTypes.Add(FirstRow.DimensionKind);
			EndIf;
			If Not FirstRow.OutputTogetherWithSubordinate Then
				Break;
			EndIf;
			FirstRow = FirstRow.Rows[0];
		EndDo;
		
		If ArrayOfAnalyticsTypes.Count() Then
			Result.Insert(FirstRow.ReportItem, ArrayOfAnalyticsTypes);
			If Create Then
				Return Result;
			EndIf;
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Function CellsOfAreaToEdit(Area)
	
	MatchingTranscripts = New Array;
	For String = Area.Top To Area.Bottom Do
		For Column = 1 To Area.Right Do
			BudgetArea = Budget.Area(String, Column);
			Details = BudgetArea.Details;
			MatchingTranscripts.Add(Details);
		EndDo;
	EndDo;
	
	MatchingTranscripts = BudgetReportingServerCall.DetailsValue(MatchingTranscripts, DetailsDataAddress);
	
	RowsArray = New Array;
	ArrayOfAreas = New Array;
	
	For String = Area.Top To Area.Bottom Do
		For Column = 1 To Area.Right Do
			BudgetArea = Budget.Area(String, Column);
			Details = MatchingTranscripts[BudgetArea.Details]; // Structure - 
			If TypeOf(Details) <> Type("Structure") Then
				Continue;
			EndIf;
			If Details.Property("Column") Then
				Break;
			EndIf;
			If Details.Property("String") Then
				RowsArray.Add(Details["String"]);
				ArrayOfAreas.Add(BudgetArea);
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	Return New Structure("RowsArray, ArrayOfAreas", RowsArray, ArrayOfAreas);
	
EndFunction

&AtServer
Procedure AddSubordinateAreasInHierarchy(AreaNames, SubordinateBudgetAreas, CellData_ = Undefined)

	FirstIteration = False;
	If CellData_ = Undefined Then
		CellData_ = GetFromTempStorage(AddressOfCellData);
		FirstIteration = True;
	EndIf;
	
	NamesOfSubordinateCells = New Array;
	
	TypesOfResourceAreas = New Array;
	TypesOfResourceAreas.Add("AreaNameSum");
	TypesOfResourceAreas.Add("AreaNameCount");
	TypesOfResourceAreas.Add("AreaNameValue");
	
	TheStructureOfTheSearch = New Structure;
	
	For Each AreaName In AreaNames Do
		If StrFind(AreaName, ":") > 0 Then
			Continue;
		EndIf;
		For Each ResourceAreaView In TypesOfResourceAreas Do
			TheStructureOfTheSearch.Clear();
			TheStructureOfTheSearch.Insert(ResourceAreaView + "Hierarchy", AreaName);
			CellDataRows = CellData_.FindRows(TheStructureOfTheSearch);
			For Each CellDataString In CellDataRows Do
				NameOfSubordinateCell = CellDataString[ResourceAreaView];
				NamesOfSubordinateCells.Add(NameOfSubordinateCell);
				AddressArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(StrReplace(NameOfSubordinateCell, "R", ""), "C");
				ColumnNumber = StrReplace(AddressArray[1], "C", "");
				RightBorderOfRegion = SubordinateBudgetAreas.Get(AddressArray[0]);
				If RightBorderOfRegion = Undefined
					Or Number(RightBorderOfRegion) < Number(ColumnNumber) Then
					SubordinateBudgetAreas.Insert(AddressArray[0], ColumnNumber);
				EndIf;
			EndDo;
		EndDo;
		AddSubordinateAreasInHierarchy(NamesOfSubordinateCells, SubordinateBudgetAreas, CellData_);
	EndDo;
	
	If FirstIteration Then
		CellData_ = Undefined;
	EndIf;

EndProcedure

// LongDesc
// 
// Parameters:
// 	ReportRow - Undefined, ValueTreeRow -
// 	ArrayOfSubordinateElements - Array of CatalogRef.FinancialReportItems -
// 	InitialIndex - Number, Undefined -
&AtServerNoContext
Procedure FillInSubordinateElementsRecursively(ReportRow, ArrayOfSubordinateElements, InitialIndex = Undefined)
	
	For Each TreeRow In ReportRow.Rows Do
		If InitialIndex <> Undefined Then
			If ReportRow.Rows.IndexOf(ReportRow) <= InitialIndex Then
				Continue;
			EndIf;
		EndIf;
		ArrayOfSubordinateElements.Add(TreeRow.ReportItem);
		FillInSubordinateElementsRecursively(TreeRow, ArrayOfSubordinateElements)
	EndDo;
	
EndProcedure

&AtServerNoContext
Function AddRowAtServer(RowsArray, AddressOfBudgetTypeParameters)
	
	ItemsTree =
		GetFromTempStorage(AddressOfBudgetTypeParameters).OutputTree; // ValueTree
	
	EditParameters = StringEditingOptions(RowsArray, AddressOfBudgetTypeParameters, True);
	If Not EditParameters.Count() Then
		For Each CurrentRow In RowsArray Do
			ReportRow = ItemsTree.Rows.Find(CurrentRow, "ReportItem", True);
			ArrayOfSubordinateElements = New Array;
			FillInSubordinateElementsRecursively(ReportRow, ArrayOfSubordinateElements);
			EditParameters = StringEditingOptions(ArrayOfSubordinateElements, AddressOfBudgetTypeParameters, True);
			If EditParameters.Count() Then
				Break;
			EndIf;
			RowParent = ReportRow.Parent;
			FillInSubordinateElementsRecursively(RowParent, ArrayOfSubordinateElements, RowParent.Rows.IndexOf(ReportRow));
			EditParameters = StringEditingOptions(ArrayOfSubordinateElements, AddressOfBudgetTypeParameters, True);
			If EditParameters.Count() Then
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return EditParameters;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	RowsArray - Array of CatalogRef.FinancialReportItems - LongDesc
// 	ArrayOfDecryptionsByLines - Array of Structure - array of decryption values:
// 	 *LineNumber - Number - Line number.
// 	AddressOfBudgetTypeParameters - String - Address of the temporary storage of budget view parameters.
//  DeletedLines - Number - number of rows to delete
//  NumberOfSubordinateRowsInHierarchy - Number - The Number Of Subordinate Rows In The Hierarchy
&AtServer
Procedure DeleteRowOnServer(RowsArray, ArrayOfDecryptionsByLines, AddressOfBudgetTypeParameters, DeletedLines, NumberOfSubordinateRowsInHierarchy)
	
	ObjectAndCalculationParameters = BudgetReportingClientServer.StructureByBudgetInstanceObject(ThisObject);
	CellData_ = GetFromTempStorage(AddressOfCellData);
	ItemsTree = GetFromTempStorage(AddressOfBudgetTypeParameters).OutputTree;
	
	MinimumRowToDelete = Undefined;
	
	TypesOfResourceAreas = New Array;
	TypesOfResourceAreas.Add("AreaNameSum");
	TypesOfResourceAreas.Add("AreaNameCount");
	TypesOfResourceAreas.Add("AreaNameValue");
	
	ShowItemHierarchy = False;
	
	For Cnt = 0 To RowsArray.UBound() Do
		
		ArrayElement = RowsArray[Cnt];
		
		FoundRows = ItemsTree.Rows.FindRows(New Structure("ReportItem", ArrayElement), True);
		If FoundRows.Count() > 0 And Not ShowItemHierarchy Then
			ShowItemHierarchy = FoundRows[0].ShowItemHierarchy;
		EndIf;
		YouCanDeleteLine = Not (FoundRows.Count() > 0 And FoundRows[0].Rows.Count() > 0)
			And RowsArray.Count() - NumberOfSubordinateRowsInHierarchy = 1;
		If YouCanDeleteLine Then
			YouCanDeleteLine = Not ValueIsFilled(ArrayElement.DimensionValue);
		EndIf;
		
		RowDescription = ArrayOfDecryptionsByLines[Cnt];
		ArrayOfDecryptions = RowDescription.ArrayOfDecryptions;
		
		EditParameters = StringEditingOptions(
					CommonClientServer.ValueInArray(ArrayElement),
					AddressOfBudgetTypeParameters,
					False);
		AnalystValues = Undefined;
		For Each KeyAndValue In EditParameters Do
			AnalystValues = KeyAndValue.Value;
			Break;
		EndDo;
		
		If AnalystValues = Undefined And ArrayOfDecryptions.Count() > 0 And FoundRows.Count() > 0 Then
			If ArrayOfDecryptions[0].Property("AnalystValues") And ArrayOfDecryptions[0].AnalystValues.Count()
				> 0 Then
				AnalystValues = New Array();
				For Each KeyValue In ArrayOfDecryptions[0].AnalystValues Do
					AnalystValues.Add(KeyValue.Key);
				EndDo;
			EndIf;
			If FoundRows[0].ItemKind = Enums.FinancialReportItemKinds.Dimension 
					And StrFind(FoundRows[0].DimensionName, "Period") Then
				YouCanDeleteLine = False;
			EndIf;
		EndIf;
		
		If AnalystValues = Undefined Then
			Continue;
		EndIf;
		
		IsBlankRow = False;
		For Each Details In ArrayOfDecryptions Do
			
			If Not IsBlankRow Then
				ThereAreCompletedAnalytics = False;
				For Each ViewOfEditedAnalytics In AnalystValues Do
					If ValueIsFilled(Details.AnalystValues[ViewOfEditedAnalytics]) Then
						ThereAreCompletedAnalytics = True;
						Break;
					EndIf;
				EndDo;
				If Not ThereAreCompletedAnalytics Then
					IsBlankRow = True;
				EndIf;
			EndIf;
			
			BudgetReportingClientServer.ReflectCellChange(ObjectAndCalculationParameters, Details, 0, "");
			TheStructureOfTheSearch = New Structure("String, Column");
			If Details.Property("BudgetFlowItem") Then
				TheStructureOfTheSearch.Insert("BudgetFlowItem");
			EndIf;
			For Each PeriodicityValue In Enums.Periodicity Do
				PeriodAsString = FinancialReportingClientServer.PeriodStrings(PeriodicityValue).Period;
				If Details.Property(PeriodAsString) Then
					TheStructureOfTheSearch.Insert(PeriodAsString);
				EndIf; 
			EndDo;
			FillPropertyValues(TheStructureOfTheSearch, Details);
			For Each DimensionValue In Details.AnalystValues Do
				TheStructureOfTheSearch.Insert(
					FinancialReportingCached.NameOfBudgetReportField(DimensionValue.Key), DimensionValue.Value);
			EndDo;
			
			FoundRows = CellData_.FindRows(TheStructureOfTheSearch);
			For Each FoundRow In FoundRows Do
				If IsBlankRow Or Not YouCanDeleteLine Then
					For Each ResourceAreaView In TypesOfResourceAreas Do
						AreaName = "";
						If ValueIsFilled(FoundRow[ResourceAreaView]) Then
							AreaName = FoundRow[ResourceAreaView];
						EndIf;
						If ValueIsFilled(AreaName) Then
							If Budget.Area(AreaName).Protection Then
								Budget.Area(AreaName).Text = "";
							Else
								Budget.Area(AreaName).Value = Undefined;
							EndIf;
						EndIf;
					EndDo;
					
					FoundRow.Sum = Undefined;
					FoundRow.SumCurr = Undefined;
					FoundRow.Count = Undefined;
					FoundRow.Value = Undefined;
				Else
					CellData_.Delete(FoundRow);
				EndIf;
			EndDo;
			
		EndDo;
		
		If Not IsBlankRow And YouCanDeleteLine Then
			
			If MinimumRowToDelete = Undefined Then
				MinimumRowToDelete = RowDescription.LineNumber;
			Else
				MinimumRowToDelete = Min(MinimumRowToDelete, RowDescription.LineNumber);
			EndIf;
			DeletedLines = DeletedLines + 1;
			AreaToDelete_ = Budget.Area(RowDescription.LineNumber, , RowDescription.LineNumber);
			Budget.DeleteArea(AreaToDelete_, SpreadsheetDocumentShiftType.Vertical);
		
		EndIf;
		
		// In the columns of the Group view, the suspended cell data that was not deleted in the previous step remains.
		If Not IsBlankRow And YouCanDeleteLine Then
			StructureOfOutputParameters = GetFromTempStorage(BudgetProfileDisplayParameters); // See BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView
			StructureOfReportDescription = StructureOfOutputParameters.StructureOfReportDescription;
			
			EndString = FinalLineOfOutputTree(ArrayElement, StructureOfReportDescription.TableOfSubordinationOfElements);
			If Not ValueIsFilled(EndString) Then
				ErrorText = NStr("vi = 'Lỗi trong cấu trúc của loại ngân sách';
								|ru = 'Ошибка в структуре вида бюджета';
								|en = 'Error in the budget profile structure'; fa = 'Error in the budget profile structure';
								|it = 'Errore nella struttura della tipologia di budget';
								|pl = 'Błąd w strukturze typu budżetu';
								|tr = 'Bütçe profili yapısında hata'");
				Raise ErrorText;
			EndIf;
			CellStructure = StructureOfReportDescription.CellStructure;
			FoundRows = CellStructure.FindRows(New Structure("MainItem, String", True, EndString));
			
			DimensionStructure = New Structure;
			For Each Details In ArrayOfDecryptions Do
				AnalyticsFilledIn_ = False;
				For Each KeyAndValue In Details.AnalystValues Do
					DimensionStructure.Insert(FinancialReportingCached.NameOfBudgetReportField(
						KeyAndValue.Key), KeyAndValue.Value);
					AnalyticsFilledIn_ = True;
				EndDo;
				If AnalyticsFilledIn_ Then
					Break;
				EndIf;
			EndDo;
			
			TheStructureOfTheSearch = Common.CopyRecursive(DimensionStructure);
			TheStructureOfTheSearch.Insert("MainItem", True);
			For Each CellStructureString In FoundRows Do
				TheStructureOfTheSearch.Insert("String", CellStructureString.String);
				TheStructureOfTheSearch.Insert("Column", CellStructureString.Column);
				ValidationLines = CellData_.FindRows(TheStructureOfTheSearch);
				For Each LineToDelete In ValidationLines Do
					CellData_.Delete(LineToDelete);
				EndDo;
			EndDo;
		EndIf;
		
	EndDo;
	
	If DeletedLines Then
		If ShowItemHierarchy Then
			GenerateReportServer();
			Return;
		EndIf;
		ShiftCellDataCells(CellData_, MinimumRowToDelete, -DeletedLines);
	EndIf;
	
	UpdatedCellData = False;
	ReflectBudgetChanges(, , , UpdatedCellData);
	
	If Not UpdatedCellData Then
		PutToTempStorage(CellData_, AddressOfCellData);
	EndIf;
	
EndProcedure

&AtServer
Procedure ShiftCellDataCells(CellData_, TopRowNumber, RowsCount)
	
	TypesOfResourceAreas = New Array;
	TypesOfResourceAreas.Add("AreaNameSum");
	TypesOfResourceAreas.Add("AreaNameCount");
	TypesOfResourceAreas.Add("AreaNameValue");
	
	For Each CellDataString In CellData_ Do
		
		For Each ResourceAreaView_ In TypesOfResourceAreas Do
			
			AreaName = Undefined;
			
			If ValueIsFilled(CellDataString[ResourceAreaView_]) Then
				AreaName = CellDataString[ResourceAreaView_];
			EndIf;
			
			If Not ValueIsFilled(AreaName) Then
				Continue;
			EndIf;
			
			AreaName = StrReplace(AreaName, "R", "");
			AddressArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(AreaName, "C");
			LineNumber = Number(AddressArray[0]);
			If LineNumber >= TopRowNumber Then
				LineNumber = LineNumber + RowsCount;
				AreaName = "R" + LineNumber + "C" + AddressArray[1];
				
				If ValueIsFilled(CellDataString.AreaNameSum)
					And ResourceAreaView_ = "AreaNameSum" Then
					CellDataString.AreaNameSum = AreaName;
				ElsIf ValueIsFilled(CellDataString.AreaNameCount)
					And ResourceAreaView_ = "AreaNameCount" Then
					CellDataString.AreaNameCount = AreaName;
				ElsIf ValueIsFilled(CellDataString.AreaNameValue)
					And ResourceAreaView_ = "AreaNameValue" Then
					CellDataString.AreaNameValue = AreaName;
				EndIf;
			EndIf;
		EndDo;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure AddRowInTableMode(AreaEditingOptions)
	
	FormParameters = New Structure();
	FormParameters.Insert("ArrayOfAnalyticsTypes", AreaEditingOptions.EditableAnalytics);
	FormParameters.Insert("AnalystValues", AreaEditingOptions.Details.AnalystValues);
	DimensionNumber = 0;
	For Each DimensionCaps In HeaderDimensionList Do
		DimensionNumber = DimensionNumber + 1;
		TextAnalyticsValue = StringFunctionsClientServer.SubstituteParametersToString("Dimension%1", DimensionNumber);
		If ValueIsFilled(Object[TextAnalyticsValue]) Then
			FormParameters.AnalystValues.Insert(DimensionCaps.Value, Object[TextAnalyticsValue]);
		EndIf;
	EndDo;
	FoundRow = FinancialReportingClient.SubordinateElementOfFormElement(BudgetItemTree,
		"GroupingID", AreaEditingOptions.Details.GroupingID);
	SubordinateDecryption = GetSubordinateDecryptionOfBudgetElementTreeString(FoundRow);
	FormParameters.Insert("SubordinateDecryption", SubordinateDecryption);
	FormParameters.Insert("DetailsDataAddress", DetailsDataAddress);
	
	CallbackDescription = New CallbackDescription("AddLineToBudgetEnd", ThisObject, AreaEditingOptions);
	OpenForm("Document.BudgetEntryForm.Form.EnterRowWithDimension", FormParameters,,,,,
			CallbackDescription,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Function GetSubordinateDecryptionOfBudgetElementTreeString(ItemsTree)
	
	ArrayOfDecryptions = New Array();
	For Each TreeRow In ItemsTree.GetItems() Do
		If ValueIsFilled(TreeRow.Details) And TypeOf(TreeRow.Details) = Type("Number") Then 
			ArrayOfDecryptions.Add(TreeRow.Details);
		EndIf;
		SubordinateDecryption = GetSubordinateDecryptionOfBudgetElementTreeString(TreeRow);
		CommonClientServer.SupplementArray(ArrayOfDecryptions,SubordinateDecryption);
	EndDo;
	
	Return ArrayOfDecryptions;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	MatchingTranscripts - Map -
// 	DetailsID - Number - 
// Returns:
// 	Structure - a structure with the property:
// 	 *String - CatalogRef.FinancialReportItems - Budget line.
&AtClient
Function DecryptionValueFromDecryptionMatch(MatchingTranscripts, DetailsID)
	Return MatchingTranscripts[DetailsID];
EndFunction

// LongDesc
// 
// Parameters:
// 	EditParameters - Map -
// 	RowsArray - Array -
// 	StartOfViewport - Number -
// Returns:
// 	Structure - LongDesc:
// * String - Arbitrary -
// * BudgetArea - Number -
// * Details - Arbitrary -
&AtClient
Function ConvertEditParametersToStructure(EditParameters, RowsArray, StartOfViewport)
	
	ReturnValue = Undefined;
	
	For Each KeyAndValue In EditParameters Do
		
		Step = 5;//Lines
		CurStart = StartOfViewport;
		FoundDecryption = Undefined;
		While CurStart <= Budget.TableHeight Do
			
			Ending = Min(CurStart + Step, Budget.TableHeight);
			MatchingTranscripts = New Array;
			For Cnt = CurStart To Ending Do
				For Column = 1 To Budget.TableWidth Do
					BudgetArea = Budget.Area(Cnt, Column);
					MatchingTranscripts.Add(BudgetArea.Details);
				EndDo;
			EndDo;
			
			MatchingTranscripts = BudgetReportingServerCall.DetailsValue(MatchingTranscripts, DetailsDataAddress);
			
			For Cnt = CurStart To Ending Do
				
				GroupingID = Undefined;
				For Column = 1 To Budget.TableWidth Do
					BudgetArea = Budget.Area(Cnt, Column);
					Details = DecryptionValueFromDecryptionMatch(MatchingTranscripts,
						BudgetArea.Details);
					If TypeOf(Details) <> Type("Structure") Then
						Continue;
					EndIf;
					If Details.Property("GroupingID")
							And GroupingID = Undefined Then
						GroupingID = Details.GroupingID;
					EndIf;
					If Details.Property("String") Then
						If Details["String"] <> KeyAndValue.Key Then
							Continue;
						EndIf;
						FoundDecryption = CommonClient.CopyRecursive(Details);
						FoundDecryption.Insert("GroupingID", GroupingID);
						Break;
					EndIf;
				EndDo;
				
				If FoundDecryption <> Undefined Then
					Break;
				EndIf;
				
			EndDo;
				
			If FoundDecryption <> Undefined Then
				Break;
			EndIf;
			
			CurStart = CurStart + Step + 1;
				
		EndDo;
			
		If FoundDecryption <> Undefined Then
			ReturnValue = New Structure();
			ReturnValue.Insert("EditableAnalytics", KeyAndValue.Value);
			ReturnValue.Insert("Details", FoundDecryption);
			ReturnValue.Insert("BudgetArea", BudgetArea.Bottom);
			ReturnValue.Insert("String", KeyAndValue.Key);
		EndIf;
		
	EndDo;
	
	Return ReturnValue;
EndFunction

&AtClient
Procedure AddLineToBudgetEnd(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	InsertionResult = InsertLinesIntoBudgetAtServer(Result, AdditionalParameters);
	If InsertionResult = "DuplicatesOfLines" Then
		WarningText = NStr("vi = 'Đã có dòng như vậy trong ngân sách';
							|ru = 'Строка с такими значениями уже есть в бюджете';
							|en = 'Line with these values already exists in the budget'; fa = 'Line with these values already exists in the budget';
							|it = 'La riga con questi valori è esiste già nel budget';
							|pl = 'Wiersz z tymi wartościami już istnieje w budżecie.';
							|tr = 'Bu anlamları olan satır bütçede zaten var'");
		ShowMessageBox(, WarningText);
	Else
		Modified = True;
	EndIf;
	
EndProcedure

// Returns the final row in the budget output tree.
// 
// Parameters:
// 	String - CatalogRef.FinancialReportItems -
// 	TableOfSubordination - ValueTable, ValueTreeRowCollection of ValueTreeRow - LongDesc:
// 	*Parent - CatalogRef.FinancialReportItems -
// 	*Ref - CatalogRef.FinancialReportItems -
// 	*ItemKind - EnumRef.FinancialReportItemKinds -
// Returns:
// 	CatalogRef.FinancialReportItems -
&AtServer
Function FinalLineOfOutputTree(String, TableOfSubordination)
	
	FoundRows = TableOfSubordination.FindRows(New Structure("Parent", String));
	If FoundRows.Count() = 1 Then
		HierarchyLine = FoundRows[0];
		If Not ValueIsFilled(HierarchyLine.Ref) Then
			Return String;
		Else
			Result = FinalLineOfOutputTree(HierarchyLine.Ref, TableOfSubordination);
			If ValueIsFilled(Result) Then
				Return Result;
			EndIf;
		EndIf;
	Else
		For Each FoundRow In FoundRows Do
			Result = FinalLineOfOutputTree(FoundRow.Ref, TableOfSubordination);
			If ValueIsFilled(Result) Then
				Return Result;
			EndIf;
		EndDo;
	EndIf;
	
EndFunction

&AtServer
Function InsertLinesIntoBudgetAtServer(Result, AdditionalParameters)
	
	NumberOfRowsToInsert = 1;
	If Result.Count() = 1 Then
		For Each KeyAndValue In Result Do
			If TypeOf(KeyAndValue.Value) = Type("Array") Then
				NumberOfRowsToInsert = KeyAndValue.Value.Count();
			EndIf;
		EndDo;
	EndIf;
	
	If NumberOfRowsToInsert = 1 Then
		InsertionResult = InsertAreaOnServer(Result, AdditionalParameters);
	Else
		ArrayOfInsertionResults = New Array;
		For LineNumber = 1 To NumberOfRowsToInsert Do
			ResultIsCopy = Common.CopyRecursive(Result);
			For Each KeyAndValue In ResultIsCopy Do
				ResultIsCopy.Insert(KeyAndValue.Key, KeyAndValue.Value[NumberOfRowsToInsert-LineNumber]);
			EndDo;
			InsertionResult = InsertAreaOnServer(ResultIsCopy, AdditionalParameters);
			If ArrayOfInsertionResults.Find(InsertionResult) = Undefined Then
				ArrayOfInsertionResults.Add(InsertionResult);
			EndIf;
		EndDo;
		If ArrayOfInsertionResults.Count() = 1 Then
			InsertionResult = ArrayOfInsertionResults[0];
		Else
			InsertionResult = "";
		EndIf;
	EndIf;
	
	Return InsertionResult;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	ConformityOfMeasurements - Map - 
// 	AdditionalParameters - See ConvertEditParametersToStructure
// Returns:
// 	String - By silencing an empty string (no problem). If there are duplicates, a "duplicate" is returned.
&AtServer
Function InsertAreaOnServer(ConformityOfMeasurements, AdditionalParameters)
	
	InsertionStatus = ""; // the area was inserted successfully.
	
	CellRow = AdditionalParameters.String;
	Details = AdditionalParameters.Details;
	
	StructureOfOutputParameters = GetFromTempStorage(
		BudgetProfileDisplayParameters); // See BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView
	StructureOfReportDescription = StructureOfOutputParameters.StructureOfReportDescription;
	ColumnStructureOfDataTable = StructureOfOutputParameters.ColumnStructureOfDataTable;
	
	EndString = FinalLineOfOutputTree(CellRow, StructureOfReportDescription.TableOfSubordinationOfElements);
	If Not ValueIsFilled(EndString) Then
		WarningText = NStr("vi = 'Lỗi trong cấu trúc của loại ngân sách';
							|ru = 'Ошибка в структуре вида бюджета';
							|en = 'Error in the budget profile structure'; fa = 'Error in the budget profile structure';
							|it = 'Errore nella struttura della tipologia di budget';
							|pl = 'Błąd w strukturze typu budżetu';
							|tr = 'Bütçe profili yapısında hata'");
		Raise WarningText;
	EndIf;
	FoundRows = StructureOfReportDescription.CellStructure.FindRows(New Structure("MainItem, String", True, EndString));
	CellData_ = GetFromTempStorage(AddressOfCellData);
	
	DimensionStructure = New Structure;
	For Each KeyAndValue In Details.AnalystValues Do
		If HeaderDimensionList.FindByValue(KeyAndValue.Key) <> Undefined Then
			Continue;
		EndIf;
		DimensionStructure.Insert(FinancialReportingCached.NameOfBudgetReportField(KeyAndValue.Key), KeyAndValue.Value);
	EndDo;
	For Each KeyAndValue In ConformityOfMeasurements Do
		If HeaderDimensionList.FindByValue(KeyAndValue.Key) <> Undefined Then
			Continue;
		EndIf;
		DimensionStructure.Insert(FinancialReportingCached.NameOfBudgetReportField(KeyAndValue.Key), KeyAndValue.Value);
	EndDo;
	
	// Adding a row to cell data
	TheStructureOfTheSearch = Common.CopyRecursive(DimensionStructure);
	TheStructureOfTheSearch.Insert("MainItem", True);
	For Each CellStructureString In FoundRows Do
		TheStructureOfTheSearch.Insert("String", CellStructureString.String);
		TheStructureOfTheSearch.Insert("Column", CellStructureString.Column);
		For Each Dimension In DimensionStructure Do
			If Not ValueIsFilled(TheStructureOfTheSearch[Dimension.Key])
				And ValueIsFilled(CellStructureString[Dimension.Key]) Then
				TheStructureOfTheSearch.Insert(Dimension.Key, CellStructureString[Dimension.Key]);
			EndIf;
		EndDo;
		ValidationLines = CellData_.FindRows(TheStructureOfTheSearch);
		If ValidationLines.Count() Then
			StringOfCellParameters = StructureOfReportDescription.CellParameters.Find(CellStructureString.RowIndex, "RowIndex");
			If StringOfCellParameters.FlagCount Then
				ThereAreDuplicatesOfLines = False;
				For Each CheckString In ValidationLines Do
					If Not IsBlankString(CheckString.AreaNameCount) Then
						ThereAreDuplicatesOfLines = True;
						Break;
					EndIf;
				EndDo;
				If ThereAreDuplicatesOfLines Then
					InsertionStatus = "DuplicatesOfLines";
					Return InsertionStatus;
				EndIf;
			EndIf;
			If StringOfCellParameters.FlagSum Then
				ThereAreDuplicatesOfLines = False;
				For Each CheckString In ValidationLines Do
					If Not IsBlankString(CheckString.AreaNameSum) Then
						ThereAreDuplicatesOfLines = True;
						Break;
					EndIf;
				EndDo;
				If ThereAreDuplicatesOfLines Then
					InsertionStatus = "DuplicatesOfLines";
					Return InsertionStatus;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	Periodicity_ = ColumnStructureOfDataTable.Periodicity_;
	PeriodsTable = BudgetReportingDisplayServer.PeriodsTable(Periodicity_, Object.BeginOfPeriod, Object.PeriodEnding);
	If Not Periodicity_.Count() Then
		PeriodsTable.Add();
	EndIf;
	PeriodicitiesByString = New Array;
	For Each Periodicity In Periodicity_ Do
		PeriodicitiesByString.Add(FinancialReportingClientServer.PeriodStrings(Periodicity).Period);
	EndDo;
	OutputTreeLines = StructureOfOutputParameters.OutputTree.Rows.Find("Rows", "DimensionName", True);
	If OutputTreeLines <> Undefined Then
		For Each PeriodicityByString In PeriodicitiesByString Do
			If Details.Property(PeriodicityByString)
				And ValueIsFilled(Details[PeriodicityByString])
				And OutputTreeLines.Rows.Find(PeriodicityByString, "DimensionName", True) <> Undefined Then
				DimensionStructure.Insert(PeriodicityByString, Details[PeriodicityByString]);
			EndIf;
		EndDo;
	EndIf;
	
	TheStructureOfTheSearch = Common.CopyRecursive(DimensionStructure);
	TheStructureOfTheSearch.Insert("MainItem", True);
	SearchStructureVerification = New Structure("MainItem", True);
	For Each CellStructureString In FoundRows Do
		TheStructureOfTheSearch.Insert("String", CellStructureString.String);
		TheStructureOfTheSearch.Insert("Column", CellStructureString.Column);
		
		AddedPeriods = New Map();
		For Each StringOfPeriods In PeriodsTable Do
			
			PeriodAsString = ";";
			SearchStructureVerification.Insert("String", CellStructureString.String);
			SearchStructureVerification.Insert("Column", CellStructureString.Column);
			
			For Each PeriodicityByString In PeriodicitiesByString Do
				If DimensionStructure.Property(PeriodicityByString)
					And DimensionStructure[PeriodicityByString] <> StringOfPeriods[PeriodicityByString] Then
					Continue;
				EndIf;
				SearchStructureVerification.Insert(PeriodicityByString, StringOfPeriods[PeriodicityByString]);
				
				If CellData_.FindRows(SearchStructureVerification).Count() > 0 Then
					TheStructureOfTheSearch.Insert(PeriodicityByString, StringOfPeriods[PeriodicityByString]);
					PeriodAsString = PeriodAsString + PeriodicityByString
						+"{" + String(StringOfPeriods[PeriodicityByString]) + "};";
				Else
					If TheStructureOfTheSearch.Property(PeriodicityByString) Then
						TheStructureOfTheSearch.Delete(PeriodicityByString);
					EndIf;
				EndIf;
			EndDo;
			
			If AddedPeriods.Get(PeriodAsString) = Undefined Then
				If PeriodAsString = ";" Then
					For Each PeriodicityByString In PeriodicitiesByString Do
						SearchStructureVerification.Delete(PeriodicityByString);
					EndDo;
					RowsCellData = CellData_.FindRows(SearchStructureVerification);
					If RowsCellData.Count() > 0 Then
						For Each PeriodicityByString In PeriodicitiesByString Do
							TheStructureOfTheSearch.Insert(PeriodicityByString, RowsCellData[0][PeriodicityByString]);
						EndDo;
					EndIf;
				EndIf;
				If CellData_.FindRows(TheStructureOfTheSearch).Count() = 0 Then	
					NewRow = BudgetReportingDisplayServer.AddRowOfCellData(
						CellData_,
						CellStructureString,
						TheStructureOfTheSearch,
						CellStructureString.Column);
					For Each PeriodicityByString In PeriodicitiesByString Do
						If Not ValueIsFilled(NewRow[PeriodicityByString]) Then
							NewRow[PeriodicityByString] = Undefined;
						EndIf;
					EndDo;
				EndIf;
				AddedPeriods.Insert(PeriodAsString,True);
			EndIf;
		EndDo;
		
	EndDo;
	
	// Output of cell data to the report
	DataParameters = Documents.BudgetEntryForm.ParametersForDisplayingBudgetViewInTableDocument(
		Object, 
		HeaderDimensionList, 
		ScenarioCurrency,
		StructureOfOutputParameters, 
		Enums.ModesOfBudgetReportGeneration.Document,
		CellData_);
	
	OutputTree = StructureOfOutputParameters.OutputTree;
	OutputTreeLine = OutputTree.Rows.Find(CellRow, "ReportItem", True);
	Table = OutputTreeLine;
	While Table.DimensionName <> "Table" Do
		Table = Table.Parent;
	EndDo;
	
	TableRows_ = OutputTree.Rows.FindRows(New Structure("DimensionName", "Table"));
	TableNumber = 1;
	For Each TableRow In TableRows_ Do
		If TableRow = Table Then
			Break;
		EndIf;
		TableNumber = TableNumber + 1;
	EndDo;
	
	// We output the tree to the report.
	OutputParameters = New Structure();
	OutputParameters.Insert("CacheAnalystValues", New Map);
	OutputParameters.Insert("CellParameters", StructureOfReportDescription.CellParameters);
	OutputParameters.Insert("CellStructure", StructureOfReportDescription.CellStructure);
	OutputParameters.Insert("SubordinateElementsOfBudgetView", StructureOfReportDescription.TableOfSubordinationOfElements);
	OutputParameters.Insert("ColumnStructureOfDataTable", StructureOfOutputParameters.ColumnStructureOfDataTable);
	
	OutputParameters.Insert("DetailsData", GetFromTempStorage(DetailsDataAddress));
	OutputParameters.Insert("ResultDocument", New SpreadsheetDocument);
	OutputParameters.Insert("CellData_", CellData_);
	OutputParameters.Insert("DimensionSearchIndexes", New Map);
	OutputParameters.Insert("ForEditing", True);
	OutputParameters.Insert("CellParameters", StructureOfReportDescription.CellParameters);
	OutputParameters.Insert("CellStructure", StructureOfReportDescription.CellStructure);
	OutputParameters.Insert("TableComplex_", Table.ItemKind = Enums.FinancialReportItemKinds.ComplexTable);
	OutputParameters.Insert("ReportParametersForFormatting", Undefined);
	
	CacheOfBudgetItemDetails = Undefined; 
	If Not StructureOfOutputParameters.DataCache.Property("CacheOfBudgetItemDetails", CacheOfBudgetItemDetails) Then
		CacheOfBudgetItemDetails = BudgetReportingCacheCalculationServer.CacheOfBudgetItemDetails(Object.BudgetProfile);
		StructureOfOutputParameters.DataCache.Insert("CacheOfBudgetItemDetails", CacheOfBudgetItemDetails);
	EndIf;
	OutputParameters.Insert("CacheOfEmptyAnalyticsPresentations", New Map);
	OutputParameters.Insert("CacheOfBudgetItemDetails", CacheOfBudgetItemDetails);
	CacheAdditionalBankingDetails = CacheOfBudgetItemDetails.CacheOfAdditionalBankingDetails;
	
	ReportDataForFormatting = BudgetReportingCacheCalculationServer.ReportDataForFormatting(Table.TableParameters,
		CacheAdditionalBankingDetails);
	OutputParameters.Insert("ReportDataForFormatting", ReportDataForFormatting);
	
	PeriodParameters_1 = BudgetReportingDisplayServer.ConvertDataParametersToPeriodData(
		StructureOfOutputParameters.ColumnStructureOfDataTable,
		DataParameters);
	OutputParameters.Insert("PeriodParameters_1", PeriodParameters_1);
	OutputParameters.Insert("LineCounter", 0);
	
	CacheOfCurrencyParameters = BudgetReportingDisplayServer.GetCacheOfCurrencyParameters(
		CellData_,
		StructureOfReportDescription.CellParameters,
		OutputParameters.SubordinateElementsOfBudgetView);
	OutputParameters.Insert("CacheOfCurrencyParameters", CacheOfCurrencyParameters);
	
	CacheOfUnitParameters = BudgetReportingDisplayServer.GetCacheOfUnitParameters(CellData_,
		StructureOfReportDescription.CellParameters);
	OutputParameters.Insert("CacheOfUnitParameters", CacheOfUnitParameters);
	OutputParameters.Insert("DisplayNotes_", False);
	OutputParameters.Insert("DisplayTableNumbers", False);
	OutputParameters.Insert("StructureOfAreas", BudgetReportingDisplayServer.StructureOfTemplateAreas(OutputParameters));
	
	OutputParameters.Insert("GenerationMode", Enums.ModesOfBudgetReportGeneration.Document);
	
	MeasurementPresentations = BudgetReportingDisplayServer.PresentationOfReportDimensions(OutputTree,
		CellData_, ColumnStructureOfDataTable, CacheAdditionalBankingDetails);
	OutputParameters.Insert("MeasurementPresentations", MeasurementPresentations);

	ColumnStructure1 = BudgetReportingDisplayServer.ParametersForColumnDimensions(OutputParameters,
		OutputParameters.DimensionSearchIndexes,
		Table.Rows.Find("Columns", "DimensionName"));
	
	OutputParameters.Insert("ColumnStructure1", ColumnStructure1);
	OutputParameters.Insert("TableParameters", Table.TableParameters);
	OutputParameters.Insert("SubordinateElementsOfBudgetView", StructureOfReportDescription.TableOfSubordinationOfElements);
		
	CacheOfUnitParameters = BudgetReportingDisplayServer.GetCacheOfUnitParameters(CellData_,
		StructureOfReportDescription.CellParameters);
	OutputParameters.Insert("CacheOfUnitParameters", CacheOfUnitParameters);
	
	CacheOfCurrencyParameters = BudgetReportingDisplayServer.GetCacheOfCurrencyParameters(CellData_,
		StructureOfReportDescription.CellParameters,
		OutputParameters.SubordinateElementsOfBudgetView);
	OutputParameters.Insert("CacheOfCurrencyParameters", CacheOfCurrencyParameters);
	
	ReportOutputTree = FormAttributeToValue("BudgetItemTree");
	GroupingTree = FinancialReportingServer.SubordinateItem(ReportOutputTree,
		"GroupingID", Details.GroupingID);
	AddressForAddingLinesToEditList = GroupingTree.Parent;
	OutputParameters.Insert("AddressForAddingLinesToEditList", AddressForAddingLinesToEditList);
	OutputParameters.Insert("LevelStyle", New Map);
	
	OutputParameters.Insert("DonTAssignNamesToAreas", True);
	
	Level = 0; LevelCalculationLine = OutputTreeLine;
	While LevelCalculationLine.DimensionName <> "Rows" Do
		If LevelCalculationLine.DisplayWithParent = False Then
			Level = Level + 1;
		EndIf;
		LevelCalculationLine = LevelCalculationLine.Parent;
	EndDo;
	
	OutputParameters.Insert("DoNotOutputEmptyAnalyticsLinesUpToLevelOf", Level);
	
	RowsArray = New Structure("Rows", CommonClientServer.ValueInArray(OutputTreeLine));
	
	If OutputTreeLine.ShowItemHierarchy Then
		OutputParameters.Insert("AddedLinesDecryption", New Array);
	EndIf;
	
	TheStructureOfTheSearch = Common.CopyRecursive(DimensionStructure);
	BudgetReportingDisplayServer.OutputTableToReport(OutputParameters, RowsArray, TableNumber, TheStructureOfTheSearch, Level);
	BudgetReportingDisplayServer.CreateBudget(OutputParameters.ResultDocument, OutputParameters, OutputTree);
	
	ValueToFormAttribute(ReportOutputTree, "BudgetItemTree");
	
	If OutputTreeLine.ShowItemHierarchy Then
		// when adding an area with hierarchical groupings, you need to update the entire budget
		ObjectAndCalculationParameters = BudgetReportingClientServer.StructureByBudgetInstanceObject(ThisObject);
		For Each Details In OutputParameters.AddedLinesDecryption Do
			BudgetReportingClientServer.ReflectCellChange(ObjectAndCalculationParameters, Details, 0, , True);
		EndDo;
		GenerateReportServer(True);
		DetailsData = GetFromTempStorage(DetailsDataAddress);
		BudgetingServer.CheckFixTSInstanceBudget(Object, ObjectAndCalculationParameters, Budget, DetailsData);
		Return InsertionStatus;
	EndIf;
	
	InBorderOfInsertedArea = OutputParameters.ResultDocument.TableHeight - 1;
	ShiftCellDataCells(CellData_, AdditionalParameters.BudgetArea, 1 + InBorderOfInsertedArea);
	
	ScopeOfApplication_7 = AdditionalParameters.BudgetArea;
	ScopeOfAdmission_1 = AdditionalParameters.BudgetArea + InBorderOfInsertedArea;
	ReceiverAreaDopLeft = 1;
	AreaOfReceiverIsAdditionalRight = Budget.TableWidth;
	
	// To correctly insert a line into an existing grouping of document lines, only the top and bottom of the areas are used.
	// The whole line is inserted.
	ReceivingArea = Budget.Area(ScopeOfApplication_7, , ScopeOfAdmission_1);
	NewArea = OutputParameters.ResultDocument.Area(1, , 1 + InBorderOfInsertedArea, );
	Budget.InsertArea(NewArea, ReceivingArea, SpreadsheetDocumentShiftType.Vertical);
	
	For String = ScopeOfApplication_7 To ScopeOfAdmission_1 Do
		For Column = ReceiverAreaDopLeft To AreaOfReceiverIsAdditionalRight Do
			DocumentArea = Budget.Area(String, Column);
			
			Details = BudgetReportingServerCall.DetailsValue(DocumentArea.Details, DetailsDataAddress);
			
			If Details = Undefined Then
				Continue;
			EndIf;
			If Details.Property("DataLineIndex") Then
				DataString1 = CellData_[Details.DataLineIndex];
				If Details.Property("IndicatorName") Then
					If Details.IndicatorName = "Sum" Then
						DataString1.AreaNameSum = DocumentArea.Name;
					ElsIf Details.IndicatorName = "Count" Then
						DataString1.AreaNameCount = DocumentArea.Name;
					ElsIf Details.IndicatorName = "Value" Then
						DataString1.AreaNameValue = DocumentArea.Name;
					EndIf;
				Else
					// Analysis by column number. Values can only be added to rows and
					// cells are shifted only vertically, so the column number remains the same.
					NewAreaColumn = Mid(DocumentArea.Name, 3);
					If ValueIsFilled(DataString1.AreaNameSum)
						And Mid(DataString1.AreaNameSum, 3) = NewAreaColumn Then
						DataString1.AreaNameSum = DocumentArea.Name;
					ElsIf ValueIsFilled(DataString1.AreaNameCount)
						And Mid(DataString1.AreaNameCount, 3) = NewAreaColumn Then
						DataString1.AreaNameCount = DocumentArea.Name;
					ElsIf ValueIsFilled(DataString1.AreaNameValue)
						And Mid(DataString1.AreaNameValue, 3) = NewAreaColumn Then
						DataString1.AreaNameValue = DocumentArea.Name;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	PutToTempStorage(CellData_, AddressOfCellData);
	PutToTempStorage(OutputParameters.DetailsData, DetailsDataAddress);
	
	Return InsertionStatus;
	
EndFunction

&AtServer
Procedure SetAccessibilityOfButtonsWhenChangingPage()
	
	If Items.PanelBudget.CurrentPage = Items.Table Then
		Items.EditAsAList.Picture = PictureLib.Forward;
		Items.EditAsAList.Title = NStr("vi = 'Soạn trong danh sách';
										|ru = 'Редактировать в списке';
										|en = 'Edit in the list'; fa = 'ویرایش در فهرست';
										|it = 'Editare nell''elenco';
										|pl = 'Edytuj na liście';
										|tr = 'Listede düzenle'");
		Items.AddListLine.Visible = False;
		Items.CopyLineFromList.Visible = False;
		Items.ChangeLineInList.Visible = False;
		Items.DeleteLineInList.Visible = False;
		Items.Copy.Visible = True;
		Items.Insert.Visible = True;
		Items.ShowHideBudgetTree.Visible = False;
		Items.AddRow.Visible = True;
		Items.DeleteRow.Visible = True;
	Else
		Items.EditAsAList.Title = NStr("vi = 'Chỉnh sửa trong bảng';
										|ru = 'Редактировать в таблице';
										|en = 'Edit in the table'; fa = 'Edit in the table';
										|it = 'Modificare nella tabella';
										|pl = 'Edytuj w tabeli.';
										|tr = 'Tabloda düzenle'");
		Items.EditAsAList.Picture = PictureLib.Back;
		Items.AddListLine.Visible = True;
		Items.CopyLineFromList.Visible = True;
		Items.ChangeLineInList.Visible = True;
		Items.DeleteLineInList.Visible = True;
		Items.Copy.Visible = False;
		Items.Insert.Visible = False;
		Items.ShowHideBudgetTree.Visible = True;
		Items.AddRow.Visible = False;
		Items.DeleteRow.Visible = False;
	EndIf;
	
EndProcedure
// End MenuReports

&AtServer
Procedure WhenChangingBudgetEditingMethod(FillInBudget = True)
	
	If Object.Action = Enums.TypesOfBudgetEntryFormActions.AdjustByBudgetFlowItems Then
		Items.BudgetPage.Visible = False;
		Items.PageAdjustmentsByBudgetItems.Visible = True;
		If Items.MainPanel.CurrentPage = Items.BudgetPage Then
			Items.MainPanel.CurrentPage = Items.PageAdjustmentsByBudgetItems;
		EndIf;
		Return;
	Else
		Items.BudgetPage.Visible = True;
		Items.PageAdjustmentsByBudgetItems.Visible = False;
		If Items.MainPanel.CurrentPage = Items.PageAdjustmentsByBudgetItems Then
			Items.MainPanel.CurrentPage = Items.BudgetPage;
		EndIf;
	EndIf;
	
	ItemsAvailability = 
		Not UseBudgetConfirmation 
		Or (Object.Status <> Enums.PlanStatuses.Upholded);
	
	MainInputMethod = Common.ObjectAttributeValue(Object.BudgetProfile, "MainInputMethod");
	If ValueIsFilled(Object.BudgetProfile)
		And (MainInputMethod = Enums.BudgetEditingMethods.InList
		Or EditMode = "List") And ItemsAvailability Then
		Items.PanelBudget.CurrentPage = Items.List;
	Else
		Items.PanelBudget.CurrentPage = Items.Table;
	EndIf;
	
	BudgetTemplateParameters = Common.ObjectAttributesValues(Object.BudgetProfile, 
			"EnableSpreadsheetDocumentProtection, SaveBudgetInTabularFormToBudgetEntryForm, DataVersion");
	
	ProtectionEnabled = BudgetTemplateParameters.EnableSpreadsheetDocumentProtection = True;
	CheckingSavedTemplate = BudgetTemplateParameters.SaveBudgetInTabularFormToBudgetEntryForm = True;
	
	Items.Budget.Protection = ProtectionEnabled;
	
	SetAccessibilityOfButtonsWhenChangingPage();
	
	If Not FillInBudget Then
		Return;
	EndIf;
	
	If Items.PanelBudget.CurrentPage = Items.List Then
		GenerateReportServer(True);
	Else
		If Not CheckingSavedTemplate Then
			GenerateReportServer();
		Else
			If Not RestoreSavedTemplate(BudgetTemplateParameters.DataVersion) Then
				GenerateReportServer();
			Else
				// There is no Column table property in the stored data 
				OutputParameters = GetFromTempStorage(BudgetProfileDisplayParameters);
				If Not OutputParameters.Property("TableColumns") Then
					GenerateReportServer();
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function RestoreSavedTemplate(BudgetViewVersion)
	
	RecoveryResult = BudgetingServer.RestoreStoredTemplate(Object.Ref, Object.BudgetProfile, BudgetViewVersion);
	If RecoveryResult = Undefined Then
		Return False;
	EndIf;
	
	LoadPreparedData(RecoveryResult);
	If RecoveryResult.CellData_ <> Undefined Then
		ReflectBudgetChanges();
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Function PrepareSupportingBudgetData()
	
	Result = New Structure;
	Result.Insert("CellData_", GetFromTempStorage(AddressOfCellData));
	Result.Insert("DetailsData", GetFromTempStorage(DetailsDataAddress));
	Result.Insert("TreeOfEditListRows", FormAttributeToValue("BudgetItemTree", Type("ValueTree")));
	Result.Insert("BudgetViewVersion", Common.ObjectAttributeValue(Object.BudgetProfile, "DataVersion"));
	Result.Insert("BudgetProfile", Object.BudgetProfile);
	
	OutputParameters = GetFromTempStorage(BudgetProfileDisplayParameters);
	If OutputParameters.Property("TableColumns") Then
		Result.Insert("TableColumns", OutputParameters.TableColumns);
	EndIf;
	
	LevelStyle = New Map;
	For Each UOElement In ConditionalAppearance.Items Do
		
		If Not StrFind(UOElement.Presentation, "AddedUOOfElementTree_") Then
			Continue;
		EndIf;
		
		For Each FilterElement In UOElement.Filter.Items Do
			
			If String(FilterElement.LeftValue) = "BudgetItemTree.TableID" Then
				TheKeyOfTheTable = FilterElement.RightValue;
			ElsIf String(FilterElement.LeftValue) = "BudgetItemTree.Level" Then
				LevelKey = FilterElement.RightValue;
			EndIf;
			
		EndDo;
		
		BackColor = UOElement.Appearance.FindParameterValue(New DataCompositionParameter("BackColor"));
		
		StyleCacheSettings = New Structure;
		StyleCacheSettings.Insert("LevelStyle", LevelStyle);
		StyleCacheSettings.Insert("BackColor", BackColor);
		StyleCacheSettings.Insert("TableID", TheKeyOfTheTable);
		StyleCacheSettings.Insert("Level", LevelKey);
		
		TreeRowStyles =
			BudgetReportingDisplayServer.GetCacheOfEditingListLineStyles(StyleCacheSettings);
		LevelStyle.Insert(TheKeyOfTheTable, TreeRowStyles);
		
	EndDo;
	
	Result.Insert("LevelStyle", LevelStyle);
	
	Return Result;
	
EndFunction

&AtServer
Procedure SaveStoredTemplate()
	
	Preserve = Common.ObjectAttributeValue(Object.BudgetProfile, "SaveBudgetInTabularFormToBudgetEntryForm");
	If Not Preserve = True Then
		Return;
	EndIf;
	
	BudgetingServer.SaveStoredTemplate(Budget, PrepareSupportingBudgetData(), Object.Ref);
	
EndProcedure

&AtServerNoContext
Procedure OnCloseAtServer(JobID,Ref)
	
	CancelCompletedTasks(JobID);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsForBudgetTaskServer()
	
	If Not AvailabilityOfItemsByBudgetTask = Undefined And Not AvailabilityOfItemsByBudgetTask.ThereIsActiveTask Then
		ReadOnly = True;
		Return;
	EndIf;
	
	If Not AvailabilityOfItemsByBudgetTask = Undefined And AvailabilityOfItemsByBudgetTask.ThereIsActiveTask Then
		Items.BudgetingModel.ReadOnly = True;
		Items.BudgetProfile.ReadOnly = True;
		If Not Items.Scenario.ReadOnly And Not AvailabilityOfItemsByBudgetTask.AvailabilityScenario Then
			Items.Scenario.ReadOnly = True;
		EndIf;
		Items.BeginOfPeriod.ReadOnly = True;
		Items.EndOfPeriod.ReadOnly = True;
		Items.SelectPeriod.Enabled = True;
		If Not Items.Organization.ReadOnly And Not AvailabilityOfItemsByBudgetTask.AvailabilityCompany Then
			Items.Organization.ReadOnly = True;
		EndIf;
		If Not Items.Department.ReadOnly And Not AvailabilityOfItemsByBudgetTask.AvailabilityDepartment Then
			Items.Department.ReadOnly = True;
		EndIf;
		Items.Action.ReadOnly = True;
		
		MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
		For Cnt = 1 To MaximumNumberOfAnalysts Do
			Item = Items.Find("AnalyticsHeader_" + Cnt);
			If Item = Undefined Then
				Continue;
			EndIf;
			If Not Items["AnalyticsHeader_" + Cnt].ReadOnly And Not AvailabilityOfItemsByBudgetTask["AvailabilityOfAnalytics_"+ Cnt] Then
				Items["AnalyticsHeader_" + Cnt].ReadOnly = True;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure
#EndRegion

&AtServer
Procedure GetAvailabilityOfItemsByBudgetIssue()
	
	ParametersStructure = New Structure("BudgetingModel", Object.BudgetingModel);
	
	UseBudgetProcess = GetFunctionalOption("UseBudgetProcess", ParametersStructure);
	
	If Not UseBudgetProcess Or Users.RolesAvailable("EditingBudgetingDataOutsideProcesses")
		Or Users.IsFullUser(, , True) Then
		
		Return;
		
	EndIf;
	
	AvailabilityOfItemsByBudgetTask = Tasks.BudgetTask.GetAvailabilityOfBudgetInstanceAnalytics();
	
	If Not ValueIsFilled(Object.Ref) Then
		ErrorText = NStr("vi = 'Tạo chứng từ chỉ có thể từ nhiệm vụ ngân sách.';
						|ru = 'Создание документа возможно только из бюджетной задачи.';
						|en = 'Document can be created only from the budget task.'; fa = 'Document can be created only from the budget task.';
						|it = 'È possibile creare un documento solo dal task del budget.';
						|pl = 'Utworzenie dokumentu jest możliwe tylko z zadania budżetowego.';
						|tr = 'Sadece bütçe görevinden belge oluşturulabilir.'");
		Raise ErrorText;
	EndIf;
	
	AvailabilityOfItemsByBudgetTask = Tasks.BudgetTask.GetAvailabilityOfBudgetInstanceAnalytics(Object.Ref, Users.CurrentUser());
	
EndProcedure
#Region IndicatorsCalculation

// Parameters:
//  Parent - FormGroup
//  Menu - Undefined
//       - ValueList of String
// 
// Returns:
//  - Undefined
//  - ValueList of String
//
&AtClient
Function MenuOfIndicatorTypes(Parent, Menu = Undefined)

	If Menu = Undefined Then
		Menu = New ValueList;
	EndIf;

	MenuItems = Parent.ChildItems; // FormItems

	For Each Item In MenuItems Do

		If TypeOf(Item) <> Type("FormGroup") Then
			Menu.Add(Item.Name, Item.Title, MainIndicator = Item.Name);
		Else
			MenuOfIndicatorTypes(Item, Menu);
		EndIf;

	EndDo;

	MenuItem = Menu.FindByValue(Items.CalculateAllIndicators.Name);

	If MenuItem <> Undefined Then
		MenuItem.Check = ExpandIndicatorsArea;
	EndIf;

	Return Menu;

EndFunction

&AtClient
Procedure AfterSelectingTheIndicator(TheSelectedIndicator, AdditionalParameters) Export

	If TypeOf(TheSelectedIndicator) <> Type("ValueListItem") Then
		Return;
	EndIf;

	If TheSelectedIndicator.Value = Items.CalculateAllIndicators.Name Then

		ExpandIndicatorsArea = Not Items.CalculateAllIndicators.Check;
		CommonInternalClient.SetIndicatorsPanelVisibiility(Items, ExpandIndicatorsArea);

	Else
		CalculateIndicators(TheSelectedIndicator.Value);
	EndIf;

EndProcedure

// Performs calculation and output of indicators of the selected area of cells.
// See event handler reportabledocumentactivation of the area.
//
&AtClient
Procedure CalculateIndicatorsDynamically()

	CalculateIndicators();

EndProcedure

&AtClient
Procedure CalculateIndicators(CurrentCommand = "")

	Factor = "";
	CommonInternalClient.CalculateIndicators(ThisObject, "Budget", CurrentCommand, 2);

EndProcedure

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_BeginOfPeriod" Then
		BeginOfPeriodOnChange(Items.BeginOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_PeriodEnding" Then
		PeriodEndingOnChange(Items.EndOfPeriod);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
