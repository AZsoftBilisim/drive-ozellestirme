
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Contract", Parameters.Contract);
	OpeningParameters.Insert("Counterparty", Parameters.Counterparty);
	OpeningParameters.Insert("Organization", Parameters.Organization);
	OpeningParameters.Insert("TypeOfLeasePayment", Parameters.TypeOfLeasePayment);
	OpeningParameters.Insert("SelectedARAPDocument", ?(Parameters.Property("SelectedARAPDocument"), Parameters.SelectedARAPDocument, Undefined));
	
	SetConditionalAppearance();
	
	FillInListOfPayments();
	
	Items.ListOfPaymentPaymentType.Visible =
		TypeOf(OpeningParameters.TypeOfLeasePayment) = Type("Array")
		And OpeningParameters.TypeOfLeasePayment.Count() > 1;
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfPayment

&AtClient
Procedure ListOfPaymentSelection(Item, RowSelected, Field, StandardProcessing)

	StandardProcessing = False;
	
	CurrentData = Items.ListOfPayment.CurrentData;
	
	If Field = Items.ListOfPaymentARAPDocument
		And CurrentData <> Undefined
		And ValueIsFilled(CurrentData.ARAPDocument) Then
		
		ShowValue(, CurrentData.ARAPDocument);
	Else
		CompleteSelection();
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectDocument(Command)
	
	CompleteSelection();
	
EndProcedure

&AtClient
Procedure OpenDocument(Command)
	
	TableRow = Items.ListOfPayment.CurrentData;
	If TableRow <> Undefined Then
		ShowValue(, TableRow.ARAPDocument);
	EndIf;
	
EndProcedure

// Create a document.
// Creates a new document Primary document.
// Parameters:
//  Command - FormCommand - Command
&AtClient
Procedure CreateDocument(Command)
	
	AddOpeningParameters(OpeningParameters);
	
	UpdateAfterCreation = New CallbackDescription("UpdateList",ThisForm);
	CreationParameters = New Structure("Basis", OpeningParameters);
	
	OpenForm("Document.SourceDocument.ObjectForm",CreationParameters,ThisForm, , , , UpdateAfterCreation);

EndProcedure

&AtServerNoContext
Procedure AddOpeningParameters(OpeningParameters)
	
	If ValueIsFilled(OpeningParameters.Contract) Then
		OpeningParameters.Insert("ContractCurrency", OpeningParameters.Contract.ARAPCurrency);
	EndIf;
	
	If ValueIsFilled(OpeningParameters.Counterparty) Then
		OpeningParameters.Insert("Partner", OpeningParameters.Counterparty.Partner);
	EndIf;
	
EndProcedure



#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(
		ThisObject, "ListOfPayment.Date", Items.ListOfPaymentDate.Name);
	
	#Region PaymentListSettlementDocument_TextColor
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfPaymentARAPDocument.Name);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	#EndRegion
	
	#Region ListOfPaymentARAPDocument_SelectedDocument
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfPaymentDate.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfPaymentNumber.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfPaymentPaymentType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfPaymentSum.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfPaymentBalance.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfPaymentCurrency.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfPaymentARAPDocument.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("ListOfPayment.ARAPDocument");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = OpeningParameters.SelectedARAPDocument;
	
	Item.Appearance.SetParameterValue("Font", StyleFonts.ImportantLabelFont);
	#EndRegion
		
EndProcedure

