
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Return of the form for analysis
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// Handler of the "Properties" subsystem
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	ItemsAndDimensionsSelectionParameters = Documents.AdjustmentOfARAPAccountingForAdvanceHolders.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.AdjustmentOfARAPAccountingForAdvanceHolders.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	ItemsAndDimensionsSelectionParameters = Documents.AdjustmentOfARAPAccountingForAdvanceHolders.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.AdjustmentOfARAPAccountingForAdvanceHolders.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	DocumentCorrectionClient.AfterWrite(Object);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BusinessOperationOnChange(Item)
	OnChangeOfElementAffectingDebt(Item);
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	OnChangeOfElementAffectingDebt(Item);
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	OnChangeOfElementAffectingDebt(Item);
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	OnChangeOfElementAffectingDebt(Item);
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersARAPAdjustment

&AtClient
Procedure ARAPAdjustmentSelection(Item, RowSelected, Field, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	Return;
	
EndProcedure

&AtClient
Procedure ARAPAdjustmentOnStartEdit(Item, NewRow, Copy)
	If NewRow And Copy Then
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
	EndIf;
	Return;
	
EndProcedure

&AtClient
Procedure ARAPAdjustmentDimensionOfExpensesStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ARAPAdjustmentDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure ARAPAdjustmentDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure ARAPAdjustmentAssetRefStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ARAPAdjustmentAssetRefOnChange(Item)
	AssetRefOnChangeServer(Item.Name);
EndProcedure

&AtClient
Procedure ARAPAdjustmentSumOnChange(Item)
	
	AmountOnChangeAtServer(Items.ARAPAdjustment.CurrentRow);
	
EndProcedure

&AtClient
Procedure ARAPAdjustmentBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Copy Or Not ValueIsFilled(Object.Organization) Then
		Return;
	EndIf;
	
	Cancel = True;
	DebtAdjustmentBeforeAddingAtServer();
	
EndProcedure

&AtClient
Procedure ARAPAdjustmentCurrencyOnChange(Item)
	CurrencyWhenChangedOnServer();
EndProcedure

&AtClient
Procedure ARAPAdjustmentOnActivateCell(Item)
	If Item.CurrentItem = Items.ARAPAdjustmentSumCompl
		 Or Item.CurrentItem = Items.ARAPAdjustmentSumMan Then
		DebtAdjustmentWhenActivatingCellATServer();
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
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
Procedure PickUpByBalance(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("Organization",           NStr("vi = 'Doanh nghiệp';
																			|ru = 'Организация';
																			|en = 'Company'; fa = 'Company';
																			|it = 'Company';
																			|pl = 'Company';
																			|tr = 'İş yeri'"));
	
	ParametersForObtainingBalances = ParametersForObtainingBalances(ThisObject);
	PickingParameters = New Structure;
	PickingParameters.Insert("ParametersForObtainingBalances", ParametersForObtainingBalances);
	PickingParameters.Insert("DocumentData", Object.ARAPAdjustment);
	
	Notification = New CallbackDescription("SelectionBasedOnBalancesAfterVerification", ThisObject, PickingParameters);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisObject, Notification, CheckParameters);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure
// End StandardSubsystems.AttachableCommands

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

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtClient
Async Procedure OnChangeOfElementAffectingDebt(Item)
	
	NamesOfDependentProps = MatchingElementsAndAttributes(ThisObject).Get(Item);
	If NamesOfDependentProps = Undefined Then
		Return;
	EndIf;
	
	If Object[NamesOfDependentProps.ObjectAttribute]
			= ThisObject[NamesOfDependentProps.FormAttribute] Then
		Return;
	EndIf;
	
	Response = Await CanClearDebtAsync();
	If Response = DialogReturnCode.No Then
		Object[NamesOfDependentProps.ObjectAttribute]
			= ThisObject[NamesOfDependentProps.FormAttribute];
	Else
		
		Object.ARAPAdjustment.Clear();
		ThisObject[NamesOfDependentProps.FormAttribute]
			= Object[NamesOfDependentProps.ObjectAttribute];
			
		If Item = Items.BusinessOperation Then
			BusinessOperationWhenChangingOnServer();
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

&AtServer
Procedure DebtAdjustmentWhenActivatingCellATServer()
	
	RowID = Items.ARAPAdjustment.CurrentRow;
	If RowID = Undefined Then
		Return;
	EndIf;
	
	LineToEdit =
		Object.ARAPAdjustment.FindByID(RowID);
	ChangeAvailabilityOfLocalManAmounts(LineToEdit);
	
EndProcedure

&AtServer
Procedure CurrencyWhenChangedOnServer()
	
	RowID = Items.ARAPAdjustment.CurrentRow;
	If RowID = Undefined Then
		Return;
	EndIf;
	
	LineToEdit =
		Object.ARAPAdjustment.FindByID(RowID);
	
	ChangeAvailabilityOfLocalManAmounts(LineToEdit);
	ParametersForObtainingBalances = ParametersForObtainingBalances(ThisObject);
	FillPropertyValues(ParametersForObtainingBalances, LineToEdit);
	Documents.AdjustmentOfARAPAccountingForAdvanceHolders.RecalculateLocalAndManAmounts(LineToEdit, ParametersForObtainingBalances);
	
EndProcedure

&AtServer
Procedure DebtAdjustmentBeforeAddingAtServer()
	
	AdjustmentLine = Object.ARAPAdjustment.Add();
	AdjustmentLine.Currency = Common.ObjectAttributeValue(Object.Organization, "LocalAccountingCurrency");
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, AdjustmentLine, "Object.ARAPAdjustment");
	
EndProcedure

&AtServer
Procedure ChangeAvailabilityOfLocalManAmounts(LineToEdit)
	
	If LineToEdit = Undefined Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Organization) Then
		Return;
	EndIf;
	
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	LocalAccountingCurrency =
			Common.ObjectAttributeValue(Object.Organization, "LocalAccountingCurrency");
	
	Items.ARAPAdjustmentSumCompl.ReadOnly = LineToEdit.Currency = LocalAccountingCurrency;
	Items.ARAPAdjustmentSumMan.ReadOnly  = LineToEdit.Currency = ManagementAccountingCurrency;
	
EndProcedure

&AtServer
Procedure BusinessOperationWhenChangingOnServer()
	
	ItemsAndDimensionsSelectionParameters = Documents.AdjustmentOfARAPAccountingForAdvanceHolders.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.AdjustmentOfARAPAccountingForAdvanceHolders.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);
