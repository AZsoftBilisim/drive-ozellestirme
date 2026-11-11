#Region FormEventHandlers

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	PeriodPresentation = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(Object.Date);
	
	ItemsAndDimensionsSelectionParameters = Documents.FutureExpenseCommitmentsAccrualWriteOff.ItemsAndDimensionsSelectionParameters(Enums.BusinessTransactions.EmptyRef());
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	PeriodPresentation = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(Object.Date);
	
	ItemsAndDimensionsSelectionParameters = Documents.FutureExpenseCommitmentsAccrualWriteOff.ItemsAndDimensionsSelectionParameters(Enums.BusinessTransactions.EmptyRef());
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	FillInSignOfDifferentFormationOfBUAndTA();
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	CheckComplianceOfDetailsWithReserves();
	
	FillFormAttributes();
	
	SetElementProperties(ThisObject);
	
EndProcedure

&AtClient
Procedure ReserveKindOnChange(Item)
	
	CheckComplianceOfDetailsWithReserves();
	
	FillFormAttributes();
	
	SetElementProperties(ThisObject);
	
EndProcedure

&AtClient
Procedure PeriodPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CloseHandler = New CallbackDescription("PeriodPresentationStartChoiceCompletion", ThisObject);
	FormParameters 	   = New Structure("Value, PeriodSelectionMode", Object.Date, "MONTH");
	
	OpenForm("CommonForm.PeriodSelection",
		FormParameters, 
		ThisObject, 
		UUID,
		,
		, 
		CloseHandler,
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure PeriodPresentationClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure PeriodPresentationTuning(Item, Direction, StandardProcessing)
	
	Object.Date = BegOfMonth(Object.Date);
	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(
		Direction,
		StandardProcessing,
		Object.Date,
		PeriodPresentation);
	Object.Date = EndOfMonth(Object.Date);
	
	FillFormAttributes();

	SetElementProperties(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReserves

&AtClient
Procedure ReservesOnStartEdit(Item, NewRow, Copy)
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, Items.Reserves.CurrentData, "Object.Reserves");
EndProcedure

&AtClient
Procedure ReservesProvisionObjectOnChange(Item)
	
	If Items.Reserves.CurrentData = Undefined Then
		Return;
	EndIf;
	
	FillTSWithRegisterData(Items.Reserves.CurrentRow);
	
EndProcedure

&AtClient
Procedure ReservesExpenseItemAccrualsOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure ReservesExpenseItemAccrualsStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ReservesIncomeItemOfWriteOffOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure ReservesIncomeItemOfWriteOffStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ReservesExpensesDimensionAccrualsStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ReservesExpensesDimensionAccrualsAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure ReservesExpensesDimensionAccrualsTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure ImportDataFromFile(Command)
	
	If Object.Reserves.Count() Then
		NotificationParameters = New Structure("EventName", Command.Name);
		CleaningTSDescriptionOfAlert = New CallbackDescription("IssueOfClearingTheTablePartCompletion", ThisObject, NotificationParameters);
		QueryText = NStr("vi = 'Xóa bảng dự phòng trước khi điền dữ liệu từ tệp?';
						|ru = 'Очистить таблицу резервов перед заполнением по данным из файла?';
						|en = 'Clear table of reserve before filling in according to data from file?'; fa = 'Clear table of reserve before filling in according to data from file?';
						|it = 'Eliminare i dati nella tabella delle riserve prima di compilare i dati dal file?';
						|pl = 'Oczyścić tabelę rezerw przed wypełnieniem według danych z pliku?';
						|tr = 'Dosyadan veri kullanarak doldurmadan önce rezerv tablosunu temizle?'");
		ShowQueryBox(CleaningTSDescriptionOfAlert, QueryText, QuestionDialogMode.YesNoCancel);
	Else
		LoadDataFromStartFile();
	EndIf;
	
EndProcedure

&AtClient
Procedure Fill(Command)
	
	If Not ValueIsFilled(Object.Organization) Then
		MessageText = NStr("vi = 'Trước khi điền dự phòng, cần điền doanh nghiệp trong chứng từ';
							|ru = 'Перед заполнением резервов необходимо заполнить организацию документа';
							|en = 'Fill in the company before populating reserves'; fa = 'Fill in the company before populating reserves';
							|it = 'Prima di compilare le riserve è necessario compilare l''azienda del documento';
							|pl = 'Przed wypełnieniem rezerw należy wypełnić firmę dokumentu';
							|tr = 'Rezervler doldurulmadan önce belgenin düzenlenmesi gerçekleştirilmelidir'");
		CommonClientServer.MessageToUser(MessageText, Object.Ref, "Organization", "Object.Organization");
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.ReserveKind) Then
		MessageText = NStr("vi = 'Trước khi điền dự phòng, cần điền dạng dự phòng của chứng từ';
							|ru = 'Перед заполнением резервов необходимо заполнить вид резервов документа';
							|en = 'Populate document reserve kind before populating reserve'; fa = 'Populate document reserve kind before populating reserve';
							|it = 'Prima di compilare le riserve è necessario compilare il tipo delle riserve del documento';
							|pl = 'Przed wypełnienie rezerw należy wypełnić rodzaj rezerw dokumentu';
							|tr = 'Rezervleri doldurmadan önce, belge rezerv türlerini doldurmak gerekir'");
		CommonClientServer.MessageToUser(MessageText, Object.Ref, "ReserveKind", "Object.ReserveKind");
		Return;
	EndIf;
	
	If Object.Reserves.Count() Then
		NotificationParameters = New Structure("EventName", Command.Name);
		CleaningTSDescriptionOfAlert = New CallbackDescription("IssueOfClearingTheTablePartCompletion", ThisObject, NotificationParameters);
		QueryText = NStr("vi = 'Xóa bảng dự phòng trước khi điền theo sổ đăng ký?';
						|ru = 'Очистить таблицу резервов перед заполнением по данным регистра?';
						|en = 'Clear table of reserve before filling in according to register data?'; fa = 'Clear table of reserve before filling in according to register data?';
						|it = 'Eliminare i dati nella tabella delle riserve prima di compilare i dati del registro?';
						|pl = 'Oczyścić tabelę rezerw przed wypełnieniem według danych z rejestru?';
						|tr = 'Kayıt verileriyle doldurmadan önce rezerv tablosunu temizle?'");
		ShowQueryBox(CleaningTSDescriptionOfAlert, QueryText, QuestionDialogMode.YesNoCancel);
	Else
		FillTSWithRegisterData();
	EndIf;
		
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	Items.ReservesCurrentTAAmount.Visible         = False;
	Items.ReservesSetNewTAAmount.Visible = False;
	Items.ReservesNewAmountTA.Visible           = False;
	
	FillInServiceDetailsOfForm();
	
	FutureExpenseCommitmentsAccrualWriteOffLocalization.OnReadCreateAtServer(ThisObject);
	
	FillInSignOfDifferentFormationOfBUAndTA();
	SetElementProperties(ThisObject);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReservesNewAmountLocal.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Reserves.SetNewAmountLocal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không thay đổi>';
													|ru = '<без изменений>';
													|en = '<without changes>'; fa = '<without changes>';
													|it = '<senza modifiche>';
													|pl = '<bez zmian>';
													|tr = '<değişiklik olmadan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReservesNewAmountMan.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Reserves.SetNewAmountMan");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không thay đổi>';
													|ru = '<без изменений>';
													|en = '<without changes>'; fa = '<without changes>';
													|it = '<senza modifiche>';
													|pl = '<bez zmian>';
													|tr = '<değişiklik olmadan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReservesNewAmountTA.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Reserves.SetNewTAAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không thay đổi>';
													|ru = '<без изменений>';
													|en = '<without changes>'; fa = '<without changes>';
													|it = '<senza modifiche>';
													|pl = '<bez zmian>';
													|tr = '<değişiklik olmadan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReservesNewExecutionDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Reserves.SetNewExecutionDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không thay đổi>';
													|ru = '<без изменений>';
													|en = '<without changes>'; fa = '<without changes>';
													|it = '<senza modifiche>';
													|pl = '<bez zmian>';
													|tr = '<değişiklik olmadan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReservesNewAmountTA.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReservesSetNewTAAmount.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReservesCurrentTAAmount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Reserves.YouCanGenerateAccountingAndTaxAccountingProvisionsSeparately");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Setting the visibility of the amounts of upr. accounting depending on the FO.
	
	NamesOfManAccountingElements = New Array;
	NamesOfManAccountingElements.Add("ReservesCurrentAmountMan");
	NamesOfManAccountingElements.Add("ReservesSetNewAmountMan");
	NamesOfManAccountingElements.Add("ReservesNewAmountMan");
	
	Item = ConditionalAppearance.Items.Add();

	For Each NameOfAccountingManElement In NamesOfManAccountingElements Do
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(NameOfAccountingManElement);
		
	EndDo;

	BeginningOfMaUsagePeriod  = CalculationOfCostCached.StartDateOfManagementAccountingOfOrganizations();
	StartOfPU22UsagePeriod = CalculationOfCostCached.DateOfMigrationToBatchAccounting22();
	BatchAccountingVersion22 = CalculationOfCostCached.BatchAccountingVersion22();
	CompanyManagementAccounting = CalculationOfCostCached.CompanyManagementAccounting();
	
	OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Date");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = Max(StartOfPU22UsagePeriod, BeginningOfMaUsagePeriod);
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = BatchAccountingVersion22 And CompanyManagementAccounting;
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

// Sets the properties of form elements
//
// Parameters:
//  Form  - ClientApplicationForm - the form of the document
//
&AtClientAtServerNoContext
Procedure SetElementProperties(Form)
	
	Items = Form.Items;
	
	Items.DiscountRate.Visible = Form.DiscountingOfEstimatedObligation;
	
	Items.ReservesCompletionDate.Visible                = Form.DiscountingOfEstimatedObligation;
	Items.ReservesSetNewExecutionDate.Visible = Form.DiscountingOfEstimatedObligation;
	Items.ReservesNewExecutionDate.Visible           = Form.DiscountingOfEstimatedObligation;
	
	Items.ReservesCurrentTAAmount.Visible         = Not Form.TheseAreReservesOfLiquidationObligations;
	Items.ReservesSetNewTAAmount.Visible = Not Form.TheseAreReservesOfLiquidationObligations;
	Items.ReservesNewAmountTA.Visible           = Not Form.TheseAreReservesOfLiquidationObligations;
	
EndProcedure

#Region FillingInTablePart

&AtClient
Procedure LoadDataFromStartFile()
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "FutureExpenseCommitmentsAccrualWriteOff.Reserves";
	ImportParameters.Title = NStr("vi = 'Kết nhập dự phòng từ tệp';
									|ru = 'Загрузка резервов из файла';
									|en = 'Import reserves from file'; fa = 'Import reserves from file';
									|it = 'Download delle riserve dal file';
									|pl = 'Pobieranie rezerw z pliku';
									|tr = 'Rezervleri dosyadan yükleme'");
	ImportParameters.TemplateColumns = DescriptionOfTemplateColumnsToLoadFromFile();
	
	Notification = New CallbackDescription("DownloadDataFromAFileCompletion", ThisObject);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure DownloadDataFromAFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ImportedDataAddress = Undefined Then 
		Return;
	EndIf;
	
	UploadDataFromFileOnServer(ImportedDataAddress);
	
EndProcedure

&AtServer
Procedure UploadDataFromFileOnServer(ImportedDataAddress)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	
	LinesChanged = False;
	
	ProvisionObjects = Common.UnloadColumn(ImportedData, "ProvisionObject", True);
	
	ParametersForFillingReserves = New Structure("Date, Ref, Organization, ReserveKind");
	FillPropertyValues(ParametersForFillingReserves, Object);
	Result = Documents.FutureExpenseCommitmentsAccrualWriteOff.DataForFillingReserves(ParametersForFillingReserves, ProvisionObjects);
	
	Selection  = Result.Select();
	
	If ImportedData.Count() <> Selection.Count() Then
		Message = NStr("vi = 'Không phải đối với tất cả các dòng được kết nhập, đã tìm thấy sự tương ứng trong danh mục ""Đối tượng kế toán dự phòng"". Đã kết nhập không phải tất cả các dòng.';
						|ru = 'Не для всех загружаемых строк были найдены соответствия в справочнике ""Объекты учета резервов"". Не все строки были загружены.';
						|en = 'Matches were found not for all imported lines in the ""Provision objects"" catalog. Not all lines were imported.'; fa = 'Matches were found not for all imported lines in the ""Provision objects"" catalog. Not all lines were imported.';
						|it = 'Non per tutte le righe in download sono state trovate le corrispondenze nel catalogo ""Oggetti di registrazione delle riserve"". Non tutte le righe sono state caricate.';
						|pl = 'Nie dla wszystkich wierszy znaleziono zgodności w katalogu ""Объекты учета резервов"". Nie wszystkie wiersze zostały pobrane.';
						|tr = 'Yüklenen tüm satırlar ""Rezerv muhasebe nesneleri"" kataloğunda eşleştirilmedi. Tüm satırlar yüklenmedi.'");
		CommonClientServer.MessageToUser(Message, Object.Ref, "Object.Reserves");
	EndIf;
	
	While Selection.Next() Do
		TheStructureOfTheSearch = New Structure("ProvisionObject", Selection.ProvisionObject);
		ArrayOfRowsWithCurReservesObject = Object.Reserves.FindRows(TheStructureOfTheSearch);
		If ArrayOfRowsWithCurReservesObject.Count() Then
			ReserveLine = ArrayOfRowsWithCurReservesObject.Get(0);
		Else
			ReserveLine = Object.Reserves.Add();
			FillPropertyValues(ReserveLine, Selection);
			LinesChanged = True;
		EndIf;
		LoadedLines = ImportedData.FindRows(TheStructureOfTheSearch);
		For Each FoundRow In LoadedLines Do
			ReserveLine.NewAmountLocal = ReserveLine.NewAmountLocal + FoundRow.NewAmountLocal;
			ReserveLine.NewAmountMan = ReserveLine.NewAmountMan + FoundRow.NewAmountMan;
			ReserveLine.NewAmountTA = ReserveLine.NewAmountTA + FoundRow.NewAmountTA;
		EndDo;
		ReserveLine.SetNewAmountLocal = ValueIsFilled(ReserveLine.NewAmountLocal);
		ReserveLine.SetNewAmountMan = ValueIsFilled(ReserveLine.NewAmountMan);
		ReserveLine.SetNewTAAmount = ValueIsFilled(ReserveLine.NewAmountTA);
		LinesChanged = LinesChanged Or ValueIsFilled(ReserveLine.NewAmountLocal)
			Or ValueIsFilled(ReserveLine.NewAmountMan) Or ValueIsFilled(ReserveLine.NewAmountTA);
	EndDo;
	
	If LinesChanged Then
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure IssueOfClearingTheTablePartCompletion(Result, AdditionalParameters = Undefined) Export
	
	If Result = DialogReturnCode.Yes Then
		Object.Reserves.Clear();
	ElsIf Result = DialogReturnCode.Cancel And AdditionalParameters.EventName <> "ChangeAttributes" Then
		Return;
	EndIf;
	
	If AdditionalParameters.EventName = "Fill" Then
		FillTSWithRegisterData();
	ElsIf AdditionalParameters.EventName = "ImportDataFromFile" Then
		LoadDataFromStartFile();
	ElsIf AdditionalParameters.EventName = "ChangeAttributes" And Result <> DialogReturnCode.Yes Then
		Object.ReserveKind = AdditionalParameters.OldDetails.ReserveKind;
		Object.Organization = AdditionalParameters.OldDetails.Organization;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillTSWithRegisterData(RowID = Undefined)
	
	ProvisionObjects = New Array;
	// If the row ID is not defined, then we fill in the entire table part
	If RowID <> Undefined Then
		ReserveLine = Object.Reserves.FindByID(RowID);
		If ReserveLine <> Undefined Then
			// Let's check if there is such an accounting object in the list, and if there is, we will issue an error message:
			TheStructureOfTheSearch = New Structure("ProvisionObject", ReserveLine.ProvisionObject);
			ArrayOfRowsWithCurReservesObject = Object.Reserves.FindRows(TheStructureOfTheSearch);
			If ArrayOfRowsWithCurReservesObject.Count() > 1 Then
				For Each CurObjectString In ArrayOfRowsWithCurReservesObject Do
					If CurObjectString.GetID() <> RowID Then
						ErrorText = NStr("vi = 'Dòng với đối tượng kế toán dự trữ đã nhập, đã có trong chứng từ.';
										|ru = 'Строка с введенным объектом учета резервов уже есть в документе.';
										|en = 'Line with entered provision object already exists in the document.'; fa = 'Line with entered provision object already exists in the document.';
										|it = 'La riga con l''oggetto di registrazione inserito nel documento esiste già.';
										|pl = 'Wiersz z wprowadzonym obiektem ewidencji rezerw już jest w dokumencie.';
										|tr = 'Girilen rezerv muhasebesi nesnesine sahip satır belgede artık mevcuttur.'");
						Path = CommonClientServer.PathToTabularSection("Reserves", CurObjectString.LineNumber, "ProvisionObject");
						CommonClientServer.MessageToUser(ErrorText, Object.Ref, Path);
						ReserveLine.ProvisionObject = Catalogs.AccountingObjectsOfFutureExpenseCommitments.EmptyRef();
					EndIf;
				EndDo;
				Return;
			EndIf;
			ProvisionObjects.Add(ReserveLine.ProvisionObject);
		EndIf;
	EndIf;
	
	ParametersForFillingReserves = New Structure("Date, Ref, Organization, ReserveKind");
	FillPropertyValues(ParametersForFillingReserves, Object);
	Result = Documents.FutureExpenseCommitmentsAccrualWriteOff.DataForFillingReserves(ParametersForFillingReserves, ProvisionObjects);
	
	Selection  = Result.Select();
	
	If ProvisionObjects.Count() = 0 Then
		While Selection.Next() Do
			TheStructureOfTheSearch = New Structure("ProvisionObject", Selection.ProvisionObject);
			ArrayOfRowsWithCurReservesObject = Object.Reserves.FindRows(TheStructureOfTheSearch);
			If ArrayOfRowsWithCurReservesObject.Count() Then
				ReserveLine = ArrayOfRowsWithCurReservesObject.Get(0);
				FillPropertyValues(ReserveLine, Selection, "CurrentAmountLocal,CurrentTAAmount,CurrentAmountMan,CompletionDate");
			Else
				ReserveLine = Object.Reserves.Add();
				FillPropertyValues(ReserveLine, Selection);
			EndIf;
		EndDo;
	Else
		If Selection.Next() Then
			FillPropertyValues(ReserveLine, Selection);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckComplianceOfDetailsWithReserves()
	
	If Object.Reserves.Count() Then
		
		ProvisionObject = Undefined;
		For Each ReserveLine In Object.Reserves Do
			If ValueIsFilled(ReserveLine.ProvisionObject) Then
				ProvisionObject = ReserveLine.ProvisionObject;
				Break;
			EndIf;
		EndDo;
		
		If ProvisionObject = Undefined Then
			Return;
		EndIf;
		
		ReserveDetails = ReserveData(ProvisionObject);
		
		If ReserveDetails.Organization <> Object.Organization
			Or ReserveDetails.ReserveKind <> Object.ReserveKind Then
			
			NotificationParameters = New Structure("EventName, OldDetails", "ChangeAttributes", ReserveDetails);
			CleaningTSDescriptionOfAlert = New CallbackDescription("IssueOfClearingTheTablePartCompletion", ThisObject, NotificationParameters);
			QueryText = NStr("vi = 'Sẽ xóa bản dự phòng. Tiếp tục?';
							|ru = 'Таблица резервов будет очищена. Продолжить?';
							|en = 'The table will be cleared. Do you want to continue?'; fa = 'جدول پاک خواهد شد. آیا می‌خواهید ادامه دهید؟';
							|it = 'I dati nella tabella delle riserve saranno eliminati. Continuare?';
							|pl = 'Tabela rezerw będzie oczyszczona. Kontynuować?';
							|tr = 'Rezerv tablosu temizlenecek. Devam edilsin mi?'");
			ShowQueryBox(CleaningTSDescriptionOfAlert, QueryText, QuestionDialogMode.YesNoCancel);
			
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ReserveData(ProvisionObject)
	
	Return Common.ObjectAttributesValues(ProvisionObject, "Organization, ReserveKind");
	
EndFunction

// Fills in the tabular part of the Rezrva with the sign "Different formation of condoms is allowed"
//
// Parameters:
//  ProvisionObject  - CatalogRef.AccountingObjectsOfFutureExpenseCommitments - selection for the tabular part.
//                          If this parameter is omitted, it will be filled in for all reserve accounting objects
//
&AtServer
Procedure FillInSignOfDifferentFormationOfBUAndTA(ProvisionObject = Undefined)

	FilterParameters = New Structure;
	
	If ProvisionObject <> Undefined Then
		FilterParameters.Insert("ProvisionObject", ProvisionObject);
	EndIf;
	
	TableOfReserves = Object.Reserves.Unload(FilterParameters, "ProvisionObject");
	
	Query = New Query;
	Query.SetParameter("TableOfReserves", TableOfReserves);
	Query.Text = 
		"SELECT
		|	TableOfReserves.ProvisionObject AS ProvisionObject
		|INTO TableOfReserves
		|FROM
		|	&TableOfReserves AS TableOfReserves
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfReserves.ProvisionObject AS ProvisionObject,
		|	CAST(TableOfReserves.ProvisionObject AS Catalog.AccountingObjectsOfFutureExpenseCommitments).YouCanGenerateAccountingAndTaxAccountingProvisionsSeparately AS YouCanGenerateAccountingAndTaxAccountingProvisionsSeparately
		|FROM
		|	TableOfReserves AS TableOfReserves";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		FilterParameters = New Structure;
		FilterParameters.Insert("ProvisionObject", Selection.ProvisionObject);
		ReserveLines = Object.Reserves.FindRows(FilterParameters);
		
		For Each String In ReserveLines Do
			FillPropertyValues(String, Selection, "YouCanGenerateAccountingAndTaxAccountingProvisionsSeparately");
		EndDo;
	EndDo;
	
EndProcedure

&AtClient
Function DescriptionOfTemplateColumnsToLoadFromFile()
	
	TemplateColumns = New Array;
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("ProvisionObject",
		New TypeDescription("String",, New StringQualifiers(100)), NStr("vi = 'Đối tượng kế toán dự phòng';
																		|ru = 'Объект учета резервов';
																		|en = 'Reserve accounting object'; fa = 'موضوع حسابداری ذخیره';
																		|it = 'Oggetto di contabilità delle riserve';
																		|pl = 'Obiekt ewidencji zapasów';
																		|tr = 'Rezerv muhasebesi nesnesi'"));
	Column.ToolTip = NStr("vi = 'Tên gọi đối tượng kế toán dự phòng để tìm kiếm';
							|ru = 'Наименование объекта учета резервов для поиска';
							|en = 'Provision object name for search'; fa = 'Provision object name for search';
							|it = 'Наименование объекта учета резервов для поиска';
							|pl = 'Provision object name for search';
							|tr = 'Arama için muhasebe nesnesi rezervlerinin tanımı'");
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("NewAmountLocal",
		New TypeDescription("Number", New NumberQualifiers()), NStr("vi = 'Số tiền mới (quy định)';
																	|ru = 'Новая сумма (регл.)';
																	|en = 'New amount (local)'; fa = 'مبلغ جدید (محلی)';
																	|it = 'Nuovo importo (regol.)';
																	|pl = 'Nowa wartość (regl.)';
																	|tr = 'Yeni tutar (yerel)'"));
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("NewAmountMan",
		New TypeDescription("Number", New NumberQualifiers()), NStr("vi = 'Số tiền mới (quản trị)';
																	|ru = 'Новая сумма (упр.)';
																	|en = 'New amount, ENT'; fa = 'مبلغ جدید (مدیریت)';
																	|it = 'Nuovo importo (gest.)';
																	|pl = 'Nowa wartość (zarz.)';
																	|tr = 'Yeni tutar (yönetim)'"));
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("NewAmountTA",
		New TypeDescription("Number", New NumberQualifiers()), NStr("vi = 'Số tiền mới (KTTh)';
																	|ru = 'Новая сумма (НУ)';
																	|en = 'New amount (TA)'; fa = 'مبلغ جدید (مالیاتی)';
																	|it = 'Nuovo importo (Contabilità fiscale)';
																	|pl = 'Nowa wartość (ewidencja podatkowa)';
																	|tr = 'Yeni tutar (VM)'"));
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("NewExecutionDate",
		New TypeDescription("Date", New DateQualifiers(DateFractions.Date)), NStr("vi = 'Ngày mới thực hiện';
																					|ru = 'Новая дата исполнения';
																					|en = 'New execution date'; fa = 'تاریخ اجرای جدید';
																					|it = 'Новая дата исполнения';
																					|pl = 'New execution date';
																					|tr = 'Yeni yürütme tarihi'"));
	TemplateColumns.Add(Column);
	
	For Position = 0 To TemplateColumns.Count()-1 Do
		TemplateColumns[Position].Parent = Column.Name;
		TemplateColumns[Position].Position = Position;
	EndDo;
	
	Return TemplateColumns;
	
EndFunction

#EndRegion

&AtClient
Procedure PeriodPresentationStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod = Undefined Then
		Return;
	EndIf;
		
	Object.Date = EndOfMonth(SelectedPeriod);
	PeriodPresentation = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(Object.Date);
	
	FillFormAttributes();

	SetElementProperties(ThisObject);
	
EndProcedure

&AtServer
Procedure FillFormAttributes()
	
	FillInServiceDetailsOfForm();
	
	If DiscountingOfEstimatedObligation Then
		Object.DiscountRate = GetDiscountRateOfEstimatedObligation(
			Object.Organization, Object.ReserveKind, Object.Date);		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfForm()
	
	If ValueIsFilled(Object.ReserveKind) Then
		DetailsOfTypeOfReserves = Common.ObjectAttributesValues(
			Object.ReserveKind, "ProvisionDiscounting, ReserveType");
		DiscountingOfEstimatedObligation = DetailsOfTypeOfReserves.ProvisionDiscounting;
		
		If Not AccountingForDiscountingReservesIsUsed() Then
			DiscountingOfEstimatedObligation = False;	
		EndIf;
		
		TheseAreReservesOfLiquidationObligations = DetailsOfTypeOfReserves.ReserveType
			= PredefinedValue("Enum.TypesOfProvisionsAndContingentLiabilities.ResidualLiabilities");
	Else
		DiscountingOfEstimatedObligation = False;
		TheseAreReservesOfLiquidationObligations = False;
	EndIf;
	
EndProcedure

&AtServer
Function AccountingForDiscountingReservesIsUsed()
	
	Used = False;
	
	If ValueIsFilled(Object.Organization) And ValueIsFilled(Object.Date) 
		And DiscountingOfEstimatedObligation Then
		
		Used = FutureExpenseCommitments.AccountingForDiscountingReservesIsUsed(EndOfMonth(Object.Date), 
			Object.Organization);
	EndIf;
		
	Return Used;
	
EndFunction

&AtServerNoContext
Function GetDiscountRateOfEstimatedObligation(Organization, ReserveKind, Date)
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	ProvisionDiscountingRates.DiscountRate AS DiscountRate
		|FROM
		|	InformationRegister.ProvisionDiscountingRates.SliceLast(&Date, Organization = &Organization
		|	AND ReserveKind = &ReserveKind) AS ProvisionDiscountingRates";
	
	Query.SetParameter("Date", Date);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("ReserveKind", ReserveKind);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		Return Selection.DiscountRate;
	Else
		Return 0;
	EndIf;
	
EndFunction

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