&AtServer
Procedure FillInListOfPayments()
	
	QueryText = 
	"SELECT ALLOWED
	|	FinancialInstrumentsARAPBalance.ARAPDocument AS ARAPDocument,
	|	FinancialInstrumentsARAPBalance.SumBalance AS Balance
	|INTO BalancesOnARAPDocuments
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Balance(, Contract IN (&AssociatedContracts)
	|	AND AmountType IN (&TypeOfLeasePayment)) AS FinancialInstrumentsARAPBalance
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT ALLOWED
	|	DocumentData.Ref AS ARAPDocument,
	|	DocumentData.Date AS Date,
	|	DocumentData.Number AS Number,
	|	DocumentData.Currency AS Currency,
	|	PaymentDecryptionTable.TypeOfLeasePayment AS PaymentType,
	|	PaymentDecryptionTable.Sum AS Sum,
	|	ISNULL(BalancesOnARAPDocuments.Balance, 0) AS Balance
	|FROM
	|	Document.BankAccountIssue AS DocumentData
	|		INNER JOIN Document.BankAccountIssue.ARAPDetails AS PaymentDecryptionTable
	|		ON DocumentData.Ref = PaymentDecryptionTable.Ref
	|			AND PaymentDecryptionTable.LeaseContracts IN (&AssociatedContracts)
	|			AND PaymentDecryptionTable.TypeOfLeasePayment IN (&TypeOfLeasePayment)
	|		LEFT JOIN BalancesOnARAPDocuments AS BalancesOnARAPDocuments
	|		ON DocumentData.Ref = BalancesOnARAPDocuments.ARAPDocument
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
	|	AND DocumentData.Organization = &Organization
	|	AND DocumentData.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref,
	|	DocumentData.Date,
	|	DocumentData.Number,
	|	DocumentData.Currency,
	|	PaymentDecryptionTable.TypeOfLeasePayment,
	|	PaymentDecryptionTable.Sum,
	|	ISNULL(BalancesOnARAPDocuments.Balance, 0)
	|FROM
	|	Document.CashVoucher AS DocumentData
	|		INNER JOIN Document.CashVoucher.ARAPDetails AS PaymentDecryptionTable
	|		ON DocumentData.Ref = PaymentDecryptionTable.Ref
	|			AND PaymentDecryptionTable.LeaseContracts IN (&AssociatedContracts)
	|			AND PaymentDecryptionTable.TypeOfLeasePayment IN (&TypeOfLeasePayment)
	|		LEFT JOIN BalancesOnARAPDocuments AS BalancesOnARAPDocuments
	|		ON DocumentData.Ref = BalancesOnARAPDocuments.ARAPDocument
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentToLessor)
	|	AND DocumentData.Organization = &Organization
	|	AND DocumentData.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref,
	|	DocumentData.Date,
	|	DocumentData.Number,
	|	DocumentData.Currency,
	|	UNDEFINED AS TypeOfLeasePayment,
	|	DocumentData.DocumentAmount,
	|	DocumentData.DocumentAmount
	|FROM
	|	Document.SourceDocument AS DocumentData
	|WHERE
	|	DocumentData.Organization = &Organization
	|	AND DocumentData.Contract IN (&AssociatedContracts)
	|	AND DocumentData.Posted
	|
	|ORDER BY
	|	Date,
	|	Number,
	|	Sum";
	
	Query = New Query(QueryText);
	Query.SetParameter("Organization", OpeningParameters.Organization);
	Query.SetParameter("Counterparty", OpeningParameters.Counterparty);
	Query.SetParameter("Contract", OpeningParameters.Contract);
	Query.SetParameter("TypeOfLeasePayment", OpeningParameters.TypeOfLeasePayment);
	Query.SetParameter("AssociatedContracts", LeasedAssetAccounting.RelatedLeaseContracts(OpeningParameters.Contract));
	
	Result = Query.Execute();
	ListOfPayment.Load(Result.Unload());
	
EndProcedure

&AtClient
Procedure UpdateList(Result, AdditionalParameters) Export
	FillInListOfPayments();
EndProcedure

&AtClient
Procedure CompleteSelection()
	
	TableRow = Items.ListOfPayment.CurrentData;
	
	If TableRow <> Undefined Then
		SelectionResult = New Structure("ARAPDocument,PaymentType", TableRow.ARAPDocument, TableRow.PaymentType);		
		NotifyChoice(SelectionResult);
	Else
		Close();
	EndIf;
	
EndProcedure

#EndRegion