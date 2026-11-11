
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	InitializationDuringCreationOnServer();

	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	#Region StandardSubsystems
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	#EndRegion
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If NotifyThatFormIsOutdated Then
		AttachIdleHandler("Attachable_NotifyThatFormIsOutdated", 0.3, True);
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_EntryOfCapitalAssetsBalance2_4", WriteParameters, Object.Ref);
	Notify("Write_OBEntry", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
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
	
	RefreshFormTitle();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerWhenChangesAreMadeOnServer();
	
	If PartnerBeforeTheChange <> Object.Partner
		Or TheCounterpartyPriorToTheChange <> Object.Counterparty Then
		If Object.LeaseContractsARAP.Count() <> 0 Then
			QueryText = NStr("vi = 'Khi thay đổi bạn hàng/đối tác, sẽ xóa dữ liệu hạch toán. Tiếp tục?';
							|ru = 'При изменении партнера/контрагента будут удалены расчеты. Продолжить?';
							|en = 'Settlements will be deleted if partner or counterparty changes. Continue?'; fa = 'Settlements will be deleted if partner or counterparty changes. Continue?';
							|it = 'In caso di modifiche al partner/controparte saranno eliminati i calcoli. Continuare?';
							|pl = 'W razie zmiany partnera/kontrahenta będą usunięte rozliczenia. Kontynuować?';
							|tr = 'İş ortağı/cari hesap değiştirildiğinde hesaplamalar silinecektir. Devam edilsin mi?'");
			CallbackDescription = New CallbackDescription("CounterpartyOnChangeCompletion", ThisObject);
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		Else
			CounterpartyOnChangeCompletion(DialogReturnCode.Yes, Undefined);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure PartnerWhenChangesAreMadeOnServer()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	If TheCounterpartyPriorToTheChange = Object.Counterparty Then
		Return;
	EndIf;
	
	If Object.LeaseContractsARAP.Count() <> 0 Then
		QueryText = NStr("vi = 'Khi thay đổi đối tác, sẽ xóa dữ liệu hạch toán. Tiếp tục?';
						|ru = 'При изменении контрагента будут удалены расчеты. Продолжить?';
						|en = 'Settlements will be deleted if counterparty is changed. Continue?'; fa = 'Settlements will be deleted if counterparty is changed. Continue?';
						|it = 'In caso di modifiche alla controparte saranno eliminati i calcoli. Continuare?';
						|pl = 'W razie zmiany kontrahenta będą usunięte rozliczenia. Kontynuować?';
						|tr = 'Cari hesap değiştirildiğinde hesaplamalar silinecektir. Devam edilsin mi?'");
		CallbackDescription = New CallbackDescription("CounterpartyOnChangeCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		CounterpartyOnChangeCompletion(DialogReturnCode.Yes, Undefined);
	EndIf; 
	
EndProcedure

&AtClient
Procedure RecordInOperationalAccountingOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure PostInFinancialAndTaxAccountingOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure RecordInMAOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	OrganizationWhenChangedOnServer();
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
EndProcedure

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
#EndRegion

#Region FormTableItemsEventHandlersLeaseContractsARAP

&AtClient
Procedure LeaseContractsARAPSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	EditInformationInLine();
	
EndProcedure

&AtClient
Procedure LeaseContractsARAPBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	EditInformationInLine(True, Copy);
	
EndProcedure

&AtClient
Procedure LeaseContractsARAPBeforeRowChange(Item, Cancel)
	
	If Item.CurrentItem <> Items.CalculationsForLeaseContractsTheRowNumber Then
		Cancel = True;
		EditInformationInLine();
	EndIf; 
	
EndProcedure

&AtClient
Procedure LeaseContractsARAPAfterDeleteRow(Item)
	
	DeleteDataFromLinkedTables();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ToEditInformation(Command)
	
	EditInformationInLine();
	
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
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_OnExecuteCommand(Command)

	EntryOfCapitalAssetsBalanceClientLocalization.FormSettlementsUnderLeaseAgreements_WhenExecutingCommand(Command, ThisForm);

EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

#Region AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)

	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()

	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	UsePartnersAndCounterparties = GetFunctionalOption("UsePartnersAndCounterparties");
	Items.Counterparty.Visible = UsePartnersAndCounterparties;
	
	TheCounterpartyPriorToTheChange = Object.Counterparty;
	PartnerBeforeTheChange = Object.Partner;
	
	Items.Counterparty.TypeRestriction = New TypeDescription("CatalogRef.Counterparties");
	
	RefreshFormTitle();
	
	ConfigureDependentFormElements();
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElements(Val ChangedBankingDetails = "")
	
	OnChangeAttributes(ChangedBankingDetails);
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If UpdateAll Then
		Items.EnterBalanceBy.Visible = False;
	EndIf;
	
	EntryOfCapitalAssetsBalanceLocalization.LeaseSettlementForm_ConfigureDependentFormElements(
		ThisForm, StructureOfChangedProps);
	
EndProcedure

&AtServer
Procedure OnChangeAttributes(ChangedBankingDetails)

	If Not ValueIsFilled(ChangedBankingDetails) Then
		Return; 
	EndIf; 
	
	AttributesList = StrSplit(ChangedBankingDetails, ",");
	
	If AttributesList.Find("RecordInOperationalAccounting") <> Undefined
		Or AttributesList.Find("PostInFinancialAndTaxAccounting") <> Undefined
		Or AttributesList.Find("RecordInMA") <> Undefined Then
		
		If Object.PostInFinancialAndTaxAccounting
			And Not Object.RecordInOperationalAccounting 
			And Not Object.RecordInMA Then
			
			Object.RecordInManAccounting = False;
			Object.RecordInLocalAccounting = True;
			
		ElsIf Object.RecordInMA
			And Not Object.RecordInOperationalAccounting 
			And Not Object.PostInFinancialAndTaxAccounting Then
			
			Object.RecordInManAccounting = True;
			Object.RecordInLocalAccounting = False;
			
		ElsIf Object.RecordInOperationalAccounting 
			And Object.RecordInMA
			And Not Object.PostInFinancialAndTaxAccounting Then
			
			Object.RecordInManAccounting = True;
			Object.RecordInLocalAccounting = False;
			
		ElsIf Object.PostInFinancialAndTaxAccounting
			And Object.RecordInMA
			And Not Object.RecordInOperationalAccounting Then
			
			Object.RecordInManAccounting = True;
			Object.RecordInLocalAccounting = True;
			
		ElsIf Object.PostInFinancialAndTaxAccounting
			And Object.RecordInOperationalAccounting Then
			
			Object.RecordInManAccounting = True;
			Object.RecordInLocalAccounting = True;
		EndIf; 
		
	EndIf; 
	
	If AttributesList.Find("Date") <> Undefined
		Or AttributesList.Find("Organization") <> Undefined
		Or AttributesList.Find("PostInFinancialAndTaxAccounting") <> Undefined
		Or AttributesList.Find("RecordInOperationalAccounting") <> Undefined
		Or AttributesList.Find("RecordInMA") <> Undefined
		Or AttributesList.Find("RecordInLocalAccounting") <> Undefined
		Or AttributesList.Find("RecordInManAccounting") <> Undefined Then
		
		FillInDetailsDependingOnProperties(Object.LeaseContractsARAP);
	EndIf; 
	
EndProcedure

&AtServer
Procedure FillInDetailsDependingOnProperties(StringsList)

	AuxiliaryDetailsOfObject = Documents.EntryOfCapitalAssetsBalance2_4.AuxiliaryAttributes(Object, False);
	
	For Each RowData In StringsList Do
		
		AuxiliaryAttributes = Documents.EntryOfCapitalAssetsBalance2_4.AddAuxiliaryDetailsBasedOnLineData(
											Object, RowData, AuxiliaryDetailsOfObject);
		
		ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_EnteringBalances(
										RowData, AuxiliaryAttributes, "");
										
		Documents.EntryOfCapitalAssetsBalance2_4.FillInDetailsDependingOnProperties(
				RowData, AuxiliaryAttributes, ItemDetailsParameters);
				
		TMCommonUseClientServer.ClearUnusedProps(RowData, ItemDetailsParameters);
		
		Documents.EntryOfCapitalAssetsBalance2_4.FillInDefaultValues(RowData, Object);
		
	EndDo; 

EndProcedure

&AtServer
Procedure RefreshFormTitle()
	
	Title = NonCurrentAssetsServerCall.PresentationOfInputBalances(Object);

EndProcedure

&AtClient
Procedure CounterpartyOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		Object.MaximumRowCode = 0;
		Object.LeaseContractsARAP.Clear();
		Object.ServicePaymentSchedule.Clear();
		Object.ServiceAccrualSchedule.Clear();
		Object.InterestAccrualSchedule.Clear();
	Else
		Object.Counterparty = TheCounterpartyPriorToTheChange;
		Object.Partner = PartnerBeforeTheChange;
	EndIf;
	
	TheCounterpartyPriorToTheChange = Object.Counterparty;
	PartnerBeforeTheChange = Object.Partner;
	
EndProcedure

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, NotificationParameters) Export
	
	If NotificationParameters.ServerCallRequired_ Then
		WhenExecutingEndCommandOnServer(CommandName, NotificationParameters.ProcessingParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenExecutingEndCommandOnServer(Val CommandName, Val AdditionalParameters)
	
	EntryOfCapitalAssetsBalanceLocalization.FormSettlementsUnderLeaseAgreements_WhenExecutingCommand(CommandName, ThisObject);
	
EndProcedure

&AtServer
Procedure InitializationDuringCreationOnServer()

	DateWhenFormWasDeprecatedMessageWasDisabled = FormDataSettingsStorage.Load("Document.EntryOfCapitalAssetsBalance2_4.Form.LeaseContractsARAP", "DateWhenFormWasDeprecatedMessageWasDisabled");
	NotifyThatFormIsOutdated = 
		DateWhenFormWasDeprecatedMessageWasDisabled = Undefined		
		Or BegOfDay(DateWhenFormWasDeprecatedMessageWasDisabled) < BegOfDay(CurrentSessionDate());
	
	AddressOfDataInLinkedTables = PutToTempStorage(Undefined, UUID);
	
	If Parameters.Property("ActivateLine") Then
		ActivateLine = Parameters.ActivateLine;
		If ActivateLine <= Object.LeaseContractsARAP.Count() And ActivateLine > 0 Then
			Items.GroupPages.CurrentPage = Items.PageSettlements;
			Items.LeaseContractsARAP.CurrentRow = ActivateLine - 1;
		EndIf; 
	EndIf; 
	
	AttributesList = New Array;
	For Each AttributeMetadata In Metadata.Documents.EntryOfCapitalAssetsBalance2_4.TabularSections.LeaseContractsARAP.Attributes Do
		AttributesList.Add(AttributeMetadata.Name);
	EndDo; 

	AttributesToEdit = StrConcat(AttributesList, ",");
	
EndProcedure

&AtClient
Procedure EditInformationInLine(NewRow = False, Copy = False)
	
	CurrentData = Items.LeaseContractsARAP.CurrentData;
	If CurrentData = Undefined And Not Copy And Not NewRow Then
		Return;
	EndIf; 

	FormParameters = New Structure;
	FormParameters.Insert("Ref", Object.Ref);
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Partner", Object.Partner);
	FormParameters.Insert("Counterparty", Object.Counterparty);
	FormParameters.Insert("RecordInLocalAccounting", Object.RecordInLocalAccounting);
	FormParameters.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	FormParameters.Insert("PostInAccounting", Object.PostInAccounting);
	FormParameters.Insert("RecordInTA", Object.RecordInTA);
	FormParameters.Insert("PostInFinancialAndTaxAccounting", Object.PostInFinancialAndTaxAccounting);
	FormParameters.Insert("RecordInOperationalAccounting", Object.RecordInOperationalAccounting);
	FormParameters.Insert("RecordInMA", Object.RecordInMA);
	FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
	FormParameters.Insert("AttributesToEdit", AttributesToEdit);
	FormParameters.Insert("NewRow", NewRow);
	FormParameters.Insert("Copy", Copy);
	FormParameters.Insert("AddressOfDataInLinkedTables", AddressOfDataInLinkedTables);
	FormParameters.Insert("ReadOnly", ReadOnly);
	
	RowID = Undefined;
	If CurrentData <> Undefined Then
		RowID = CurrentData.GetID();
		If Not NewRow Or Copy Then
			AttributesValues = New Structure(AttributesToEdit);
			FillPropertyValues(AttributesValues, CurrentData);
			FormParameters.Insert("AttributesValues", AttributesValues);
		EndIf; 
		If Copy Then
			AttributesValues.Contract = Undefined;
		EndIf;
	EndIf;
	
	If CurrentData <> Undefined Then
		PlaceDataFromRelatedTablesInTemporaryStorage(CurrentData.RowCode);
	Else
		PutToTempStorage(Undefined, AddressOfDataInLinkedTables);
	EndIf;
	
	AddlParameters = New Structure("NewRow,RowID", NewRow, RowID);
	CallbackDescription = New CallbackDescription("EditInformationInLineCompletion", ThisObject, AddlParameters);
	OpenForm("Document.EntryOfCapitalAssetsBalance2_4.Form.InformationAboutSettlementsUnderLeaseContracts", 
		FormParameters,,,,, CallbackDescription);

EndProcedure

&AtClient
Procedure EditInformationInLineCompletion(ClosingResult, AdditionalParameters) Export

	If TypeOf(ClosingResult) = Type("Structure") Then
		EditInformationInRowOnServer(ClosingResult, AdditionalParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure EditInformationInRowOnServer(Val ClosingResult, Val AdditionalParameters)

	Modified = True;

	If AdditionalParameters.NewRow Then
		
		TableRow = Object.LeaseContractsARAP.Add();
		
		Object.MaximumRowCode = Object.MaximumRowCode + 1;
		TableRow.RowCode = Object.MaximumRowCode;
		
	Else
		TableRow = Object.LeaseContractsARAP.FindByID(AdditionalParameters.RowID);
	EndIf;
	
	FillPropertyValues(TableRow, ClosingResult,, "RowCode");
	
	TablesData = GetFromTempStorage(AddressOfDataInLinkedTables);
	If TablesData <> Undefined Then
		
		Documents.EntryOfCapitalAssetsBalance2_4.UpdateDataInLinkedTable(
			Object.ServicePaymentSchedule, TablesData.ServicePaymentSchedule, TableRow.RowCode);
			
		Documents.EntryOfCapitalAssetsBalance2_4.UpdateDataInLinkedTable(
			Object.ServiceAccrualSchedule, TablesData.ServiceAccrualSchedule, TableRow.RowCode);
			
		Documents.EntryOfCapitalAssetsBalance2_4.UpdateDataInLinkedTable(
			Object.InterestAccrualSchedule, TablesData.InterestAccrualSchedule, TableRow.RowCode);
			
		Documents.EntryOfCapitalAssetsBalance2_4.UpdateDataInLinkedTable(
			Object.PrepaymentsUnderLeaseContracts, TablesData.PrepaymentsUnderLeaseContracts, TableRow.RowCode);
			
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteDataFromLinkedTables()
	
	StringCodesUsed = New Map();
	
	For Each RowData In Object.LeaseContractsARAP Do
		StringCodesUsed.Insert(RowData.RowCode);
	EndDo;
	
	DeleteUnusedRows(Object.ServicePaymentSchedule, StringCodesUsed);
	DeleteUnusedRows(Object.ServiceAccrualSchedule, StringCodesUsed);
	DeleteUnusedRows(Object.InterestAccrualSchedule, StringCodesUsed);
	DeleteUnusedRows(Object.PrepaymentsUnderLeaseContracts, StringCodesUsed);
	
EndProcedure

&AtServer
Procedure DeleteUnusedRows(DocumentTable, StringCodesUsed)
	
	LinesToDelete = New Array;
	For Each RowData In DocumentTable Do
		If StringCodesUsed.Get(RowData.RowCode) = Undefined Then
			LinesToDelete.Add(RowData);
		EndIf;
	EndDo;
	For Each RowData In LinesToDelete Do
		DocumentTable.Delete(RowData);
	EndDo;
	
EndProcedure

&AtServer
Procedure PlaceDataFromRelatedTablesInTemporaryStorage(Val RowCode)
	
	SearchForStrings = New Structure("RowCode", RowCode);
	
	RentalSchedules = New Structure;
	RentalSchedules.Insert("ServicePaymentSchedule", Object.ServicePaymentSchedule.Unload(SearchForStrings));
	RentalSchedules.Insert("ServiceAccrualSchedule", Object.ServiceAccrualSchedule.Unload(SearchForStrings));
	RentalSchedules.Insert("InterestAccrualSchedule", Object.InterestAccrualSchedule.Unload(SearchForStrings));
	RentalSchedules.Insert("PrepaymentsUnderLeaseContracts", Object.PrepaymentsUnderLeaseContracts.Unload(SearchForStrings));
	
	PutToTempStorage(RentalSchedules, AddressOfDataInLinkedTables);
	
EndProcedure

&AtClient
Procedure Attachable_NotifyThatFormIsOutdated()
	
	ButtonsList = New ValueList();
	ButtonsList.Add(DialogReturnCode.OK);
	ButtonsList.Add("DisableMessageThatFormIsOutdated", NStr("vi = 'Không hiển thị cảnh báo hôm nay';
															|ru = 'Не показывать предупреждение сегодня';
															|en = 'Do not show warning today'; fa = 'Do not show warning today';
															|it = 'Non mostrare notifica oggi';
															|pl = 'Nie pokazuj ostrzeżenie dzisiaj';
															|tr = 'Uyarıyı bugün gösterme'"));
	
	QueryText = NStr("vi = 'Việc nhập số dư hạch toán công nợ thuê thông qua chứng từ ""Nhập số dư tài sản dài hạn"" đã cũ.
						|Chỉ nên sử dụng chứng từ để xem các chứng từ đã tạo ra từ trước.
						|Nếu cần thay đổi chứng từ cũ thì nên tạo chứng từ mới ""Nhập số dư hạch toán công nợ thuê"" và xóa chứng từ cũ.
						|Để tạo mới, cần sử dụng chứng từ ""Nhập số dư hạch toán công nợ thuê"".';
						|ru = 'Ввод остатков взаиморасчетов по аренде с помощью документа ""Ввод остатков внеоборотных активов"" устарел.
						|Рекомендуется использовать документ только для просмотра ранее созданных документов.
						|Если устаревший документ необходимо изменить, то рекомендуется создать новый документ ""Ввод остатков взаиморасчетов по аренде"" и удалить устаревший.
						|Для создания новых необходимо использовать документы ""Ввод остатков взаиморасчетов по аренде"".';
						|en = 'Entry of the rental AR/AP balance using the ""OB entry: Fixed assets cost and depreciation"" document is outdated.
						|It is recommended that you use the document only for viewing previously created documents.
						|If the outdated document must be changed, create new document ""OB entry: rental AR/AP"" and delete the outdated one.
						|To create new documents, use the ""OB entry: rental AR/AP"" documents.'; fa = 'Entry of the rental AR/AP balance using the ""OB entry: Fixed assets cost and depreciation"" document is outdated.
						|It is recommended that you use the document only for viewing previously created documents.
						|If the outdated document must be changed, create new document ""OB entry: rental AR/AP"" and delete the outdated one.
						|To create new documents, use the ""OB entry: rental AR/AP"" documents.';
						|it = 'L''inserimento dei saldi dei regolamenti di conti reciproci di affitto con il supporto del documento ""Inserimento saldi attività non correnti"" è obsoleto.
						|Si consiglia di utilizzare il documento solo per la visualizzazione dei documenti precedentemente creati.
						|Se è necessario modificare il documento obsoleto, si consiglia di creare un nuovo documento ""Inserimento saldi dei regolamenti di conti reciproci di affitto"" ed eliminare quello obsoleto.
						|Per la creazione di nuovi documenti è necessario utilizzare i documenti ""Inserimento saldi dei regolamenti di conti reciproci di affitto"".';
						|pl = 'Wprowadzenie sald rozliczeń wzajemnych z tytułu dzierżawy za pomocą dokumentu ""Wprowadzenie sald aktywów pozaobrotowych"" jest przestarzały.
						|Zaleca się użycie dokumentu tylko do przeglądu wcześniej utworzonych dokumentów.
						|Jeśli przestarzały dokument należy zmienić, to zalecane jest utworzenie nowego dokumentu ""Wprowadzenie sald rozliczeń wzajemnych z tytułu dzierżawy"" i usunąć przestarzały.
						|Aby utworzyć nowe należy używać dokumentów ""Wprowadzenie sald rozliczeń wzajemnych z tytułu dzierżawy"".';
						|tr = '""Duran varlıkların bakiyelerini girin"" belgesini kullanarak kira uzlaştırma bakiyelerinin girilmesi güncelliğini yitirmiştir. 
						|Bu belgenin yalnızca daha önce oluşturulmuş belgeleri görüntülemek için kullanılması önerilmektedir. 
						|Eski belgenin değiştirilmesi gerekiyorsa, yeni bir ""Kira ödeme bakiyelerinin girişi"" belgesi oluşturmanız ve eski belgeyi silmeniz önerilmektedir. 
						| Yenilerini oluşturmak için ""Kira mutabakat bakiyelerini gir"" belgelerini kullanın.'");
	
	CallbackDescription = New CallbackDescription("NotifyThatFormIsOutdatedCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
	
EndProcedure

&AtClient
Procedure NotifyThatFormIsOutdatedCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = "DisableMessageThatFormIsOutdated" Then
		DisableMessageThatFormIsOutdated();
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure DisableMessageThatFormIsOutdated()
	
	FormDataSettingsStorage.Save(
		"Document.EntryOfCapitalAssetsBalance2_4.Form.LeaseContractsARAP", 
		"DateWhenFormWasDeprecatedMessageWasDisabled",
		CurrentSessionDate());
	
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
