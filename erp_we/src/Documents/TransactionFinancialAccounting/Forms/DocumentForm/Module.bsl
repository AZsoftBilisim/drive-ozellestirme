#Region FormEventHandlers

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
	
	FinancialAccountingOfGeneralPurpose.SetUnitHeaders(Items.DepartmentDr, NStr("vi = 'Nợ';
																				|ru = 'Дт';
																				|en = 'Dr'; fa = 'بد';
																				|it = 'Debito';
																				|pl = 'Wn';
																				|tr = 'Borç'"));
	FinancialAccountingOfGeneralPurpose.SetUnitHeaders(Items.DepartmentCr, NStr("vi = 'Có';
																				|ru = 'Кт';
																				|en = 'Cr'; fa = 'بس';
																				|it = 'Credito';
																				|pl = 'Ma';
																				|tr = 'Alacak'"));
	FinancialAccountingOfGeneralPurpose.SetUnitHeaders(Items.Department, "");
	
	CheckBoxList = Object.RecordsFilling.Count() > 1;
	ArrayOfDocumentTypes = New Array;
	For Each Type In Metadata.AccountingRegisters.International.StandardAttributes.Recorder.Type.Types() Do
		If Common.MetadataObjectAvailableByFunctionalOptions(Metadata.FindByType(Type)) Then
			ArrayOfDocumentTypes.Add(Type);
		EndIf;
	EndDo;
	ArrayOfDocumentTypes.Add(Type("String"));
	NewType = New TypeDescription(ArrayOfDocumentTypes);
	Items.ReversedDocument.TypeRestriction = NewType;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	TypesConnectedWithTheCompany = GLAccountSettingsServer.TypesConnectedWithTheCompany();
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		If ValueSelected.Property("AddressOfPostingsInTheStorage") Then
			DownloadTransactionsFromStorage(ValueSelected.AddressOfPostingsInTheStorage);
			Modified = True;
		ElsIf ValueSelected.Property("OperationTemplate") Then
			TemplateNames_ = ProcessingOperationTemplateSelectionServer(ValueSelected.OperationTemplate);
			ShowUserNotification(NStr("vi = 'Các bút toán tiêu biểu được thêm vào:';
										|ru = 'Добавлены типовые проводки:';
										|en = 'Standard accounting entries are added:'; fa = 'Standard accounting entries are added:';
										|it = 'Sono state aggiunte le scritture contabili standard:';
										|pl = 'Dodano typowe dekretowania:';
										|tr = 'Standart işlemler eklendi'"),,TemplateNames_,PictureLib.Information32);
		EndIf;
	ElsIf Items.ReversedDocument.TypeRestriction.ContainsType(TypeOf(ValueSelected)) Then
		ReversedDocument = ValueSelected;
		Modified = True;
		UploadTransactionsForReversal(ValueSelected);
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	If WriteParameters.WriteMode = DocumentWriteMode.UndoPosting Then
		ThisForm.Read();
	EndIf;
	
	FinancialAccountingOfGeneralPurpose.FillInPresentationOfExtdimensionSpecies(Object.RegisterRecords.International, "Dr");
	FinancialAccountingOfGeneralPurpose.FillInPresentationOfExtdimensionSpecies(Object.RegisterRecords.International, "Cr");
	FinancialAccountingOfGeneralPurpose.FillInPresentationOfExtdimensionSpecies(Object.RegisterRecords.InternationalWithoutCorrespondence, "");
	
	FillInAuxiliaryAttributesOfTransactionsWithoutCorrespondence();
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
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

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	If Not CheckBoxList And ValueIsFilled(ReversedDocument) And TypeOf(ReversedDocument) <> Type("String") Then
		CurrentObject.RecordsFilling.Clear();
		NewRow = CurrentObject.RecordsFilling.Add();
		NewRow.Document = ReversedDocument;
	EndIf;
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	
	DateOfChangeOnServer();
	
EndProcedure

&AtServer
Procedure DateOfChangeOnServer()
	
	GenerateHeadersForInvalidatingCommands();
	
EndProcedure

&AtClient
Procedure EnterPeriodByRowsOnChange(Item)
	
	Items.Period.Visible = Object.EnterPeriodByRows;
	Items.InternationalWithoutCorrespondencePeriod.Visible = Object.EnterPeriodByRows;
		
EndProcedure

&AtClient
Procedure FillingMethodOnChange(Item)
	
	UpdateDisplayOfDocumentBeingCanceled();
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	ThereAreRegisteredRecords = 
		Object.RegisterRecords.International.Count() > 0
		Or Object.RegisterRecords.InternationalWithoutCorrespondence.Count() > 0;

	If ThereAreRegisteredRecords Then
		QueryText = NStr("vi = 'Các tài khoản thanh toán, hợp đồng, Bộ phận, Chứng từ quy định trong các giao dịch sẽ bị xóa. Tiếp tục?';
						|ru = 'Указанные в проводках расчетные счета, договоры, подразделения, документы будут очищены. Продолжить?';
						|en = 'Current accounts, contracts, business units, documents specified in the entries will be cleared. Continue?'; fa = 'Current accounts, contracts, business units, documents specified in the entries will be cleared. Continue?';
						|it = 'Conti di regolamento, contratti, reparti, documenti indicati nelle scritture contabili verranno eliminati. Continuare?';
						|pl = 'Wskazane w dekretowaniach rachunki bieżące, kontrakty, działy zostaną. Kontynuować?';
						|tr = 'Girişlerde belirtilen cari işlemler hesapları, sözleşmeler, departmanlar, belgeler temizlenecek. Devam edilsin mi?'");
		Notification = New CallbackDescription("QuestionWhenYouChangeTheOrganizationEnd", ThisObject);
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	Else
		OrganizationWhenChangedOnServer();
	EndIf;
	
	UpdateDisplayAccordingToChartOfAccounts();
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	GenerateHeadersForInvalidatingCommands();
	
EndProcedure

&AtClient
Procedure ChartOfAccountsOnChange(Item)
	
	ThereAreRegisteredRecords = 
		Object.RegisterRecords.International.Count() > 0
		Or Object.RegisterRecords.InternationalWithoutCorrespondence.Count() > 0;
		
	If ThereAreRegisteredRecords And CurrentAccountPlan <> Object.ChartOfAccounts Then
		CallbackDescription = New CallbackDescription("WhenChangingChartOfAccountsQuestion", ThisObject);
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.OK, NStr("vi = 'Tiếp tục';
												|ru = 'Продолжить';
												|en = 'Continue'; fa = 'ادامه';
												|it = 'Continuare';
												|pl = 'Kontynuuj';
												|tr = 'Devam'"));
		Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Anuluj';
													|tr = 'İptal'"));
		ShowQueryBox(CallbackDescription, NStr("vi = 'Bảng bút toán sẽ bị xóa. Tiếp tục?';
												|ru = 'Таблица проводок будет очищена. Продолжить?';
												|en = 'Postings table will be cleared. Continue?'; fa = 'Postings table will be cleared. Continue?';
												|it = 'Tabella delle registrazioni verrà cancellata. Continuare?';
												|pl = 'Tabela dekretować zostanie wyczyszczona. Kontynuować?';
												|tr = 'Girişler tablosu temizlenecektir. Devam edilsin mi?'"), Buttons);
	Else
		CurrentAccountPlan = Object.ChartOfAccounts;
		ChartOfAccountsWhenChangedOnServer();
	EndIf;

	
EndProcedure

&AtServer
Procedure ChartOfAccountsWhenChangedOnServer()
	
	GenerateHeadersForInvalidatingCommands();
	UpdateDisplayAccordingToChartOfAccounts();
	
EndProcedure

#EndRegion

#Region ElementEventHandlersFillingRegisteredRecords

&AtClient
Procedure RecordsFillingDocumentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.RecordsFilling.CurrentData;
	Item.ChooseType = Not ValueIsFilled(CurrentData.Document);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRegisteredRecordsInternational

&AtClient
Procedure RegisteredRecordsInternationalOnStartEdit(Item, NewRow, Copy)
	
	CurrentRow = Items.RegisteredRecordsInternational.CurrentData;
	If NewRow And Not Copy Then
		CurrentRow.Active = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure RegisteredRecordsInternationalBeforeRowChange(Item, Cancel)
	TableRow = Items.RegisteredRecordsInternational.CurrentData;
	GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, TableRow, Object.Organization, "Dr");
	GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, TableRow, Object.Organization, "Cr");
EndProcedure

&AtClient
Procedure AccountDrOnChange(Item)
	
	CurrentData = Items.RegisteredRecordsInternational.CurrentData;
	FillPropertyValues(CurrentData, PresentationOfExtdimensionAccounts(CurrentData.AccountDr, "Dr"));
	
EndProcedure

&AtClient
Procedure AccountCrOnChange(Item)
	
	CurrentData = Items.RegisteredRecordsInternational.CurrentData;
	FillPropertyValues(CurrentData, PresentationOfExtdimensionAccounts(CurrentData.AccountCr, "Cr"));
	
EndProcedure

&AtClient
Procedure SumOnChange(Item)
	
	CurrentRow = Items.RegisteredRecordsInternational.CurrentData;
	CurrentRow.PresentationAmount = CalculateSumOfPresentation(Object.ChartOfAccounts, Object.Organization, CurrentRow.Sum, Object.Date);
	
EndProcedure

&AtClient
Procedure CurrencyDrOnChange(Item)
	
	CurrencyOnChangeClient(Items.RegisteredRecordsInternational, "Dr");
	
EndProcedure

&AtClient
Procedure CurrencyCrOnChange(Item)
	
	CurrencyOnChangeClient(Items.RegisteredRecordsInternational, "Cr");
	
EndProcedure

&AtClient
Procedure CurrencyAmountDrOnChange(Item)
	
	CurrencyOnChangeClient(Items.RegisteredRecordsInternational, "Dr");
	
EndProcedure

&AtClient
Procedure CurrencyAmountCrOnChange(Item)
	
	CurrencyOnChangeClient(Items.RegisteredRecordsInternational, "Cr");
	
EndProcedure

&AtClient
Procedure ExtDimensionDr1OnChange(Item)
	TableRow = Items.RegisteredRecordsInternational.CurrentData;
	GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, TableRow, Object.Organization, "Dr");
EndProcedure

&AtClient
Procedure ExtDimensionDr1ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ClearSelectionOptions(Item);
EndProcedure

&AtClient
Procedure ExtDimensionDr2OnChange(Item)
	TableRow = Items.RegisteredRecordsInternational.CurrentData;
	GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, TableRow, Object.Organization, "Dr");
EndProcedure

&AtClient
Procedure ExtDimensionDr2ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ClearSelectionOptions(Item);
EndProcedure

&AtClient
Procedure ExtDimensionDr3OnChange(Item)
	TableRow = Items.RegisteredRecordsInternational.CurrentData;
	GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, TableRow, Object.Organization, "Dr");
EndProcedure

&AtClient
Procedure ExtDimensionDr3ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ClearSelectionOptions(Item);
EndProcedure

&AtClient
Procedure ExtDimensionCr1OnChange(Item)
	TableRow = Items.RegisteredRecordsInternational.CurrentData;
	GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, TableRow, Object.Organization, "Cr");
EndProcedure

&AtClient
Procedure ExtDimensionCr1ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ClearSelectionOptions(Item);
EndProcedure

&AtClient
Procedure ExtDimensionCr2OnChange(Item)
	TableRow = Items.RegisteredRecordsInternational.CurrentData;
	GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, TableRow, Object.Organization, "Cr");
EndProcedure

&AtClient
Procedure ExtDimensionCr2ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ClearSelectionOptions(Item);
EndProcedure

&AtClient
Procedure ExtDimensionCr3OnChange(Item)
	TableRow = Items.RegisteredRecordsInternational.CurrentData;
	GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, TableRow, Object.Organization, "Cr");
EndProcedure

&AtClient
Procedure ExtDimensionCr3ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ClearSelectionOptions(Item);
EndProcedure

#EndRegion

#Region EventHandlersForTrafficFormTableElementsInternationalWithoutCorrespondence

&AtClient
Procedure InternationalWithoutCorrespondenceBeforeRowChange(Item, Cancel)
	TableRow = Items.InternationalWithoutCorrespondence.CurrentData;
	GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, TableRow, Object.Organization, "");
EndProcedure

&AtClient
Procedure InternationalWithoutCorrespondenceOnEditEnd(Item, NewRow, CancelEdit)
	If Not CancelEdit Then
		CalculateResultsOfTransactionsWithoutCorrespondence(ThisObject);
	EndIf;
EndProcedure

&AtClient
Procedure InternationalWithoutCorrespondenceOnStartEdit(Item, NewRow, Copy)
	
	CurrentRow = Items.InternationalWithoutCorrespondence.CurrentData;
	If NewRow And Not Copy Then
		CurrentRow.Active = False;
		If TotalAmount_5Dr > TotalAmount_5Cr Then
			CurrentRow.RecordType = TypeOfMovementCredit;
			CurrentRow.SumCr = TotalAmount_5Dr - TotalAmount_5Cr;
			CurrentRow.Sum = CurrentRow.SumCr;
			
			CurrentRow.PresentationAmountCr = ResultIsSumOfDrSubmission - ResultIsSumOfCrRepresentation;
			CurrentRow.PresentationAmount = CurrentRow.PresentationAmountCr;
		ElsIf TotalAmount_5Dr < TotalAmount_5Cr Then
			CurrentRow.RecordType = TypeOfMovementDebit;
			CurrentRow.SumDr = TotalAmount_5Cr - TotalAmount_5Dr;
			CurrentRow.Sum = CurrentRow.SumDr;
			
			CurrentRow.PresentationAmountDr = ResultIsSumOfCrRepresentation - ResultIsSumOfDrSubmission;
			CurrentRow.PresentationAmount = CurrentRow.PresentationAmountDr;
		ElsIf ResultIsSumOfDrSubmission > ResultIsSumOfCrRepresentation Then
			CurrentRow.RecordType = TypeOfMovementCredit;
			CurrentRow.SumCr = TotalAmount_5Dr - TotalAmount_5Cr;
			CurrentRow.Sum = CurrentRow.SumCr;
			
			CurrentRow.PresentationAmountCr = ResultIsSumOfDrSubmission - ResultIsSumOfCrRepresentation;
			CurrentRow.PresentationAmount = CurrentRow.PresentationAmountCr;
		ElsIf ResultIsSumOfDrSubmission < ResultIsSumOfCrRepresentation Then
			CurrentRow.RecordType = TypeOfMovementDebit;
			CurrentRow.SumDr = TotalAmount_5Cr - TotalAmount_5Dr;
			CurrentRow.Sum = CurrentRow.SumDr;
			
			CurrentRow.PresentationAmountDr = ResultIsSumOfCrRepresentation - ResultIsSumOfDrSubmission;
			CurrentRow.PresentationAmount = CurrentRow.PresentationAmountDr;
		EndIf;
		CalculateResultsOfTransactionsWithoutCorrespondence(ThisObject);
		CurrentRow.TypeOfMovementIndex = 
			TypeOfMovementIndexOfImage(CurrentRow.RecordType, CurrentRow.Active, CurrentRow.Sum, ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure InternationalWithoutCorrespondenceAfterDeleteRow(Item)
	CalculateResultsOfTransactionsWithoutCorrespondence(ThisObject);
EndProcedure

&AtClient
Procedure AccountOnChange(Item)
	
	CurrentData = Items.InternationalWithoutCorrespondence.CurrentData;
	FillPropertyValues(CurrentData, PresentationOfExtdimensionAccounts(CurrentData.Account, ""));
	
	If ValueIsFilled(CurrentData.Account) Then
		AccountProperties = FinancialAccountingServerCall.AccountProperties(CurrentData.Account);
		If AccountProperties.Currency1
		   And ValueIsFilled(CurrentData.Sum)
		   And Not ValueIsFilled(CurrentData.Currency)
		   And Not ValueIsFilled(CurrentData.CurrencyAmount) Then
			CurrentData.Currency = CurrencyFunctional;
			CurrentData.CurrencyAmount = CurrentData.Sum;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SumDrOnChange(Item)
	
	CurrentData = Items.InternationalWithoutCorrespondence.CurrentData;
	CurrentData.RecordType = TypeOfMovementDebit;
	CurrentData.Sum = CurrentData.SumDr;
	CurrentData.SumCr = 0;
	
	CurrentData.PresentationAmountDr = CalculateSumOfPresentation(Object.ChartOfAccounts, Object.Organization, CurrentData.Sum, Object.Date);
	CurrentData.PresentationAmount = CurrentData.PresentationAmountDr;
	CurrentData.PresentationAmountCr = 0;
	
	CurrentData.TypeOfMovementIndex = 
		TypeOfMovementIndexOfImage(CurrentData.RecordType, CurrentData.Active, CurrentData.Sum, ThisObject);
	
EndProcedure

&AtClient
Procedure SumCrOnChange(Item)
	
	CurrentData = Items.InternationalWithoutCorrespondence.CurrentData;
	CurrentData.RecordType = TypeOfMovementCredit;
	CurrentData.Sum = CurrentData.SumCr;
	CurrentData.SumDr = 0;
	
	CurrentData.PresentationAmountCr = CalculateSumOfPresentation(Object.ChartOfAccounts, Object.Organization, CurrentData.Sum, Object.Date);
	CurrentData.PresentationAmount = CurrentData.PresentationAmountCr;
	CurrentData.PresentationAmountDr = 0;
	
	CurrentData.TypeOfMovementIndex = 
		TypeOfMovementIndexOfImage(CurrentData.RecordType, CurrentData.Active, CurrentData.Sum, ThisObject);
		
EndProcedure

&AtClient
Procedure PresentationAmountDrOnChange(Item)
	CurrentData = Items.InternationalWithoutCorrespondence.CurrentData;
	CurrentData.PresentationAmount = CurrentData.PresentationAmountDr;
	CurrentData.RecordType = TypeOfMovementDebit;
	If CurrentData.SumCr <> 0 Then
		CurrentData.SumCr = 0;
		CurrentData.Sum = 0;
	EndIf;
	If CurrentData.PresentationAmountCr <> 0 Then
		CurrentData.PresentationAmountCr = 0;
	EndIf;
EndProcedure

&AtClient
Procedure PresentationAmountCrOnChange(Item)
	CurrentData = Items.InternationalWithoutCorrespondence.CurrentData;
	CurrentData.PresentationAmount = CurrentData.PresentationAmountCr;
	CurrentData.RecordType = TypeOfMovementCredit;
	If CurrentData.SumDr <> 0 Then
		CurrentData.SumDr = 0;
		CurrentData.Sum = 0;
	EndIf;
	If CurrentData.PresentationAmountDr <> 0 Then
		CurrentData.PresentationAmountDr = 0;
	EndIf;
EndProcedure

&AtClient
Procedure CurrencyAmountOnChange(Item)
	CurrencyOnChangeClient(Items.InternationalWithoutCorrespondence, "");
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	CurrencyOnChangeClient(Items.InternationalWithoutCorrespondence, "");
EndProcedure

&AtClient
Procedure ExtDimension1OnChange(Item)
	TableRow = Items.InternationalWithoutCorrespondence.CurrentData;
	GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, TableRow, Object.Organization, "");
EndProcedure

&AtClient
Procedure ExtDimension1ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ClearSelectionOptions(Item);
EndProcedure

&AtClient
Procedure ExtDimension2OnChange(Item)
	TableRow = Items.InternationalWithoutCorrespondence.CurrentData;
	GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, TableRow, Object.Organization, "");
