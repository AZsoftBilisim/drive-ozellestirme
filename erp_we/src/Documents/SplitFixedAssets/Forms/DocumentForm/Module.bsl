
#Region Variables

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	InitializingFormWhenCreatingItOnServer();
	
	ItemsAndDimensionsSelectionParameters = Documents.SplitFixedAssets.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	#Region StandardSubsystems
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.FilesOperations
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
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

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	ItemsAndDimensionsSelectionParameters = Documents.SplitFixedAssets.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If WriteParameters.WriteMode = DocumentWriteMode.UndoPosting Then
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	EndIf; 
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting And Not DataOnTraceableGoodsIsCorrect() Then
		Cancel = True;	
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	
	Notify("Write_SplitFixedAssets", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInInformationInBasement();
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_SplitFixedAssets" 
		And Source <> Object.Ref Then
		FillInInformationInBasement();
	EndIf; 
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	If ChoiceSource.FormName = AccountingForTraceableGoodsClientServerLocalization.NameOfFormOfSelectionForRemainsOfTraceableGoodsVos() Then
		
		GetTraceableItemsFromStorage(ValueSelected);
				
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region PageGeneral

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	BusinessOperationWhenChangingOnServer();	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure RecordInLocalAccountingOnChange(Item)
	
	If Not Object.RecordInLocalAccounting And Not Object.RecordInManAccounting Then
		Object.RecordInLocalAccounting = True;
	EndIf;
	
	ConfigureDependentFormElementsOnServer("RecordInLocalAccounting");

EndProcedure

&AtClient
Procedure RecordInManAccountingOnChange(Item)
	
	If Not Object.RecordInLocalAccounting And Not Object.RecordInManAccounting Then
		Object.RecordInManAccounting = True;
	EndIf;

	ConfigureDependentFormElementsOnServer("RecordInManAccounting");

EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	InitializingFormWhenCreatingItOnServer();
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure FixedAssetOnChange(Item)
	
	CheckChoiceOfFixedAssets();
	
EndProcedure

&AtClient
Procedure OptionForAccountingForComponentNodesONChange(Item)
	
	Object.WriteOffNodes = (NodeAccountingOption = 1);
	
	OptionToAccountForComponentNodesOnChangesAtServer();
	
EndProcedure

&AtClient
Procedure DocumentInformationInAnotherAccountingURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "#CreateDocument" Then
		StandardProcessing = False;
		FormParameters = New Structure("Basis", Object.Ref);
		OpenForm("Document.SplitFixedAssets.ObjectForm", FormParameters);
	EndIf; 
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.Pages.ChildItems.TraceableProductsPage Then
		Items.TraceableGoodsFixedAsset.ChoiceList.LoadValues(AvailableFixedAssets());
	EndIf;
	
EndProcedure

#EndRegion

#Region PageExpenseRecord

&AtClient
Procedure ExpenseItemAccountingOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemAccounting);
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure ExpenseItemAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionAccountingAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionAccountingTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseItemManagementAccountingOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemManagementAccounting);
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure ExpenseItemManagementAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionManagementAccountingStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionManagementAccountingAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesDimensionManagementAccountingTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

#EndRegion

#Region StandardSubsystems

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersFA

&AtClient
Procedure FASelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	ChangeFAString();
	
EndProcedure

&AtClient
Procedure FABeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	ChangeFAString(True, Copy);
	
EndProcedure

&AtClient
Procedure FABeforeRowChange(Item, Cancel)
	
	If Item.CurrentItem <> Items.StringBaseNumber Then
		Cancel = True;
		ChangeFAString();
	EndIf; 
	
EndProcedure

&AtClient
Procedure FAChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	NonCurrentAssetsClientServer.ProcessingElementSelection(Object.FA, "FixedAsset", ValueSelected);
	
EndProcedure

&AtClient
Procedure FAOnStartEdit(Item, NewRow, Copy)
	
	FillInValuesOfFADetailsBeforeChange();
	
EndProcedure

