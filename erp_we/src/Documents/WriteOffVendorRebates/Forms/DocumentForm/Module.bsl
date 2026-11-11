//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnCreatReadAtServer();
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If ExchangePlans.MasterNode() <> Undefined Then
		
		ReadOnly = True;
		
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnCreatReadAtServer();
		
	EndIf;
	
	SetConditionalAppearance();
	SetHeader();
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	SetHeader();
	FillInServiceFieldsForDecodingDebits();
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.ShowConfirmationForClosingFormWithFiles(ThisObject, Cancel, Exit, Object.Ref);
	If Cancel Then
		Return;
	EndIf;
	// End StandardSubsystems.FilesOperations
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StatusOnChange(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDrillDownDebits

&AtClient
Procedure DrillDownDebitsOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateTotals();
	
EndProcedure

&AtClient
Procedure DrillDownDebitsAfterDeleteRow(Item)
	
	CalculateTotals();
	
EndProcedure

&AtClient
Procedure DecryptionOfDebitsAmountOnChange(Item)
	
	CalculateTotals();
	
EndProcedure

&AtClient
Procedure DrillDownDebitsCurrencyOnChange(Item)
	
	CalculateTotals();
	
EndProcedure

&AtClient
Procedure DecryptionOfWriteOffConditionsDocumentOnChange(Item)
	
	CurrentData = Items.DrillDownDebits.CurrentData;
	
	If ValueIsFilled(CurrentData.TermDocument) Then
		
		IDCurrentRow = CurrentData.GetID();
		DecryptionOfWriteOffConditionsDocumentOnChangeServer(IDCurrentRow);
		
	Else
		
		DateEmpty = Date(1, 1, 1);
		
		CurrentData.BonusType = PredefinedValue("Enum.VendorRebateTypes.EmptyRef");
		CurrentData.BeginOfPeriod = DateEmpty;
		CurrentData.PeriodEnding = DateEmpty;
		CurrentData.CurrencyIsDeterminedByCondition = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DecryptionOfPartnerDebitsOnChange(Item)
	
	SetSelectionOfContractInDecryption();
	
EndProcedure

&AtClient
Procedure DrillDownDebitsOnActivateRow(Item)
	
	SetSelectionOfContractInDecryption();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject, True);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);

EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject, True);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);

EndProcedure

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

// End StandardSubsystems.Properties

// StandardSubsystems.AttachableCommands

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

// StandardSubsystems.FilesOperations

// Parameters:
//  Command - FormCommand - executed command.
//
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	
	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
	
EndProcedure

// End StandardSubsystems.FilesOperations