EndProcedure

&AtClient
Procedure ExtDimension2ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ClearSelectionOptions(Item);
EndProcedure

&AtClient
Procedure ExtDimension3OnChange(Item)
	TableRow = Items.InternationalWithoutCorrespondence.CurrentData;
	GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, TableRow, Object.Organization, "");
EndProcedure

&AtClient
Procedure ExtDimension3ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ClearSelectionOptions(Item);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ImportPostings(Command)
	
	StartUploadingTransactions(Command.Name);
	
EndProcedure

&AtClient
Procedure ImportPostingStorno(Command)
	
	StartUploadingTransactions(Command.Name);
	
EndProcedure

&AtClient
Procedure AddFromTemplate(Command)
	
	FormParameters = New Structure("Object",Object);
	If ValueIsFilled(Object.ChartOfAccounts) Then
		SelectionAccordingToChartOfAccounts = New Structure("ChartOfAccounts", Object.ChartOfAccounts);
		FormParameters.Insert("Filter", SelectionAccordingToChartOfAccounts);
	EndIf;
	
	OpenForm("Catalog.StandardTransactionsOfFinancialAccounting.ChoiceForm", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
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
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	// registration of negative amounts in red
	RegistrationOfNegativeAmounts(Items.Sum);
	RegistrationOfNegativeAmounts(Items.PresentationAmount);
	RegistrationOfNegativeAmounts(Items.CurrencyAmountDr);
	RegistrationOfNegativeAmounts(Items.CurrencyAmountCr);
	
	RegistrationOfNegativeAmounts(Items.SumDr);
	RegistrationOfNegativeAmounts(Items.SumCr);
	RegistrationOfNegativeAmounts(Items.PresentationAmountDr);
	RegistrationOfNegativeAmounts(Items.PresentationAmountCr);
	RegistrationOfNegativeAmounts(Items.CurrencyAmount);
	
	// registration of the fields "Subconto1", ... etc.
	FinancialAccountingOfGeneralPurpose.SetTransactionLayout(
		ConditionalAppearance, 
		"Object.RegisterRecords.International",
		True);
	FinancialAccountingOfGeneralPurpose.SetTransactionLayout(
		ConditionalAppearance, 
		"Object.RegisterRecords.InternationalWithoutCorrespondence",
		False);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	TypeOfMovementDebit = AccountingRecordType.Debit;
	TypeOfMovementCredit = AccountingRecordType.Credit;
	OverdueDataColor = StyleColors.OverdueDataColor;
	
	Items.Period.Visible = Object.EnterPeriodByRows;
	Items.InternationalWithoutCorrespondencePeriod.Visible = Object.EnterPeriodByRows;
	CurrentAccountPlan = Object.ChartOfAccounts;
	UpdateDisplayAccordingToChartOfAccounts();
	UpdateDisplayOfDocumentBeingCanceled();
	GenerateHeadersForInvalidatingCommands();
	FillInAuxiliaryAttributesOfTransactionsWithoutCorrespondence();
	
	FinancialAccountingOfGeneralPurpose.FillInPresentationOfExtdimensionSpecies(Object.RegisterRecords.International, "Dr");
	FinancialAccountingOfGeneralPurpose.FillInPresentationOfExtdimensionSpecies(Object.RegisterRecords.International, "Cr");
	FinancialAccountingOfGeneralPurpose.FillInPresentationOfExtdimensionSpecies(Object.RegisterRecords.InternationalWithoutCorrespondence, "");
	
EndProcedure

&AtServer
Procedure RegistrationOfNegativeAmounts(FormField)

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormField.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(FormField.DataPath);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 0;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTextColor);

