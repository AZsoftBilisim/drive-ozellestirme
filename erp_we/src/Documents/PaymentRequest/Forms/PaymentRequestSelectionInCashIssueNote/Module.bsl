#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();

	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	Currency = Parameters.Currency;
	DocumentAmount = Parameters.DocumentAmount;
	DocumentDate  = Parameters.Date;
	BankAccountCashAccount = Parameters.BankAccountCashAccount;
	
	ThereIsCashlessPayment = Parameters.PaymentMethod.Find(Enums.PaymentForms.BankAccountPayment) <> Undefined;
	ThereIsCashPayment = Parameters.PaymentMethod.Find(Enums.PaymentForms.CashAccountPayment_) <> Undefined;
	
	If ThereIsCashlessPayment Then
		PaymentMethod = Enums.PaymentForms.BankAccountPayment;
	ElsIf ThereIsCashPayment Then
		PaymentMethod = Enums.PaymentForms.CashAccountPayment_;
	Else
		PaymentMethod = Enums.PaymentForms.PaymentCard;
	EndIf;
	
	AddressOfPaymentsInTheStorage = Parameters.AddressOfPaymentsInTheStorage;
	
	FillInApplicationTable();
	SelectGoodsClientServer.CreateSelectionFormHeader(Title, Parameters.Ref);
	
	ConfigurationModificationOverridable.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	CalculateAmountOfPayments();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Cancel = True;
		Return;
	EndIf;
	
	If Not ClosingInProgress And Modified Then
		Cancel = True;
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject),
			NStr("vi = 'Dữ liệu bị thay đổi. Đưa các thay đổi vào chứng từ?';
				|ru = 'Данные были изменены. Перенести изменения в документ?';
				|en = 'The data was modified. Migrate the changes to the document?'; fa = 'The data was modified. Migrate the changes to the document?';
				|it = 'I dati sono stati modificati. Trasferire le modifiche nel documento?';
				|pl = 'Dane zostały zmienione. Przenieść zmiany do dokumentu?';
				|tr = 'Veriler değiştirildi. Değişiklikler belgeye aktarılsın mı?'"),
			QuestionDialogMode.YesNoCancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.Yes Then
		ClosingInProgress = True;
		Modified = False;
		MoveRequestsToDocument();
		
	ElsIf Response = DialogReturnCode.No Then
		ClosingInProgress = True;
		Modified = False;
		Close();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure RequestsTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.RequestsTable.CurrentData <> Undefined Then
		If Field.Name = "RequestsTableRequestPresentation" Then
			ShowValue(Undefined, Items.RequestsTable.CurrentData.PaymentRequest);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure RequestsTableOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateAmountOfPayments();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectRows(Command)
	
	SelectAllApplicationsOnServer(True);
	CalculateAmountOfPayments();
	
EndProcedure

&AtClient
Procedure ClearRows(Command)
	
	SelectAllApplicationsOnServer(False);
	CalculateAmountOfPayments();
	
EndProcedure

&AtClient
Procedure MoveToDocument(Command)
	
	MoveRequestsToDocument();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RequestsTableRequestPresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RequestsTable.PaymentRequest");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RequestsTable.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RequestsTable.ExistsInTheDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	
EndProcedure

&AtServer
Procedure SelectAllApplicationsOnServer(SelectionValue = True)
	
	For Each TableRow In RequestsTable.FindRows(New Structure("RowIsSelected", Not SelectionValue)) Do
		
		TableRow.RowIsSelected = SelectionValue;
		
	EndDo;
	
EndProcedure

&AtServer
Function PlaceApplicationsInRepository()
	
	// Forming a table to return to the document
	TableOfSelectedApplications = RequestsTable.Unload(New Structure("RowIsSelected", True));
	
	FillingData = New Structure;
	FillingData.Insert("DocumentBasis", TableOfSelectedApplications.UnloadColumn("PaymentRequest"));
	FillingData.Insert("BankAccountCashAccount", BankAccountCashAccount);
	FillingData.Insert("Sum", 0);
	
	RequestsTable.Clear();
	CashServer.FillOutDocumentOnApplicationsForSpendingMoney(FillingData, RequestsTable, PaymentMethod);
	
	TableOfSelectedApplications = RequestsTable.Unload();
	TableOfSelectedApplications.Columns.Add("PaymentPurpose");
	TableOfSelectedApplications.Columns.Add("PaymentID", Common.StringTypeDetails(25));
	TableOfSelectedApplications.LoadColumn(TableOfSelectedApplications.UnloadColumn("ARAPObject"), "PaymentPurpose");
	TableOfSelectedApplications.FillValues(FillingData.PaymentID, "PaymentID");
	
	AddressOfRequestsInRepository = PutToTempStorage(TableOfSelectedApplications);
	
	Return AddressOfRequestsInRepository;
	
EndFunction

&AtServer
Procedure FillInApplicationTable()
	
	SelectionData_ = New Structure(
		"Counterparty,
		|BankAccountBeneficiary,
		|CashAccountRecipient,
		|AdvanceHolder,
		|Organization,
		|BusinessOperation,
		|PayrollTransaction,
		|Currency,
		|PaymentMethod,
		|BankAccountCashAccount,
		|Ref,
		|Date,
		|ListOfCounterparties_,
		|OperationWithSelfEmployedPerson");
		
	FillPropertyValues(SelectionData_, Parameters);
	
	CashServer.FillInBalancesOfApplicationsForSpendingMoney(SelectionData_, RequestsTable);
	
	SetSignsOfPresenceOfLineInDocument(RequestsTable);
	
EndProcedure

&AtServer
Procedure SetSignsOfPresenceOfLineInDocument(RequestsTable)
	
	If IsTempStorageURL(AddressOfPaymentsInTheStorage) Then
		
		TheStructureOfTheSearch = New Structure("PaymentRequest, Sum");
		
		ARAPDetails = GetFromTempStorage(AddressOfPaymentsInTheStorage);
		
		For Each PaymentLine_1 In RequestsTable Do
			
			FillPropertyValues(TheStructureOfTheSearch, PaymentLine_1);
			
			Rows = ARAPDetails.FindRows(TheStructureOfTheSearch);
			If Rows.Count() Then
				PaymentLine_1.ExistsInTheDocument = True;
			EndIf;
			
			PaymentLine_1.RowIsSelected = Not PaymentLine_1.ExistsInTheDocument;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure MoveRequestsToDocument()
	
	// Removal of modifiability, because before closing, the attribute is checked
	Modified = False;
	AddressOfRequestsInRepository = PlaceApplicationsInRepository();
	Close();
	NotifyChoice(New Structure("AddressOfRequestsInRepository", AddressOfRequestsInRepository));
	
EndProcedure

&AtClient
Procedure CalculateAmountOfPayments()
	
	AmountByPayments = 0;
	For Each TableRow In RequestsTable Do
		If TableRow.RowIsSelected Then
			AmountByPayments = AmountByPayments + TableRow.Sum;
		EndIf;
	EndDo;
	
EndProcedure

ClosingInProgress = False;

#EndRegion