&AtClient
Procedure FAFixedAssetOnChange(Item)
	
	FAIsPrimaryMeansWhenChangingOnServer();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	
	PerformanceMonitorClient.TimeMeasurement("Catalog.Assets.ChoiceForm");

	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.FAFixedAsset, ThisObject);
	
	ThisIsAllocationOfComponentNodes = 
		Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation");
	
	ArrayOfFATypes = New Array;
	If ThisIsAllocationOfComponentNodes Then
		ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.Node"));
		ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.DepreciationComponent"));
	Else
		ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.Asset"));
		ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.GroupFA"));
		ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.CapitalExpenditureInLeasedAssets"));
	EndIf;
	
	If Not PickingParameters.Property("Filter") Then
		PickingParameters.Insert("Filter", New Structure);
	EndIf;
	
	PickingParameters.Filter.Insert("OSType", ArrayOfFATypes);
	
	OpenForm("Catalog.Assets.ChoiceForm", 
					PickingParameters, Items.FA,,,,, 
					FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure ChangeInformation(Command)
	
	ChangeFAString();
	
EndProcedure

&AtClient
Procedure GenerateStatement(Command)
	
	AvailableFixedAssets = AvailableFixedAssets();
	AvailableFixedAssets.Add(Object.FixedAsset);
	
	Filter = New Structure;
    Filter.Insert("Organization", Object.Organization);   
	Filter.Insert("FixedAsset", AvailableFixedAssets);
	ReportPeriod = New StandardPeriod();
	ReportPeriod.StartDate = BegOfDay(Object.Date);
	ReportPeriod.EndDate = EndOfDay(Object.Date);
 	Filter.Insert("Period", ReportPeriod);
	FormParameters = New Structure("Filter, GenerateOnOpen, VariantKey", Filter, True, "Main");	
	AccountingForTraceableGoodsClientLocalization.GenerateStatement(FormParameters);
	
EndProcedure

&AtClient
Procedure InformationOnBalanceOfTraceableGoods(Command)
			
	If Object.TraceableGoods.Count()>0 Then
		
		QueryText = NStr("vi = 'Trước khi điền, phần bảng sẽ bị xóa, tiếp tục?';
						|ru = 'Перед заполнением табличная часть документа будет очищена, продолжить?';
						|en = 'The document table will be cleared before filling in. Do you want to continue?'; fa = 'The document table will be cleared before filling in. Do you want to continue?';
						|it = 'Prima del completamento, la parte tabellare del documento sarà cancellata. Continuare?';
						|pl = 'Przed wypełnieniem sekcja tabelaryczna zostanie wyczyszczona, kontynuować?';
						|tr = 'Doldurmadan önce, belgenin tablo kısmı temizlenecek, devam edecek mi?'");
		Notification = New CallbackDescription("AnswerToQuestionAboutClearingTablePart", ThisObject);
		
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
		
	Else
		
		PerformanceMonitorClient.TimeMeasurement("Document.SplitFixedAssets.Form.DocumentForm.InformationOnBalanceOfTraceableGoods");
		
		FillInByRemainingTraceableItemsOnServer();	
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchForTraceableProductBalances(Command)
		
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Company';
																	|tr = 'İş yeri'"));
	Notification = New CallbackDescription("SelectionByStockCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisObject, Notification, CheckParameters);

EndProcedure

#Region AttachableCommands

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
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

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()

	InitializingFormWhenCreatingItOnServer();
	
	FixedAssetBeforeChange = Object.FixedAsset;
	
	FillInInformationInBasement();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure InitializingFormWhenCreatingItOnServer()
	
	NodeAccountingOption = ?(Object.WriteOffNodes, 1, 0);
	
	Items.TraceableGoodsFixedAsset.ChoiceList.LoadValues(AvailableFixedAssets());	

	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, 
		Items.TraceableGoodsCCDNumber.Name, True);

	BusinessOperationWhenChangingOnServer();
	
EndProcedure
 
&AtClient
Procedure ConfigureDependentFormElements(Val ChangedDetailsOrElement = "")

	If TypeOf(ChangedDetailsOrElement) = Type("String") Then
		ChangedBankingDetails = ChangedDetailsOrElement;
	Else
		ChangedBankingDetails = ChangedDetailsOrElement.Name;
	EndIf;
	
	ConfigureDependentFormElementsOnServer(ChangedBankingDetails)

EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplianceCAAccountingIsKept",
			NonCurrentAssetsInternal.ComplianceCAAccountingIsKept(),
			FormServiceParameters);

	EndIf;

	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		NonCurrentAssets.SetParametersOfFunctionalOptionsOfObjectForm(ThisObject, Object.Organization, Object.Date);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		DetermineCostOfOriginalFA();
		AccountingForTraceableGoodsLocalization.SetVisibilityOfTraceableGoodsPage(ThisObject, Object.Date);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"FALocalAccountingIsConductedIndependently",
			AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()))),
			FormServiceParameters);
			
		Items.RecordInLocalAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.RecordInManAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.DecorationIsReflectionOption.Visible = Items.RecordInLocalAccounting.Visible Or Items.RecordInManAccounting.Visible;
		
		If Not FormServiceParameters.FALocalAccountingIsConductedIndependently 
			And Not UpdateAll Then

			Object.RecordInLocalAccounting = True;
			Object.RecordInManAccounting = True;
		EndIf;
		
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessOperation")
		Or UpdateAll Then
		
		If BusinessTransactionBeforeTheChange <> PredefinedValue("Enum.BusinessTransactions.EmptyRef")
			And (Object.BusinessOperation = Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation
				Or BusinessTransactionBeforeTheChange = Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
			And Object.BusinessOperation <> BusinessTransactionBeforeTheChange Then
			Object.FA.Clear();
		EndIf;
		
		BusinessTransactionBeforeTheChange = Object.BusinessOperation;
		
		//
		InformationTitle = "";
		
		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CompleteSplitFixedAssets") Then
			InformationTitle =
				NStr("vi = 'Khi bỏ đóng bộ hoàn toàn, tổng giá trị tiếp nhận vào kế toán của tài sản cố định phải bằng giá trị tài sản cố định ban đầu';
					|ru = 'При полной разукомплектации общая стоимость принимаемых к учету основных средств должна быть равна стоимости исходного основного средства';
					|en = 'In case of complete splitting, the total value of recognized fixed assets must be equal to the value of the original fixed asset'; fa = 'In case of complete splitting, the total value of recognized fixed assets must be equal to the value of the original fixed asset';
					|it = 'Con lo smantellamento completo il costo totale dei cespiti da registrare in contabilità deve essere pari al costo del cespite iniziale';
					|pl = 'Przy pełnym zdekompletowaniu łączna wartość przyjmowanych do ewidencji środków trwałych, powinna być równa wartości pierwotnego środka trwałego';
					|tr = 'Tamamen söküm durumunda, dikkate alınan sabit kıymetlerin toplam değeri, orijinal sabit kıymetin değerine eşit olmalıdır'");
		ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PartialFixedAssetsSplit") Then
			InformationTitle =
				NStr("vi = 'Nếu bỏ đóng bộ một phần thì giá trị của các tài sản cố định được tiếp nhận vào kế toán không được vượt quá giá trị tài sản cố định ban đầu';
					|ru = 'При частичной разукомплектации стоимость принимаемых к учету основных средств не должна превышать стоимость исходного основного средства';
					|en = 'In case of partial splitting, the value of recognized fixed assets must not exceed the value of the original fixed asset'; fa = 'In case of partial splitting, the value of recognized fixed assets must not exceed the value of the original fixed asset';
					|it = 'Con lo smantellamento parziale il prezzo dei cespiti da registrare in contabilità non deve essere superiore al prezzo del cespite iniziale';
					|pl = 'Przy częściowym zdekompletowaniu wartość, przyjętych do ewidencji środków trwałych, nie powinna przekraczać wartość pierwotnego środka trwałego';
					|tr = 'Kısmi çıkarımda, sabit kıymetlerin muhasebeleştirilmesi için alınan maliyet, orijinal sabit kıymetlerin maliyetini aşmamalıdır'");
		ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation") Then
			InformationTitle =
				NStr("vi = 'Nếu chọn các bộ phận và thành phần khấu hao thì giá trị các tài sản cố định được tiếp nhận vào kế toán không được vượt quá giá trị tài sản cố định ban đầu';
					|ru = 'При выделении узлов и компонентов амортизации стоимость принимаемых к учету основных средств не должна превышать стоимость исходного основного средства';
					|en = 'When splitting sub-assets and components of depreciation, the value of recognized fixed assets must not exceed the value of the original fixed asset'; fa = 'When splitting sub-assets and components of depreciation, the value of recognized fixed assets must not exceed the value of the original fixed asset';
					|it = 'Selezionando i nodi e le componenti di ammortamento, il costo dei cespiti inclusi in contabilità non deve essere superiore al costo del cespite originario';
					|pl = 'Przy wydzieleniu węzłów i komponentów amortyzacji wartość przyjmowanych do ewidencji środków trwałych nie powinna przekraczać wartości źródłowego środka trwałego';
					|tr = 'Amortisman birimleri ve bileşenleri tahsis edilirken, dikkate alınan sabit kıymetlerin değeri, orijinal sabit kıymetin değerini aşmamalıdır'");
		EndIf;
		
		Items.InformationAmount.Title = InformationTitle;

		//
		AvailableFATypes = New Array;
		AvailableFATypes.Add(Enums.FATypes.Asset);
		AvailableFATypes.Add(Enums.FATypes.GroupFA);
		If Object.BusinessOperation <> Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation Then
			AvailableFATypes.Add(Enums.FATypes.CapitalExpenditureInLeasedAssets);
		EndIf;
		
		NewSelectionOptions = NonCurrentAssetsInternal.ChoiceParameters(Items.FixedAsset.ChoiceParameters, "Filter.OSType");
		SelectionParameterFAType = New ChoiceParameter("Filter.OSType", AvailableFATypes);
		NewSelectionOptions.Add(SelectionParameterFAType);
		Items.FixedAsset.ChoiceParameters = New FixedArray(NewSelectionOptions);
		
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessOperation") 
		Or StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("RecordInManAccounting") 
		Or UpdateAll Then
		
		PropertyValue = 
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation")
			And Object.RecordInLocalAccounting;
		
		Items.ExpenseItemAccounting.Visible = PropertyValue;
		Items.ExpensesDimensionAccounting.Visible = PropertyValue;
		
		//	
		PropertyValue = 
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation")
			And Object.RecordInManAccounting;
			
		Items.ExpenseItemManagementAccounting.Visible = PropertyValue;
		Items.ExpensesDimensionManagementAccounting.Visible = PropertyValue;
			
	EndIf;
	
	If StructureOfChangedProps.Property("FixedAsset")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("BusinessOperation")
		Or UpdateAll Then
		
		FillInInformationForReflectingExpenses();
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting") 
		Or StructureOfChangedProps.Property("RecordInManAccounting") 
		Or StructureOfChangedProps.Property("AccountingProcedureAC") 
		Or StructureOfChangedProps.Property("AccountingProcedureMA") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("FixedAsset")
		Or StructureOfChangedProps.Property("ExpenseItemAccounting")
		Or StructureOfChangedProps.Property("ExpenseItemManagementAccounting")
		Or StructureOfChangedProps.Property("BusinessOperation")
		Or UpdateAll Then
		
		PropertyValue =
			OwnerSArticlesAreNotDefined
			And (Items.ExpenseItemAccounting.Visible
				Or Items.ExpenseItemManagementAccounting.Visible)
			And (Not ValueIsFilled(Object.ExpenseItemAccounting)
					And Object.RecordInLocalAccounting
				Or Not ValueIsFilled(Object.ExpenseItemManagementAccounting)
					And Object.RecordInManAccounting);
		
		Items.CostReflectionInformationPicture.Visible = PropertyValue;
		Items.CostReflectionInformationText.Visible = PropertyValue;
		
	EndIf;
	
	If StructureOfChangedProps.Property("FixedAsset")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("BusinessOperation")
		Or UpdateAll Then
		
		ThereAreNodes = False;
		If Object.BusinessOperation = Enums.BusinessTransactions.CompleteSplitFixedAssets Then
			
			ThereAreNodes = NonCurrentAssets.ThereAreNodes(
				CommonClientServer.ValueInArray(Object.FixedAsset), 
				Object.Ref, 
				Object.Date);

			If ThereAreNodes
				And Not Items.NodeAccountingOption.Visible Then
				
				If Not UpdateAll Then
					Object.WriteOffNodes = True;
				EndIf;
				
				Items.NodeAccountingOption.Visible = True;
				
			EndIf;
			
		EndIf;
		
		If Not ThereAreNodes Then
			Object.WriteOffNodes = False;
			Items.NodeAccountingOption.Visible = False;
		EndIf;
		
	EndIf;
	
	SplitFixedAssetsLocalization.ConfigureDependentFormElements(ThisObject, StructureOfChangedProps);
			
EndProcedure

&AtServer
Procedure FillInInformationInBasement()

	If (Not Object.RecordInManAccounting
			Or Not Object.RecordInLocalAccounting)
		And NonCurrentAssetsInternal.ComplianceCAAccountingIsKept()
		And ValueIsFilled(Object.FixedAsset) Then
		
		// We will not display the inscription that can be created in another account if the OS is accepted for accounting in only one of the accounts.
		InitialInformation = Catalogs.Assets.InitialInformation(Object.FixedAsset, Object.Date);
		
		ShowInformationIfNotCreated = Object.RecordInLocalAccounting 
					And InitialInformation.StateOfTheUU = Enums.FixedAssetsStates.Recognized_ 
				Or Object.RecordInManAccounting 
					And InitialInformation.BUState = Enums.FixedAssetsStates.Recognized_;
					
	Else
		ShowInformationIfNotCreated = True;
	EndIf;
				
	LabelTitle = NonCurrentAssetsInternal.DocumentInformationInAnotherAccounting(Object, ShowInformationIfNotCreated);

	If LabelTitle.Count() <> 0 Then
		Items.Information.Title = New FormattedString(LabelTitle);
		Items.PictureInformation.Visible = True;
		Items.Information.Visible = True;
	Else
		Items.PictureInformation.Visible = False;
		Items.Information.Visible = False;
	EndIf; 
	
EndProcedure

&AtClient
Procedure FillInValuesOfFADetailsBeforeChange()

	AttributesValuesBeforeChange = New Structure;
	AttributesValuesBeforeChange.Insert("CostInManagementAccounting", 0);
	AttributesValuesBeforeChange.Insert("CostInAccounting", 0);
	AttributesValuesBeforeChange.Insert("CostInTaxAccounting", 0);
	
	CurrentData = Items.FA.CurrentData;
	If CurrentData <> Undefined Then
		FillPropertyValues(AttributesValuesBeforeChange, CurrentData);
	EndIf;
	
	FAAttributeValuesBeforeChange = New FixedStructure(AttributesValuesBeforeChange);

EndProcedure

&AtClient
Procedure CheckChoiceOfFixedAssets()

	CheckResult = ParametersForSelectingFixedAssets(Object);
	
	If CheckResult.ProblematicFA.Count() <> 0 Then
		
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
													|ru = 'Продолжить';
													|en = 'Continue'; fa = 'ادامه';
													|it = 'Continuare';
													|pl = 'Continue';
													|tr = 'Devam'"));
		ButtonsList.Add(DialogReturnCode.Cancel);

		QueryText = NStr("vi = 'Các tài sản cố định không cùng loại sẽ bị xóa khỏi phần bảng.
                             |Tiếp tục?';
                             |ru = 'Из табличной части будут удалены не однотипные основные средства.
                             |Продолжить?';
                             |en = 'Fixed assets that are not of the same type will be removed from the table.
                             |Continue?'; fa = 'Fixed assets that are not of the same type will be removed from the table.
                             |Continue?';
                             |it = 'Fixed assets that are not of the same type will be removed from the table.
                             |Continue?';
                             |pl = 'Fixed assets that are not of the same type will be removed from the table.
                             |Continue?';
                             |tr = 'Tablo bölümünden aynı türde olmayan sabit kıymetler silinecek.
                             | Devam edilsin mi?'");
		
		CallbackDescription = New CallbackDescription("CheckChoiceOfFixedAssetsCompletion", ThisObject, CheckResult);
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
		
	Else
		
		CheckChoiceOfFixedAssetsCompletion(DialogReturnCode.Yes, CheckResult);
		
	EndIf; 

EndProcedure

&AtClientAtServerNoContext
Function ParametersForSelectingFixedAssets(Object)

	ListOfFA = New Array;
	For Each RowData In Object.FA Do
		If ValueIsFilled(RowData.FixedAsset) Then
			ListOfFA.Add(RowData.FixedAsset);
		EndIf;
	EndDo;
	
	ParametersForSelectingFixedAssets = ParametersForSelectingFixedAssetsOnServer(Object.FixedAsset, ListOfFA, Object.Date);

	Return ParametersForSelectingFixedAssets;
	
EndFunction

&AtServerNoContext
Function ParametersForSelectingFixedAssetsOnServer(Val FixedAsset, Val ListOfFA, Val Date)

	Return Documents.SplitFixedAssets.CheckSelectionOfFixedAssets(FixedAsset, ListOfFA, Date);

EndFunction

&AtClient
Procedure CheckChoiceOfFixedAssetsCompletion(QuestionResult, CheckResult) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Object.FixedAsset = FixedAssetBeforeChange;
		Return;
	EndIf;
	
	CheckSelectionOfMainCompletionToolOnServer(CheckResult);
	
EndProcedure

&AtServer
Procedure CheckSelectionOfMainCompletionToolOnServer(Val CheckResult)

	FixedAssetBeforeChange = Object.FixedAsset;
	
	LinesToDelete = New Array;
	For Each RowData In Object.FA Do
		If CheckResult.ProblematicFA.Find(RowData.FixedAsset) <> Undefined Then
			LinesToDelete.Add(RowData);
		EndIf; 
	EndDo; 

	For Each RowData In LinesToDelete Do
		Object.FA.Delete(RowData);
	EndDo; 
	
	FillInHeaderForSelectedFA();

	DetermineCostOfOriginalFA();
	
	FillInInformationInBasement();

	ConfigureDependentFormElementsOnServer("FixedAsset");
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure DetermineCostOfOriginalFA()

	CostInManagementAccounting = 0;
	CostInAccounting = 0;
	CostInTaxAccounting = 0;
	CostPermanentDifference = 0;
	
	If Not ValueIsFilled(Object.FixedAsset) Then
		Return;
	EndIf; 
	
	QueryText = 
	"SELECT
	|	FACostBalance.CostBalance AS CostInManagementAccounting,
	|	FACostBalance.LocalCostBalance + FACostBalance.CostTargetFinancingBalance AS CostInAccounting,
	|	FACostBalance.CostInTaxAccountingBalance + FACostBalance.CostTargetFinancingTABalance AS CostInTaxAccounting,
	|	FACostBalance.CostPermanentDifferenceBalance + FACostBalance.CostTargetFinancingPDBalance AS CostPermanentDifference
	|FROM
	|	AccumulationRegister.FACost.Balance(&PeriodLimit, FixedAsset = &FixedAsset) AS FACostBalance";
	
	Query = New Query(QueryText);
	Query.SetParameter("FixedAsset", Object.FixedAsset);
	
	PeriodLimit = New Boundary(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()), BoundaryType.Excluding);
	Query.SetParameter("PeriodLimit", PeriodLimit);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		CostInManagementAccounting = Selection.CostInManagementAccounting;
		CostInAccounting = Selection.CostInAccounting;
		CostInTaxAccounting = Selection.CostInTaxAccounting;
		CostPermanentDifference = Selection.CostPermanentDifference;
	EndIf;

EndProcedure
 
&AtServer
Procedure FillInHeaderForSelectedFA()

	ChangedBankingDetails = "";
	NonCurrentAssetsInternal.FillInHeaderForSelectedFA(
		"Organization,Department", 
		Undefined, 
		Object, 
		ChangedBankingDetails);
	
	If ChangedBankingDetails <> "" Then
		ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeFAString(NewRow = False, Copy = False)
	
	CurrentData = Items.FA.CurrentData;
	If CurrentData = Undefined And Not Copy And Not NewRow Then
		Return;
	EndIf; 
	
	FormParameters = PrepareParametersForOpeningForm();
	FormParameters.Insert("NewRow", NewRow);
	FormParameters.Insert("Copy", Copy);
	
	RowID = Undefined;
	If CurrentData <> Undefined Then
		RowID = CurrentData.GetID();
		If Not NewRow Or Copy Then
			AttributesValues = New Structure(FormParameters.AttributesToSave);
			FillPropertyValues(AttributesValues, CurrentData);
			FormParameters.Insert("AttributesValues", AttributesValues);
		EndIf; 
		If Copy Then
			AttributesValues.FixedAsset = Undefined;
		EndIf;
	EndIf;
	
	CallbackDescriptionOnClose = New CallbackDescription("AdvancedLineEditingCompletion", ThisObject,
		New Structure("NewRow, RowID", NewRow, RowID));
	
	OpenForm("Document.SplitFixedAssets.Form.EditingFARow", FormParameters, ThisObject,,,,
		CallbackDescriptionOnClose, FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtServer
Function PrepareParametersForOpeningForm()
	
	FormParameters = New Structure;
	FormParameters.Insert("AttributesToSave",  GetSavedLineEditingDetails());
	FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
	FormParameters.Insert("RecordInManAccounting",     Object.RecordInManAccounting);
	FormParameters.Insert("RecordInLocalAccounting",    Object.RecordInLocalAccounting);
	FormParameters.Insert("Organization",           Object.Organization);
	FormParameters.Insert("Date",                  Object.Date);
	
	ListOfFA = New Array;
	For Each RowData In Object.FA Do
		If ValueIsFilled(RowData.FixedAsset) Then
			ListOfFA.Add(RowData.FixedAsset);
		EndIf;
	EndDo;

	FormParameters.Insert("ListOfFA", ListOfFA);
	
	Return FormParameters;
	
EndFunction

&AtServerNoContext
Function GetSavedLineEditingDetails()

	AttributesToSave =
	"FixedAsset,
	|CostInAccounting,
	|CostInTaxAccounting,
	|CostPermanentDifference,
	|CostTemporaryDifference,
	|CostInManagementAccounting,
	|ResidualValueMan,
	|ResidualValueLocal,
	|AnnualDepreciationRateAccounting,
	|DepreciationSchedule,
	|FinancialAccountingGroup,
	|AccelerationFactorAccounting,
	|AccelerationFactorManagementAccounting,
	|DepreciationMethodAccounting,
	|DepreciationAccrualMethodManagementAccounting,
	|UsefulLifeAccounting,
	|UsefulLifeManagementAccounting,
	|RunningTimeValue,
	|EstimatedRunningTime";
	
	Return AttributesToSave;

EndFunction

&AtClient
Procedure AdvancedLineEditingCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	AdvancedEditingOfCompletionLineOnServer(Result, AdditionalParameters);

EndProcedure

&AtServer
Procedure AdvancedEditingOfCompletionLineOnServer(Val ClosingResult, Val AdditionalParameters)

	Modified = True;

	If AdditionalParameters.NewRow Then
		TableRow = Object.FA.Add();
	Else
		TableRow = Object.FA.FindByID(AdditionalParameters.RowID);
	EndIf;
	
	FillPropertyValues(TableRow, ClosingResult);
		
EndProcedure

&AtServer
Function AvailableFixedAssets()
	
	AvailableFixedAssets = Object.FA.Unload(,"FixedAsset").UnloadColumn("FixedAsset");
	NodesList = NonCurrentAssets.GetFANodes(AvailableFixedAssets, Object.Date);
	
	While NodesList.Next() Do
		AvailableFixedAssets.Add(NodesList.FixedAsset);
	EndDo;
		
	Return AvailableFixedAssets;
	
EndFunction

&AtClient
Function DataOnTraceableGoodsIsCorrect()
	
	DataCorrect = True;
	FixedAssets = AvailableFixedAssets();
	For Each Page1 In Object.TraceableGoods Do
		If FixedAssets.Find(Page1.FixedAsset) = Undefined Then
			MessageString = NStr("vi = 'Dữ liệu phần bảng hàng hóa có truy xuất nguồn gốc không tương ứng với dữ liệu về tài sản cố định tiếp nhận vào kế toán. 
			|Giá trị %1 không có trong tài sản cố định tiếp nhận vào kế toán.';
			|ru = 'Данные табличной части прослеживаемых товаров не соответствуют данным о принимаемых к учету основных средствах. 
			|Значение %1 отсутствует в принимаемых к учету основных средствах.';
			|en = 'Data of the traceable goods table does not correspond to the data of fixed assets to recognize. 
			|The %1 value is missing in the fixed assets to recognize.'; fa = 'Data of the traceable goods table does not correspond to the data of fixed assets to recognize. 
			|The %1 value is missing in the fixed assets to recognize.';
			|it = 'I dati della parte tabellare degli articoli tracciabili non corrispondono ai dati sulle immobilizzazioni ricevibili in contabilità. 
			|Il valore %1 manca nelle immobilizzazioni ricevibili in contabilità.';
			|pl = 'Dane sekcji tabelarycznej towarów identyfikowalnych nie są zgodne z danymi o przyjmowanych do ewidencji środkach trwałych. 
			|Brak wartości %1 w sekcji tabelarycznej przyjmowanych do ewidencji środkach trwałych.';
			|tr = 'İzlenebilir malların tablo kısmındaki veriler, muhasebe için kabul edilen sabit kıymetlerdeki verilerle uyuşmamaktadır. 
			| Muhasebeleştirilecek sabit kıymetlerde %1 değeri eksik.'"); 
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, Page1.FixedAsset);
			CommonClient.MessageToUser(MessageString,Object.Ref);
			DataCorrect = False;	
		EndIf;	
	EndDo;

	Return DataCorrect;
EndFunction

&AtServer
Procedure FillInByRemainingTraceableItemsOnServer()
	
	FixedAssets = New Array();
	FixedAssets.Add(Object.FixedAsset);
	
	AccountingForTraceableGoodsLocalization.FillInTabularPartOnRemainsOfTraceableGoods(Object, FixedAssets, True);
	
EndProcedure

&AtClient
Procedure AnswerToQuestionAboutClearingTablePart(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.No Then
		Return;
	EndIf;
	PerformanceMonitorClient.TimeMeasurement(
	"Document.SplitFixedAssets.Form.DocumentForm.InformationOnBalanceOfTraceableGoods");
	FillInByRemainingTraceableItemsOnServer();
	
EndProcedure 

&AtServer
Procedure FAIsPrimaryMeansWhenChangingOnServer()
	
	Items.TraceableGoodsFixedAsset.ChoiceList.LoadValues(AvailableFixedAssets());	
	
EndProcedure

&AtServer
Function AddressInStorage()
	
	Tab = New ValueTable();
	
	AddressOfTraceableGoodsBalances = PutToTempStorage(
		Tab,
		UUID);

	Return AddressOfTraceableGoodsBalances; 
	
EndFunction

&AtClient
Procedure SelectionByStockCompletion(Result, AdditionalParameters) Export
	
	PerformanceMonitorClient.TimeMeasurement(
	"Document.SplitFixedAssets.Form.DocumentForm.SearchForTraceableProductBalances");
	
	AddressOfTraceableGoodsBalances = AddressInStorage();

	PickingParameters = New Structure;
	PickingParameters.Insert("Organization", Object.Organization);
	PickingParameters.Insert("AddressOfTraceableGoodsBalances", AddressOfTraceableGoodsBalances);
	FixedAssets = New ValueList();
	FixedAssets.Add(Object.FixedAsset);
	PickingParameters.Insert("FixedAssets", FixedAssets);
	AccountingForTraceableGoodsClientLocalization.OpenSelectionForm(PickingParameters, ThisObject);
	
EndProcedure
	
&AtServer
Procedure GetTraceableItemsFromStorage(AddressOfTraceableGoodsBalances)
	
	BalanceTable = GetFromTempStorage(AddressOfTraceableGoodsBalances); // ValueTable
	BalanceTable.Columns.Delete("FixedAsset");
	Object.TraceableGoods.Load(BalanceTable);	

EndProcedure

&AtServer
Procedure FillInInformationForReflectingExpenses()
	
	OwnerSArticlesAreNotDefined = False;
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT TOP 1
	|	Assets.Ref
	|FROM
	|	Catalog.Assets AS Assets
	|	
	|		LEFT JOIN InformationRegister.AccountingProcedureForOSBU.SliceLast(
	|			&Date,
	|			&RecordInLocalAccounting
	|			AND Organization = &Organization
	|			AND FixedAsset IN (&ListOfFA)) AS AccountingProcedureForOSBU
	|		ON AccountingProcedureForOSBU.FixedAsset = Assets.Ref
	|		
	|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
	|			&Date,
	|			&RecordInManAccounting
	|			AND Organization = &Organization
	|			AND FixedAsset IN (&ListOfFA)) AS FixedAssetsAccountingProcedureManagementAccounting
	|		ON FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = Assets.Ref		
	|		
	|WHERE
	|	Assets.Ref IN (&ListOfFA)
	|	AND (&RecordInLocalAccounting 
	|			AND AccountingProcedureForOSBU.ExpenseItemAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|		OR &RecordInManAccounting
	|			AND FixedAssetsAccountingProcedureManagementAccounting.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef))
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", Object.Date);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("RecordInLocalAccounting", Object.RecordInLocalAccounting);
	Query.SetParameter("RecordInManAccounting", Object.RecordInManAccounting);
	Query.SetParameter("ListOfFA", Object.FixedAsset);
	
	Result = Query.Execute();
	
	OwnerSArticlesAreNotDefined = Not Result.IsEmpty();
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtServer
Procedure BusinessOperationWhenChangingOnServer()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CompleteSplitFixedAssets Then
		Items.TraceableGoodsFillIn.Visible = True; 
		Items.TraceableGoodsToPickUp.Visible = False;
	Else
		Items.TraceableGoodsFillIn.Visible = False; 
		Items.TraceableGoodsToPickUp.Visible = True;	
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation
		And ValueIsFilled(Object.FixedAsset) Then
			
		OSType = Common.ObjectAttributeValue(Object.FixedAsset, "OSType");
		If OSType = Enums.FATypes.CapitalExpenditureInLeasedAssets Then
			Object.FixedAsset = Catalogs.Assets.EmptyRef();
		EndIf;
		
	EndIf;

	ConfigureDependentFormElementsOnServer("BusinessOperation");   
	
EndProcedure

&AtServer
Procedure OptionToAccountForComponentNodesOnChangesAtServer()
	
	ItemsAndDimensionsSelectionParameters = Documents.SplitFixedAssets.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);

	ConfigureDependentFormElementsOnServer("WriteOffNodes,ExpensesPostingMethod,BusinessUnitAndLineOfBusinessMatchAccountingData");
	
EndProcedure

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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
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