EndProcedure

&AtServer
Procedure UpdateDisplayOfDocumentBeingCanceled()
	
	Items.GroupToReverseAList.Visible = False;
	If Object.RecordsFilling.Count() > 1 Then
		Items.GroupToReverseAList.Visible = True;
		Items.ReversalPages.CurrentPage = Items.GroupToReverseAList;
		ReversedDocument = Undefined;
		ReversedDocument = TextEnterDocument();
		
	ElsIf Object.RecordsFilling.Count() = 1 Then
		Items.ReversalPages.CurrentPage = Items.TheGroupToCancelADocument;
		ReversedDocument = Object.RecordsFilling[0].Document;
		
	Else
		Items.ReversalPages.CurrentPage = Items.TheGroupToCancelADocument;
		ReversedDocument = TextEnterDocument();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateDisplayAccordingToChartOfAccounts()
	
	CurrencyInt = FinancialAccountingOfGeneralPurpose.AccountingCurrencies(Object.ChartOfAccounts, Object.Organization);
	CurrencyFunctional = CurrencyInt.Functional;
	
	If Not ValueIsFilled(CurrencyInt.Functional) Then
		TextAmount = NStr("vi = 'Chức năng';
							|ru = 'Функц.';
							|en = 'Functional'; fa = 'Functional';
							|it = 'Funz.';
							|pl = 'Funkc.';
							|vi = 'Chức năng (%1)'; 
							|ar= 'ُوظیفه(%1)';
							|tr = 'Fonks.'");
		TextAmountDr = NStr("vi = 'Số tiền chức năng Nợ';
							|ru = 'Сумма функц. Дт';
							|en = 'Dr funct. currency amount'; fa = 'Dr funct. currency amount';
							|it = 'Importo funz. Db';
							|vi = 'Chức năng (%1)';
							|pl = 'Wartość funkc. Wn';
							|ar= 'ُوظیفه(%1)';
							|tr = 'Tutar (fonks. para birimi) Borç'");
		TextAmountCr = NStr("vi = 'Số tiền chức năng Có';
							|ru = 'Сумма функц. Кт';
							|en = 'Cr funct. currency amount'; fa = 'Cr funct. currency amount';
							|it = 'Importo funz. Cd';   
							|ar= 'ُوظیفه(%1)';
							|vi = 'Chức năng (%1)';
							|pl = 'Wartość funkc. Ma';
							|tr = 'Tutar (fonks. para birimi) Alacak'");
	Else
		TextAmount = StrTemplate(NStr("vi = 'Chức năng (%1)';
										|ru = 'Функц. (%1)';
										|en = 'Funct. (%1)'; fa = 'Funct. (%1)';
										|it = 'Funzionale (%1)';
										|ar= 'ُوظیفه(%1)';
							|vi = 'Chức năng (%1)';
										|pl = 'Funkc. (%1)';
										|tr = 'Fonks. (%1)'"), String(CurrencyInt.Functional));
		TextAmountDr = StrTemplate(NStr("vi = 'Số tiền chức năng Nợ (%1)';
										|ru = 'Сумма функц. Дт (%1)';    
										|ar= 'ُوظیفه(%1)';
							|vi = 'Chức năng (%1)';
										|en = 'Dr funct. currency amount (%1)'; fa = 'Dr funct. currency amount (%1)';
										|it = 'Importo funz. Db (%1)';
										|pl = 'Wartość funkc. Wn (%1)';
										|tr = 'Tutar (fonks. para birimi) Borç (%1)'"), String(CurrencyInt.Functional));
		TextAmountCr = StrTemplate(NStr("vi = 'Số tiền chức năng Có (%1)';
										|ru = 'Сумма функц. Кт (%1)'; 
										|ar= 'ُوظیفه(%1)';
							|vi = 'Chức năng (%1)';
										|en = 'Cr funct. currency amount (%1)'; fa = 'Cr funct. currency amount (%1)';
										|it = 'Importo funz. Cd (%1)';
										|pl = 'Wartość funkc. Ma (%1)';
										|tr = 'Tutar (fonks. para birimi) Alacak (%1)'"), String(CurrencyInt.Functional));
	EndIf;
	Items.Sum.Title = TextAmount;
	Items.SumDr.Title = TextAmountDr;
	Items.SumCr.Title = TextAmountCr;
	
	Items.PresentationAmount.Visible = True;
	Items.PresentationAmountDr.Visible = True;
	Items.PresentationAmountCr.Visible = True;
	If Not ValueIsFilled(CurrencyInt.Presentations) Then
		TextSumOfView = NStr("vi = 'Trước đó';
							|ru = 'Пред.';
							|en = 'Presentation'; fa = 'نمایش';
							|it = 'Prec.';
							|pl = 'Prez.';
							|tr = 'Geçmiş'");
		TextSumOfViewDr = NStr("vi = 'Số tiền trình bày Nợ';
								|ru = 'Сумма предст. Дт';
								|en = 'Dr present. amount'; fa = 'مبلغ نمایش بدهکار';
								|it = 'Importo pres. Db';
								|pl = 'Wartość prez. Wn';
								|tr = 'Sunum  para birimi tutarı Borç'");
		TextSumOfViewCr = NStr("vi = 'Số tiền trình bày Có';
								|ru = 'Сумма предст. Кт';
								|en = 'Cr present. amount'; fa = 'مبلغ نمایش بستانکار';
								|it = 'Importo pres. Cd';
								|pl = 'Wartość prez. Ma';
								|tr = 'Tutar sunum para birimi Alacak'");
		Else
		PresentationCurrency = String(CurrencyInt.Presentations);
		TextSumOfView = NStr("vi = 'Trước đó';
								|ru = 'Пред.';
								|en = 'Present.'; fa = 'Present.';
								|it = 'Visualizzazione';
								|pl = 'Prez.';
								|tr = 'Geçmiş'") + " (" + PresentationCurrency + ")";
		TextSumOfViewDr = NStr("vi = 'Số tiền trình bày Nợ';
								|ru = 'Сумма предст. Дт';
								|en = 'Dr present. amount'; fa = 'مبلغ نمایش بدهکار';
								|it = 'Importo pres. Db';
								|pl = 'Wartość prez. Wn';
								|tr = 'Tutar sunum para birimi Borç'") + " (" + PresentationCurrency + ")";
		TextSumOfViewCr = NStr("vi = 'Số tiền trình bày Có';
								|ru = 'Сумма предст. Кт';
								|en = 'Cr present. amount'; fa = 'مبلغ نمایش بستانکار';
								|it = 'Importo pres. Cd';
								|pl = 'Wartość prez. Ma';
								|tr = 'Sunum tutarı Alacak'") + " (" + PresentationCurrency + ")";
		EndIf;
	Items.PresentationAmount.Title = TextSumOfView;
	Items.PresentationAmountDr.Title = TextSumOfViewDr;
	Items.PresentationAmountCr.Title = TextSumOfViewCr;
	
	If ValueIsFilled(CurrencyInt.Functional) And CurrencyInt.Functional = CurrencyInt.Presentations Then
		Items.PresentationAmount.Visible = False;
		Items.PresentationAmountDr.Visible = False;
		Items.PresentationAmountCr.Visible = False;
		TextAmount = StrTemplate(NStr("vi = 'Số tiền (%1)';
										|ru = 'Сумма (%1)';
										|en = 'Amount (%1)'; fa = 'Amount (%1)';
										|it = 'Importo (%1)';
										|pl = 'Wartość (%1)';
										|tr = 'Tutar (%1)'"), String(CurrencyInt.Functional));
		TextAmountDr = StrTemplate(NStr("vi = 'Số tiền Nợ (%1)';
										|ru = 'Сумма Дт (%1)';
										|en = 'Dr amount (%1)'; fa = 'Dr amount (%1)';
										|it = 'Importo Db (%1) ';
										|pl = 'Wartość Wn (%1)';
										|tr = 'Tutar Borç (%1)'"), String(CurrencyInt.Functional));
		TextAmountCr = StrTemplate(NStr("vi = 'Số tiền Có (%1)';
										|ru = 'Сумма Кт (%1)';
										|en = 'Cr amount (%1)'; fa = 'Cr amount (%1)';
										|it = 'Importo Cd (%1)';
										|pl = 'Wartość Ma (%1)';
										|tr = 'Tutar Alacak (%1)'"), String(CurrencyInt.Functional));
		Items.Sum.Title = TextAmount;
		Items.SumDr.Title = TextAmountDr;
		Items.SumCr.Title = TextAmountCr;
	EndIf;
	
	GroupTitle = "";
	OptionForGeneratingTransactions = Undefined;
	If ValueIsFilled(Object.ChartOfAccounts) Then
		DetailsOfChartOfAccounts = Common.ObjectAttributesValues(Object.ChartOfAccounts, "Description, OptionForGeneratingTransactions");
		GroupTitle = DetailsOfChartOfAccounts.Description;
		OptionForGeneratingTransactions = DetailsOfChartOfAccounts.OptionForGeneratingTransactions;
		
		If Not ValueIsFilled(OptionForGeneratingTransactions) Then
			ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Undefined,
				"Catalog.FinancialAccountingChartsOfAccounts", Object.ChartOfAccounts);
			If Not ProcessingCompleted Then
				OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence;
			EndIf;
		EndIf;
	EndIf;
	
	Items.PostingGroupWithoutCorrespondence.Title = GroupTitle;
	Items.GroupOfTransactionsWithCorrespondence.Title = GroupTitle;
	
	Items.PostingGroupWithoutCorrespondence.Visible = (OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence);
	Items.GroupOfTransactionsWithCorrespondence.Visible = (OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence);
	Items.ChartOfAccountsGroupIsNotSelected.Visible = Not ValueIsFilled(OptionForGeneratingTransactions);
	
EndProcedure

&AtClient
Procedure StartUploadingTransactions(CommandName)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	ThereAreRegisteredRecords = 
		Object.RegisterRecords.International.Count() > 0
		Or Object.RegisterRecords.InternationalWithoutCorrespondence.Count() > 0;
	
	If ThereAreRegisteredRecords Then
		
		ShowQueryBox(New CallbackDescription("ProcessingAnswerToQuestionThereAreLines", ThisObject, CommandName),
						NStr("vi = 'Bút toán hiện tại của chứng từ khi kết nhập sẽ bị xóa. Tiếp tục?';
							|ru = 'Текущие проводки документа при загрузке будут удалены. Продолжить?';
							|en = 'Current document entries will be deleted upon import. Continue?'; fa = 'Current document entries will be deleted upon import. Continue?';
							|it = 'Le transazioni correnti del documento durante il download saranno eliminate. Continuare?';
							|pl = 'Bieżące wpisy księgowe dokumentu podczas importowania zostaną usunięte. Kontynuować?';
							|tr = 'Mevcut belge girişleri, yükleme sırasında silinecektir. Devam edilsin mi?'"),
							QuestionDialogMode.YesNo);
	Else
		UploadTransactions(CommandName);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessingAnswerToQuestionThereAreLines(Response, CommandName) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	UploadTransactions(CommandName);
	
EndProcedure

&AtClient
Procedure UploadTransactions(CommandName)
	
	If CommandName = "ImportPostings" Then
		FormParameters = New Structure();
		FormParameters.Insert("DocumentDate", Object.Date);
		FormParameters.Insert("Organization", Object.Organization);
		FormParameters.Insert("ChartOfAccounts", Object.ChartOfAccounts);
		FormParameters.Insert("EnterPeriodByRows", Object.EnterPeriodByRows);
		OpenForm("Document.TransactionFinancialAccounting.Form.LoadForm", FormParameters, ThisForm);
	ElsIf CommandName = "ImportPostingStorno" Then
		UploadTransactionsToStornoServer();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CalculateSumOfPresentation(ChartOfAccounts, Organization, Sum, Date)
	
	Return FinancialAccountingOfGeneralPurpose.CalculateSumOfPresentation(ChartOfAccounts, Organization, Sum, Date);
	
EndFunction

&AtClient
Procedure CurrencyOnChangeClient(FormTable, DrCr)
	
	CurrentRow = FormTable.CurrentData;
	OnDate = ?(Object.EnterPeriodByRows, CurrentRow.Period, Object.Date);
	TransactionAmounts = CalculateAmounts(Object.ChartOfAccounts, Object.Organization, CurrentRow["CurrencyAmount"+DrCr], CurrentRow["Currency"+DrCr], OnDate);
	FillPropertyValues(CurrentRow, TransactionAmounts);
	If DrCr = "" Then
		FillInAuxiliaryAttributesOfTransaction(CurrentRow, ThisObject);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CalculateAmounts(ChartOfAccounts, Organization, CurrencyAmount, Currency, OnDate)
	
	TransactionAmounts = New Structure("Sum,PresentationAmount",0,0);
	ConversionFactor = FinancialAccountingOfGeneralPurpose.GetCurrencyConversionRates_(ChartOfAccounts, Organization, Currency, OnDate);
	TransactionAmounts.Sum = CurrencyAmount * ConversionFactor.ToFunctionalCurrency;
	TransactionAmounts.PresentationAmount = CurrencyAmount * ConversionFactor.CurrencyOfPresentation;
	
	Return TransactionAmounts;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	OperationTemplates - CatalogRef.StandardTransactionsOfFinancialAccounting, Array of CatalogRef.StandardTransactionsOfFinancialAccounting - 
// Returns:
// 	String - LongDesc
&AtServer
Function ProcessingOperationTemplateSelectionServer(OperationTemplates)
	
	DescriptionTexts = New Array();
	
	If TypeOf(OperationTemplates) = Type("CatalogRef.StandardTransactionsOfFinancialAccounting") Then
		DetailsText = UploadOperationTemplate(OperationTemplates);
		DescriptionTexts.Add(DetailsText);
	ElsIf TypeOf(OperationTemplates) = Type("Array") Then
		For Each Template In OperationTemplates Do
			DetailsText = UploadOperationTemplate(Template);
			DescriptionTexts.Add(DetailsText);
		EndDo;
	EndIf;
	
	Return StrConcat(DescriptionTexts, "," + Chars.LF);
	
EndFunction

&AtServer
Function UploadOperationTemplate(OperationTemplate)
	
	If Object.Organization.IsEmpty() Then
		Object.Organization = OperationTemplate.Organization;
	EndIf;
	
	If Not ValueIsFilled(Object.TransactionContent) Then
		Object.TransactionContent = OperationTemplate.TransactionContent;
	EndIf;
	
	If Not ValueIsFilled(Object.ChartOfAccounts) Then
		Object.ChartOfAccounts = OperationTemplate.ChartOfAccounts;
	EndIf;
	
	For Each AccountingEntry In OperationTemplate.TransactionsWithCorrespondence Do
		
		NewEntry = Object.RegisterRecords.International.Add();
		FillPropertyValues(NewEntry, AccountingEntry);
		NewEntry.Active = False;
		NewEntry.Period = Object.Date;
		
	EndDo;
	
	For Each AccountingEntry In OperationTemplate.TransactionsWithoutCorrespondence Do
		
		NewEntry = Object.RegisterRecords.InternationalWithoutCorrespondence.Add();
		FillPropertyValues(NewEntry, AccountingEntry);
		NewEntry.Active = False;
		NewEntry.Period = Object.Date;
		
		If AccountingEntry.RecordType = Enums.AccountingMovementKinds.Debit Then
			NewEntry.RecordType = TypeOfMovementDebit;
		ElsIf AccountingEntry.RecordType = Enums.AccountingMovementKinds.Credit Then
			NewEntry.RecordType = TypeOfMovementCredit;
		Else
			NewEntry.RecordType = Undefined;
		EndIf;
		
		NewEntry.PresentationAmount = CalculateSumOfPresentation(Object.ChartOfAccounts, Object.Organization, NewEntry.Sum, Object.Date);
		
	EndDo;
	
	FinancialAccountingOfGeneralPurpose.FillInPresentationOfExtdimensionSpecies(Object.RegisterRecords.International, "Dr");
	FinancialAccountingOfGeneralPurpose.FillInPresentationOfExtdimensionSpecies(Object.RegisterRecords.International, "Cr");
	FinancialAccountingOfGeneralPurpose.FillInPresentationOfExtdimensionSpecies(Object.RegisterRecords.InternationalWithoutCorrespondence, "");
	
	FillInAuxiliaryAttributesOfTransactionsWithoutCorrespondence();
	
	Return OperationTemplate.Description;
	
EndFunction

&AtServer
Procedure DownloadTransactionsFromStorage(AddressOfPostingsInTheStorage)
	
	If OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence Then
		Object.RegisterRecords.International.Load(GetFromTempStorage(AddressOfPostingsInTheStorage));
	Else
		Object.RegisterRecords.InternationalWithoutCorrespondence.Load(GetFromTempStorage(AddressOfPostingsInTheStorage));
		FillInAuxiliaryAttributesOfTransactionsWithoutCorrespondence();
	EndIf;
	
EndProcedure

&AtServer
Function PresentationOfExtdimensionAccounts(Account, DrCr)
	
	Return FinancialAccountingOfGeneralPurpose.PresentationOfExtdimensionSpecies(Account, DrCr);
	
EndFunction

&AtServer
Procedure UploadTransactionsToStornoServer()
	
	DocumentsStorno = Object.RecordsFilling.Unload(,"Document");
	If ValueIsFilled(ReversedDocument) Then
		NewDocument = DocumentsStorno.Add();
		NewDocument.Document = ReversedDocument;
		DocumentsStorno.GroupBy("Document");
	EndIf;
	UploadTransactionsForReversal(DocumentsStorno);
	
EndProcedure

&AtServer
Procedure UploadTransactionsForReversal(Recorders)
	
	If OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence Then
		TransactionTransactions = AccountingRegisters.International.PostingsStorno(Recorders,
			Object.ChartOfAccounts, Object.Date, Object.EnterPeriodByRows);
		Object.RegisterRecords.International.Load(TransactionTransactions);
	Else
		TransactionTransactions = AccountingRegisters.InternationalWithoutCorrespondence.PostingsStorno(Recorders,
			Object.ChartOfAccounts, Object.Date, Object.EnterPeriodByRows);
		Object.RegisterRecords.InternationalWithoutCorrespondence.Load(TransactionTransactions);
		FillInAuxiliaryAttributesOfTransactionsWithoutCorrespondence();
	EndIf;
	
EndProcedure

&AtClient
Procedure ReversedDocumentClick(Item, StandardProcessing)
	
	If TypeOf(ReversedDocument) = Type("String") Then
		
		StandardProcessing = False;
		TypesList = New ValueList;
		TypesList.LoadValues(Item.TypeRestriction.Types());
		TypesList.SortByValue();
		TypesList.Delete(TypesList.FindByValue(Type("String")));
		TypesList.ShowChooseItem(New CallbackDescription("HandlerForSelectingDocumentType", ThisObject),
											NStr("vi = 'Chọn loại:';
												|ru = 'Выберите тип:';
												|en = 'Select type:'; fa = 'Select type:';
												|it = 'Selezionare il tipo:';
												|pl = 'Wybierz typ:';
												|tr = 'Türü seçin:'"));
		
		
	EndIf;
	
EndProcedure

&AtClient
Procedure HandlerForSelectingDocumentType(Selected_2Type, AdditionalParameters) Export
	
	If Selected_2Type <> Undefined Then
		DocumentName = TypeName(Selected_2Type.Value);
		OpenForm("Document." + DocumentName + ".ChoiceForm",,ThisForm);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function TypeName(PreassignedType)
	
	Return Metadata.FindByType(PreassignedType).Name;
	
EndFunction

&AtClient
Procedure GoInList(Command)
	
	CheckBoxList = True;
	Items.ReversalPages.CurrentPage = Items.GroupToReverseAList;
	Items.GroupToReverseAList.Visible = True;
	If ValueIsFilled(ReversedDocument) And TypeOf(ReversedDocument) <> Type("String") Then
		Object.RecordsFilling.Clear();
		NewRow = Object.RecordsFilling.Add();
		NewRow.Document = ReversedDocument;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExitTheList(Command)
	
	CheckBoxList = False;
	Items.ReversalPages.CurrentPage = Items.TheGroupToCancelADocument;
	Items.GroupToReverseAList.Visible = False;
	If Object.RecordsFilling.Count() > 0 Then
		ReversedDocument = Object.RecordsFilling[0].Document;
		Object.RecordsFilling.Clear();
	ElsIf Object.RecordsFilling.Count() = 0 Then
		ReversedDocument = Undefined;
	EndIf;
	
	If Not ValueIsFilled(ReversedDocument) Then
		ReversedDocument = TextEnterDocument();
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearSelectionOptions(Item)
	Item.ChoiceParameters = New FixedArray(New Array);
EndProcedure

&AtClient
Procedure QuestionWhenYouChangeTheOrganizationEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		For Each AccountingEntry In Object.RegisterRecords.International Do
			GLAccountSettingsClient.ProcessingTransactionsWhenOrganizationChanges(AccountingEntry, TypesConnectedWithTheCompany, "Dr");
			GLAccountSettingsClient.ProcessingTransactionsWhenOrganizationChanges(AccountingEntry, TypesConnectedWithTheCompany, "Cr"); 
			GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, AccountingEntry, Object.Organization, "Dr");
			GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, AccountingEntry, Object.Organization, "Cr");
		EndDo;
		For Each AccountingEntry In Object.RegisterRecords.InternationalWithoutCorrespondence Do
			GLAccountSettingsClient.ProcessingTransactionsWhenOrganizationChanges(AccountingEntry, TypesConnectedWithTheCompany, ""); 
			GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, AccountingEntry, Object.Organization, "");
		EndDo;
		CurrentCompany = Object.Organization;
		OrganizationWhenChangedOnServer();
	Else
		Object.Organization = CurrentCompany;
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenChangingChartOfAccountsQuestion(Result, AdditionalParameters) Export
	If Result = DialogReturnCode.OK Then
		Object.RegisterRecords.International.Clear();
		Object.RegisterRecords.InternationalWithoutCorrespondence.Clear();
		CurrentAccountPlan = Object.ChartOfAccounts;
		ChartOfAccountsWhenChangedOnServer();
	Else
		Object.ChartOfAccounts = CurrentAccountPlan;
	EndIf;
	
EndProcedure

&AtServer
Procedure GenerateHeadersForInvalidatingCommands()
	
	PostingGenerationSetting = FinancialAccountingServerCached.UsedSettingsForGeneratingTransactions(
		BegOfMonth(Object.Date), Object.ChartOfAccounts, Object.Organization);
	
	MethodOfCancelingTransactions = Common.ObjectAttributeValue(PostingGenerationSetting, "MethodOfCancelingTransactions");
	
	If MethodOfCancelingTransactions = Enums.MethodsOfCancelingPostingsInFinancialAccounting.ByReversePostings Then
		Items.ExitTheList.Title = NStr("vi = 'Dự phòng một chứng từ';
										|ru = 'Реверс одного документа';
										|en = 'Reverse of a document'; fa = 'Reverse of a document';
										|it = 'Inversione di un documento';
										|pl = 'Rewers jednego dokumentu';
										|tr = 'Tek belgenin tersi'");
		Items.GoInList.Title = NStr("vi = 'Dự phòng danh sách chứng từ';
									|ru = 'Реверс списка документов';
									|en = 'Reverse of the document list'; fa = 'Reverse of the document list';
									|it = 'Inversione elenco documenti';
									|pl = 'Rewers listy dokumentów';
									|tr = 'Belgelerin listesinin tersi'");
		HeaderLoadingReverseTransactions = NStr("vi = 'Bằng các bút toán đảo ngược theo chứng từ';
												|ru = 'Реверсивными проводками по документам';
												|en = 'Reversing entries by documents'; fa = 'Reversing entries by documents';
												|it = 'Registrazioni invertibili per documento';
												|pl = 'Przez dekretowania rewersyjne według dokumentów';
												|tr = 'Belgeler göre ters girişler'");
		Items.RegisteredRecordsInternationalImportPostingStorno.Title = HeaderLoadingReverseTransactions;
		Items.InternationalWithoutCorrespondenceImportPostingStorno.Title = HeaderLoadingReverseTransactions;
	Else
		Items.ExitTheList.Title = NStr("vi = 'Đảo ngược một chứng từ';
										|ru = 'Сторно одного документа';
										|en = 'One document storno'; fa = 'یک سند استورنو';
										|it = 'Storno di un documento';
										|pl = 'Storno jednego dokumentu';
										|tr = 'Tek belgenin iptali'");
		Items.GoInList.Title = NStr("vi = 'Đảo ngược danh sách chứng từ';
									|ru = 'Сторно списка документов';
									|en = 'Document list storno'; fa = 'فهرست اسناد استورنو';
									|it = 'Storno elenco dei documenti';
									|pl = 'Storno listy dokumentów';
									|tr = 'Belgeler listesi iptali'");
		HeaderLoadingReverseTransactions = NStr("vi = 'Đảo ngược bởi các bút toán theo chứng từ';
												|ru = 'Сторно проводками по документам';
												|en = 'Storno entries by documents'; fa = 'ثبت‌های استورنو بر اساس اسناد';
												|it = 'Storno delle registrazioni per documenti';
												|pl = 'Przez storno dekretowania według dokumentów';
												|tr = 'Belgelere göre girişlerin iptali'");
		Items.RegisteredRecordsInternationalImportPostingStorno.Title = HeaderLoadingReverseTransactions;
		Items.InternationalWithoutCorrespondenceImportPostingStorno.Title = HeaderLoadingReverseTransactions;
	EndIf;
	
	FinancialAccountingOfGeneralPurpose.AddTypesOfInvalidTransactions(MethodOfCancelingTransactions,
		Items.PostingType.ChoiceList);
	FinancialAccountingOfGeneralPurpose.AddTypesOfInvalidTransactions(MethodOfCancelingTransactions,
		Items.InternationalWithoutCorrespondencePostingType.ChoiceList);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateResultsOfTransactionsWithoutCorrespondence(ThisForm)
	
	Items = ThisForm.Items;
	
	ThisForm.TotalAmount_5Dr = 0;
	ThisForm.TotalAmount_5Cr = 0;
	ThisForm.ResultIsSumOfDrSubmission = 0;
	ThisForm.ResultIsSumOfCrRepresentation = 0;
	For Each Record In ThisForm.Object.RegisterRecords.InternationalWithoutCorrespondence Do
		ThisForm.TotalAmount_5Dr = ThisForm.TotalAmount_5Dr + ?(Record.RecordType = ThisForm.TypeOfMovementDebit, Record.Sum, 0);
		ThisForm.TotalAmount_5Cr = ThisForm.TotalAmount_5Cr + ?(Record.RecordType = ThisForm.TypeOfMovementCredit, Record.Sum, 0);
		ThisForm.ResultIsSumOfDrSubmission = ThisForm.ResultIsSumOfDrSubmission + ?(Record.RecordType = ThisForm.TypeOfMovementDebit, Record.PresentationAmount, 0);
		ThisForm.ResultIsSumOfCrRepresentation = ThisForm.ResultIsSumOfCrRepresentation + ?(Record.RecordType = ThisForm.TypeOfMovementCredit, Record.PresentationAmount, 0);
	EndDo;
	
	If ThisForm.TotalAmount_5Dr <> ThisForm.TotalAmount_5Cr Then
		Items.SumDr.FooterTextColor = ThisForm.OverdueDataColor;
		Items.SumCr.FooterTextColor = ThisForm.OverdueDataColor;
	Else
		Items.SumDr.FooterTextColor = New Color();
		Items.SumCr.FooterTextColor = New Color();
	EndIf;
	
	If ThisForm.ResultIsSumOfDrSubmission <> ThisForm.ResultIsSumOfCrRepresentation Then
		Items.PresentationAmountDr.FooterTextColor = ThisForm.OverdueDataColor;
		Items.PresentationAmountCr.FooterTextColor = ThisForm.OverdueDataColor;
	Else
		Items.PresentationAmountDr.FooterTextColor = New Color();
		Items.PresentationAmountCr.FooterTextColor = New Color();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAuxiliaryAttributesOfTransactionsWithoutCorrespondence()
	
	For Each Record In Object.RegisterRecords.InternationalWithoutCorrespondence Do
		FillInAuxiliaryAttributesOfTransaction(Record, ThisObject);
	EndDo;
	CalculateResultsOfTransactionsWithoutCorrespondence(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInAuxiliaryAttributesOfTransaction(Record, ThisForm)
	
	Record.SumDr = ?(Record.RecordType = ThisForm.TypeOfMovementDebit, Record.Sum, 0);
	Record.SumCr = ?(Record.RecordType = ThisForm.TypeOfMovementCredit, Record.Sum, 0);
	Record.PresentationAmountDr = ?(Record.RecordType = ThisForm.TypeOfMovementDebit, Record.PresentationAmount, 0);
	Record.PresentationAmountCr = ?(Record.RecordType = ThisForm.TypeOfMovementCredit, Record.PresentationAmount, 0);
	Record.TypeOfMovementIndex = TypeOfMovementIndexOfImage(Record.RecordType, Record.Active, Record.Sum, ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Function TypeOfMovementIndexOfImage(RecordType, Active, Sum, ThisForms)
	
	If RecordType = ThisForms.TypeOfMovementDebit And Sum <> 0 Then
		Return ?(Active, 1, 3);
	ElsIf RecordType = ThisForms.TypeOfMovementCredit And Sum <> 0 Then
		Return ?(Active, 2, 4);
	Else
		Return 0;
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function TextEnterDocument()
	Return NStr("vi = 'Nhập chứng từ';
				|ru = 'Ввести документ';
				|en = 'Enter document'; fa = 'Enter document';
				|it = 'Inserire il documento';
				|pl = 'Wprowadź dokument';
				|tr = 'Belge girişi'");
EndFunction;

#EndRegion