// IntegrationWith1CDocumentManagementSubsystem

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure PickUpByBalance(Command)
	
	ClearMessages();
	Cancel = False;
	FieldKind = "Field";
	MessageKind = "FillType";
	
	FieldsToCheck = New Map;
	FieldsToCheck.Insert("Organization", NStr("vi = 'Doanh nghiệp';
												|ru = 'Организация';
												|en = 'Company'; fa = 'Company';
												|it = 'Организация';
												|pl = 'Firma';
												|tr = 'İş yeri'"));
	FieldsToCheck.Insert("Counterparty", NStr("vi = 'Đối tác';
												|ru = 'Контрагент';
												|en = 'Counterparty'; fa = 'طرف حساب';
												|it = 'Контрагент';
												|pl = 'Kontrahent';
												|tr = 'Cari hesap'"));
	FieldsToCheck.Insert("Date", NStr("vi = 'Ngày';
										|ru = 'Дата';
										|en = 'Date'; fa = 'تاریخ';
										|it = 'Дата';
										|pl = 'Date';
										|tr = 'Tarih'"));
	
	For Each CurrentField In FieldsToCheck Do
		
		Field = CurrentField.Key;
		
		If Not ValueIsFilled(Object[Field]) Then
			
			FieldName = CurrentField.Value;
			MessageText = CommonClientServer.FillingErrorText(FieldKind, MessageKind, FieldName);
			CommonClient.MessageToUser(MessageText,, Field, "Object", Cancel);
			
		EndIf;
		
	EndDo;
	
	If Not Cancel Then
		
		PickUpAccruedRB();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnCreatReadAtServer()
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	FillInServiceFieldsForDecodingDebits();
	CalculateTotals();
	
EndProcedure

#Region EventHandlersForFormHeaderElementsAuxiliary

&AtServer
Procedure OrganizationOnChangeServer()
	
	If Object.Organization.IsEmpty() Then
		
		CurrencyOfComplianceAccounting = Catalogs.Currencies.EmptyRef();
		
	Else
		
		CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		
		If GetFunctionalOption("NotUseMultipleCurrencies") Then
			
			For Each TSRow In Object.DrillDownDebits Do
				
				TSRow.Currency = CurrencyOfComplianceAccounting;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForRebateTableElementsAreAuxiliary

&AtServer
Procedure DecryptionOfWriteOffConditionsDocumentOnChangeServer(Val IDCurrentRow)
	
	TableRow = Object.DrillDownDebits.FindByID(IDCurrentRow);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert(
		"FillInCurrencyIndicationForRebatesOfSuppliers",
		New Structure("TermDocument", "CurrencyIsDeterminedByCondition"));
	StructureOfActions.Insert(
		"FillInCurrencyOfVendorSRebates",
		New Structure("TermDocument", "Currency"));
	StructureOfActions.Insert(
		"FillInRebateTypeOfSuppliers",
		New Structure("TermDocument", "BonusType"));
	
	CacheOfValues = Undefined;
	BatchProcessingOfTablePartServer.ProcessTSString(
		TableRow,
		StructureOfActions,
		CacheOfValues,
		Object.DrillDownDebits);
	
	If TableRow.BonusType = Enums.VendorRebateTypes.Balance Then
		
		TableRow.BeginOfPeriod = Date(1, 1, 1);
		TableRow.PeriodEnding = Date(1, 1, 1);
		
	EndIf;
	
	If GetFunctionalOption("NotUseMultipleCurrencies") Then
		TableRow.Currency = CurrencyOfComplianceAccounting;
	EndIf;
	
EndProcedure

#EndRegion

#Region ConditionalAppearance

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	SetRegistrationDecryptionOfDebitsValidityPeriod();
	SetRegistrationDecryptionOfDebitsCurrency();
	
EndProcedure

&AtServer
Procedure SetRegistrationDecryptionOfDebitsValidityPeriod()
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DrillDownDebitsBeginOfPeriod.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DrillDownDebitsPeriodEnding.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	Filter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.DrillDownDebits.BonusType");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = Enums.VendorRebateTypes.Balance;
	
	Filter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.DrillDownDebits.TermDocument");
	Filter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", "-");
	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Center);
	
EndProcedure

&AtServer
Procedure SetRegistrationDecryptionOfDebitsCurrency()
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DrillDownDebitsCurrency.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DrillDownDebits.CurrencyIsDeterminedByCondition");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

#EndRegion

#Region SelectionByStock

&AtClient
Async Procedure PickUpAccruedRB()
	
	QuestionIsRequired = False;
	If Object.Posted Then
		
		QuestionIsRequired = True;
		QueryText = NStr("vi = 'Trước khi chọn phương án tính, cần hủy kết chuyển chứng từ. Tiếp tục?';
						|ru = 'Перед подбором начислений необходимо отменить проведение документа. Продолжить?';
						|en = 'Before you pick accruals, unpost the document. Continue?'; fa = 'Before you pick accruals, unpost the document. Continue?';
						|it = 'Перед подбором начислений необходимо отменить проведение документа. Продолжить?';
						|pl = 'Before you pick accruals, unpost the document. Continue?';
						|tr = 'Tahakkukları seçmeden önce belge işlemini iptal etmelisiniz. Devam edilsin mi?'");
		
	EndIf;
	
	If QuestionIsRequired Then
		
		Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
		If Response = DialogReturnCode.No Then
			Return;
		Else
			
			If Object.Posted Then
				Write(New Structure("WriteMode", DocumentWriteMode.UndoPosting));
			EndIf;
			
		EndIf;
		
	EndIf;
	
	PickUpAccruedRBContinue();
	
EndProcedure

&AtClient
Procedure PickUpAccruedRBContinue()
	
	AddressOfTableOfSelectedRows = AddressOfTableOfSelectedRows();
	
	PickingParameters = New Structure;
	PickingParameters.Insert("Organization", Object.Organization);
	PickingParameters.Insert("Counterparty", Object.Counterparty);
	PickingParameters.Insert("AddressOfTableOfSelectedRows", AddressOfTableOfSelectedRows);
	PickingParameters.Insert("ChoiceMode", True);
	PickingParameters.Insert("UpdateDate", Object.Date);
	
	Notification = New CallbackDescription("PickUpAccruedRBCompletion", ThisObject);
	
	OpenForm("AccumulationRegister.VendorRebates.Form.FormForPickingByBalance",
		PickingParameters, ThisObject,,,, Notification);
	
EndProcedure

&AtServer
Function AddressOfTableOfSelectedRows()
	
	Table_SelectedRows = Object.DrillDownDebits.Unload();
	Table_SelectedRows.Columns.Add("DocumentSelected", New TypeDescription("Boolean"));
	Table_SelectedRows.Columns.Add("Check", New TypeDescription("Boolean"));
	
	For Each TableRow In Table_SelectedRows Do
		
		TableRow.DocumentSelected = True;
		TableRow.Check = True;
		
	EndDo;
	
	AddressOfTableOfSelectedRows = PutToTempStorage(Table_SelectedRows, UUID);
	
	Return AddressOfTableOfSelectedRows;
	
EndFunction

// Parameters:
//  Result - Undefined, String - 
//  AdditionalParameters - Arbitrary -
//
&AtClient
Procedure PickUpAccruedRBCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined
	   And IsTempStorageURL(Result) Then
		
		ProcessingSelectionOfAccrualDocuments(Result);
		CalculateTotals();
		Modified = True;
		
	EndIf;
	
EndProcedure

// Parameters:
//  AddressInStorage - String - Address in the store
//
&AtServer
Procedure ProcessingSelectionOfAccrualDocuments(Val AddressInStorage)
	
	BalanceTable = TableOfSelectedBalances(AddressInStorage);
	DeleteFromTempStorage(AddressInStorage);
	
	Object.DrillDownDebits.Clear();
	Object.DrillDownDebits.Load(BalanceTable);
	FillInServiceFieldsForDecodingDebits();
	
EndProcedure

// Parameters:
//  AddressInStorage - String - Address in the store
// 
// Returns:
//  ValueTable:
//   * TermDocument - DocumentRef.ConditionsOfVendorRebates
//   * Partner - CatalogRef.Partners
//   * Contract - CatalogRef.CounterpartyContracts
//   * RebateKind - CatalogRef.VendorRebateKinds
//   * LongDesc - String
//   * ValidOnDate - Date
//   * ValidTo - Date
//   * Sum - DefinedType.MonetaryAmountPositiveNegative
//   * Currency - CatalogRef.Currencies
//
&AtServer
Function TableOfSelectedBalances(AddressInStorage)
	
	Return GetFromTempStorage(AddressInStorage);
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure CalculateTotals()
	
	AmountTotal = Object.DrillDownDebits.Total("Sum");
	
	CopyOfCharge = Object.DrillDownDebits.Unload(,
		"Sum, Currency");
	CopyOfCharge.GroupBy("Currency", "Sum");
	
	If CopyOfCharge.Count() = 0 Then
		
		TitleLine = NStr("vi = 'Tổng số: <không dữ liệu>';
						|ru = 'Итого: <нет данных>';
						|en = 'Total: <no data>'; fa = 'Total: <no data>';
						|it = 'Итого: <нет данных>';
						|pl = 'Total: <no data>';
						|tr = 'Toplam: <veri yok>'");
		
	Else
		
		TitleLine = NStr("vi = 'Tổng số:';
						|ru = 'Итого:';
						|en = 'Total:'; fa = 'جمع:';
						|it = 'Итого:';
						|pl = 'Total:';
						|tr = 'Toplam:'");
		
	EndIf;
	
	CaptionLines = New Array; // Array of String
	CaptionLines.Add(TitleLine);
	
	For Each TableRow In CopyOfCharge Do
		
		CaptionLines.Add(Format(TableRow.Sum, "NFD=2;"));
		If TableRow.Currency.IsEmpty() Then
			CaptionLines.Add("<..>");
		Else
			CaptionLines.Add(String(TableRow.Currency));
		EndIf;
		
	EndDo;
	
	Items.DecorationTotal.Title = StrConcat(CaptionLines, " ");
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure SetHeader()
	
	AutoTitle = False;
	Title = RebatesServer.DocumentTitle(
		Object.Ref, Object.Number, Object.Date);
	
EndProcedure

&AtServer
Procedure FillInServiceFieldsForDecodingDebits()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert(
		"FillInCurrencyIndicationForRebatesOfSuppliers",
		New Structure("TermDocument", "CurrencyIsDeterminedByCondition"));
	StructureOfActions.Insert(
		"FillInRebateTypeOfSuppliers",
		New Structure("TermDocument", "BonusType"));
	
	BatchProcessingOfTablePartServer.TreatTS(Object.DrillDownDebits, StructureOfActions);
	
EndProcedure

&AtClient
Procedure SetSelectionOfContractInDecryption()
	
	RowData = Items.DrillDownDebits.CurrentData;
	ContractSelectionParameters_ = ContractSelectionParameters_(RowData);
	Items.DrillDownDebitsContract.ChoiceParameters = New FixedArray(ContractSelectionParameters_);
	
EndProcedure

&AtClient
Function ContractSelectionParameters_(RowData)
	
	SupportedContractTypes = RebatesClientServer.TypesOfProcurementContracts();
	
	ContractSelectionParameters_ = New Array(); // Array of ChoiceParameter
	
	FilterType = New ChoiceParameter("Filter.ContractType", New FixedArray(SupportedContractTypes));
	ContractSelectionParameters_.Add(FilterType);
	
	FilterCheck = New ChoiceParameter("Filter.DeletionMark", False);
	ContractSelectionParameters_.Add(FilterCheck);
	
	If RowData <> Undefined
	   And ValueIsFilled(RowData.Partner) Then
		
		NewFilter = New ChoiceParameter("Partner", RowData.Partner);
		ContractSelectionParameters_.Add(NewFilter);
		
	EndIf;
	
	Return ContractSelectionParameters_;
	
EndFunction

#EndRegion

#Region StandardSubsystems_PlugInCommands

// StandardSubsystems.AttachableCommands

// The Attachable one continues to execute the Commands on the server.
// 
// Parameters:
//  ExecutionParameters - Structure -
//  AdditionalParameters - Structure -
//
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#Region StandardSubsystems_Properties

// StandardSubsystems.Properties
&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

//@skip-check module-unused-method - implicit call from the property managementmiclient.Post-loadingadditional requirements
&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure

// End StandardSubsystems.Properties

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