EndProcedure

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtServer
Procedure AssetRefOnChangeServer(TagName)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items[TagName]);
	SetupParameters = Documents.AdjustmentOfARAPAccountingForAdvanceHolders.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure
// End StandardSubsystems.Properties

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

&AtClient
Procedure SelectionBasedOnBalancesAfterVerification(Result, PickingParameters) Export
	
	Notification = New CallbackDescription("SelectionByStockCompletion", ThisObject);
	OpenForm("Document.AdjustmentOfARAPAccountingForAdvanceHolders.Form.SelectionByStock",
	             PickingParameters,,,,,
	             Notification,
	             FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectionByStockCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		For Each Balance In Result Do
			
			If Balance.ExistsInTheDocument Then
				RowFilter = New Structure("AdvanceHolder,Currency,IssuancePurpose");
				FillPropertyValues(RowFilter, Balance);
				DocumentRows = Object.ARAPAdjustment.FindRows(RowFilter);
				If DocumentRows.Count() Then
					FillPropertyValues(DocumentRows[0], Balance);
				EndIf;
			Else
				FillPropertyValues(Object.ARAPAdjustment.Add(), Balance);
			EndIf;
			
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Async Function CanClearDebtAsync()
	
	If Object.ARAPAdjustment.Count() Then
		QueryText = NStr("vi = 'Số tiền ghi giảm công nợ có thể chưa được cập nhật.
		                        |Xóa danh sách công nợ?';
		                        |ru = 'Суммы списания задолженности могут стать неактуальным.
		                        |Очистить список задолженности?';
		                        |en = 'AR/AP write-off amounts can become irrelevant.
		                        |Clear debt list?'; fa = 'AR/AP write-off amounts can become irrelevant.
		                        |Clear debt list?';
		                        |it = 'Importi di storno del debito possono diventare obsoleti. 
		                        | Cancellare elenco del debito?';
		                        |pl = 'Kwoty umorzenia zadłużenia mogą stać się nieaktualne.
		                        |Oczyścić listę zobowiązań?';
		                        |tr = 'Borç gider yazma işlemlerinin tarihi geçmiş olabilir.
		                        |Borç listesi temizlensin mi?'");
		Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo);
	Else
		Response = DialogReturnCode.Yes;
	EndIf;
	
	Return Response;
	
EndFunction

&AtClientAtServerNoContext
Function MatchingElementsAndAttributes(Form)
	
	MatchingElementsAndAttributes = New Map;
	PropertiesOfNameStructure = "ObjectAttribute,FormAttribute";
	MatchingElementsAndAttributes.Insert(
		Form.Items.Date,
		New Structure(PropertiesOfNameStructure, "Date", "PreviousDateOfDocument"));
	MatchingElementsAndAttributes.Insert(
		Form.Items.Organization,
		New Structure(PropertiesOfNameStructure, "Organization", "PreviousOrganization"));
	MatchingElementsAndAttributes.Insert(
		Form.Items.Department,
		New Structure(PropertiesOfNameStructure, "Department", "PreviousDivision"));
	MatchingElementsAndAttributes.Insert(
		Form.Items.BusinessOperation,
		New Structure(PropertiesOfNameStructure, "BusinessOperation", "PreviousBusinessTransaction"));
		
	Return MatchingElementsAndAttributes;
		
EndFunction

&AtServer
Procedure OnReadCreateAtServer()
	
	UpdateCacheOfAttributes(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateCacheOfAttributes(Form)
	
	MatchingElementsAndAttributes = MatchingElementsAndAttributes(Form);
	For Each ItemDetails In MatchingElementsAndAttributes Do
		NamesOfDependentProps = ItemDetails.Value;
		Form[NamesOfDependentProps.FormAttribute]
			= Form.Object[NamesOfDependentProps.ObjectAttribute];
	EndDo;
	
EndProcedure

&AtServer
Procedure AmountOnChangeAtServer(RowID)
	
	ParametersForObtainingBalances = ParametersForObtainingBalances(ThisObject);
	LineToEdit = Object.ARAPAdjustment.FindByID(RowID);
	FillPropertyValues(ParametersForObtainingBalances, LineToEdit);
	Documents.AdjustmentOfARAPAccountingForAdvanceHolders.RecalculateLocalAndManAmounts(LineToEdit, ParametersForObtainingBalances);
	
EndProcedure

&AtClientAtServerNoContext
Function ParametersForObtainingBalances(Form)
	
	PickingParameters = New Structure;
	PickingParameters.Insert("Date");
	PickingParameters.Insert("Organization");
	PickingParameters.Insert("Department");
	PickingParameters.Insert("BusinessOperation");
	FillPropertyValues(PickingParameters, Form.Object);
	
	PickingParameters.Insert("AdvanceHolder");
	PickingParameters.Insert("Currency");
	PickingParameters.Insert("IssuancePurpose");
	
	Return PickingParameters;
	
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
