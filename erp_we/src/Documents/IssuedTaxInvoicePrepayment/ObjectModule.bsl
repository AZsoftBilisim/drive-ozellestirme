#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	IssuedTaxInvoicePrepaymentLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	IssuedTaxInvoicePrepaymentLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.TSName = "Prepayments";
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
	
	If TypeOf(DocumentBasis) <> Type("DocumentRef.OBEntry")
		And TypeOf(DocumentBasis) <> Type("DocumentRef.OBEntryARAP")
		And TypeOf(DocumentBasis) <> Type("DocumentRef.ARAPSettlement") Then
		
		NotCheckedAttributeArray.Add("Counterparty");
	EndIf; 
	
	If Not ValueIsFilled(SettlementDocumentNumber)
		And Not ValueIsFilled(DateOfDocumentInARAPAccounting) Then
		
		NotCheckedAttributeArray.Add("SettlementDocumentNumber");
		NotCheckedAttributeArray.Add("DateOfDocumentInARAPAccounting");
	EndIf; 
	
	If Not ValueIsFilled(ThisObject.Ref) Then
		NotCheckedAttributeArray.Add("CorrectionNumber");
	EndIf;
	
	If Not Patch Then
		NotCheckedAttributeArray.Add("BaseDocumentTaxInvoice");
		NotCheckedAttributeArray.Add("CorrectionNumber");
	EndIf;
	
	If Not Corrective Then
		NotCheckedAttributeArray.Add("Prepayments.OriginalTaxInvoice");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	IssuedTaxInvoicePrepaymentLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

	If WriteMode = DocumentWriteMode.Posting Then
		CheckDuplicateInvoices(Cancel);
	EndIf;
	
	Sum    = Prepayments.Total("Sum");
	VATAmount = Prepayments.Total("VATAmount");
	
	GenerateStringOfSettlementAndPaymentDocuments();
	FillInDateOfReceiptOfAdvance();
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Prepayments");
	
	IssuedTaxInvoicePrepaymentLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If WriteMode = DocumentWriteMode.UndoPosting Then
		ManualAdjustmentOfTaxInvoiceRegister = False;
	EndIf;
	
EndProcedure

Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	SetPrivilegedMode(True);
	
	If Patch Then
		
		Query = New Query("
		|SELECT
		|	CASE
		|		WHEN IssuedTaxInvoicePrepayment.Patch
		|			THEN IssuedTaxInvoicePrepayment.BaseDocumentTaxInvoice
		|		ELSE IssuedTaxInvoicePrepayment.Ref
		|	END                          AS Ref,
		|	IssuedTaxInvoicePrepayment.Number AS Number
		|INTO SourceDocuments
		|FROM Document.IssuedTaxInvoicePrepayment AS IssuedTaxInvoicePrepayment
		|WHERE
		|	IssuedTaxInvoicePrepayment.Ref = &BaseDocumentTaxInvoice
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT TOP 1
		|	SourceDocuments.Number AS Number,
		|	ISNULL(Corrections.CorrectionNumber, 0) AS CorrectionNumber
		|FROM
		|	SourceDocuments AS SourceDocuments
		|		LEFT JOIN Document.IssuedTaxInvoicePrepayment AS Corrections
		|		ON SourceDocuments.Ref = Corrections.BaseDocumentTaxInvoice
		|			AND SourceDocuments.Ref <> Corrections.Ref
		|			AND Corrections.Patch
		|			AND NOT Corrections.DeletionMark
		|
		|ORDER BY
		|	CorrectionNumber DESC");
		
		Query.SetParameter("BaseDocumentTaxInvoice", BaseDocumentTaxInvoice);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			StandardProcessing = False;
			// Setting the number and redefining the prefix of the information base.
			UsePrefix = GetFunctionalOption("KeepSeparateNumberingOfTaxInvoicesIssuedForAdvances");
			If UsePrefix Then
				Prefix = "EEYORE";
				PrefixLength = 2;
			Else
				Prefix = "And";
				PrefixLength = 1;
			EndIf;
			ObjectsPrefixesEvents.SetInfobaseAndCompanyPrefix(ThisObject, StandardProcessing, Prefix);
			
			NumberWithoutPrefix = ObjectsPrefixesClientServer.DeletePrefixesFromObjectNumber(Selection.Number, True, True);
			If StrLen(TrimR(NumberWithoutPrefix)) = 7 Then
				NumberWithoutPrefix = Right(NumberWithoutPrefix, StrLen(NumberWithoutPrefix)-PrefixLength);
			EndIf;
			Number = Prefix + NumberWithoutPrefix;
			CorrectionNumber = Format(Number(Selection.CorrectionNumber) + 1, "ND=10; NFD=0; NG=0");
		EndIf;
	Else
		UsePrefix = GetFunctionalOption("KeepSeparateNumberingOfTaxInvoicesIssuedForAdvances");
		If UsePrefix Then
			Prefix = "A";
		Else
			Prefix = "0";
		EndIf;
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		If FillingData.Property("Patch") 
			 And FillingData.Patch
			 And FillingData.Property("BaseDocumentTaxInvoice") Then
			
			If DocumentCorrection.IsThereFixOrReverse(FillingData.BaseDocumentTaxInvoice) Then
				Text = NStr("vi = 'На основании введен документ ""Сторно"". Регистрация исправительного счета-фактуры невозможна.';
							|ru = 'На основании введен документ ""Сторно"". Регистрация исправительного счета-фактуры невозможна.';
							|en = 'The ""Storno"" document is already entered using the base document. Cannot register a replacement tax invoice.'; fa = 'The ""Storno"" document is already entered using the base document. Cannot register a replacement tax invoice.';
							|it = 'На основании введен документ ""Сторно"". Регистрация исправительного счета-фактуры невозможна.';
							|pl = 'The ""Storno"" document is already entered using the base document. Cannot register a replacement tax invoice.';
							|tr = 'На основании введен документ ""Сторно"". Регистрация исправительного счета-фактуры невозможна.'");
				Raise Text;
			EndIf;
			
			FillInCorrectionOnInvoice(FillingData);
		EndIf;
	ElsIf TypeOf(FillingData) = Type("DocumentRef.CashAccountReceiptNote") Then
		DetailsOfFillingInForm = DetailsCashReceiptOrder(FillingData);
		FillInPaymentDocument(DetailsOfFillingInForm);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.BankAccountReceiptNote") Then
		DetailsOfFillingInForm = DetailsReceiptOfNonCashFunds(FillingData);
		FillInPaymentDocument(DetailsOfFillingInForm);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ReceivedTaxInvoicePrepayment") Then
		FillInInvoiceReceivedInAdvance(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ARAPSettlement") Then
		FillInOffsetOfDebt(FillingData);
	EndIf;
	
	IssuedTaxInvoicePrepaymentLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Prepayments");
	
	IssuedTaxInvoicePrepaymentLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure
	

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	If Not Cancel Then
		DocumentsArray= New Array;
		DocumentsArray.Add(Ref);
		VATAccountingERP.GenerateTasksBasedOnDocuments(DocumentsArray);
	EndIf;
	
	IssuedTaxInvoicePrepaymentLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Organization") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("EmployeeResponsible") Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Department") Then
		Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	EndIf;
	
EndProcedure

Function DetailsCashReceiptOrder(Var_Ref)
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	DocumentData.Date					AS Date,
	|	DocumentData.Ref					AS Ref,
	|	DocumentData.Posted				AS Posted,
	|	DocumentData.BusinessOperation	AS BusinessOperation,
	|	CASE
	|		WHEN ISNULL(TSARAPDetails.ARAPObject.Organization,
	|				VALUE(Catalog.Companies.EmptyRef)) = VALUE(Catalog.Companies.EmptyRef)
	|			THEN DocumentData.Organization
	|		ELSE
	|			TSARAPDetails.ARAPObject.Organization
	|	END									AS Organization,
	|	CASE
	|		WHEN ISNULL(TSARAPDetails.ARAPObject.Organization,
	|				VALUE(Catalog.Companies.EmptyRef)) = VALUE(Catalog.Companies.EmptyRef)
	|			THEN DocumentData.Department
	|		ELSE
	|			TSARAPDetails.ARAPObject.Department
	|	END									AS Department,
	|	CASE WHEN
	|		DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
	|			VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
	|		)
	|	THEN
	|		DocumentData.CashAccountIssuer.Owner
	|	ELSE
	|		DocumentData.Counterparty
	|	END 									AS Counterparty,
	|	DocumentData.VATTaxation		AS VATTaxation
	|FROM
	|	Document.CashAccountReceiptNote AS DocumentData
	|		LEFT JOIN Document.CashAccountReceiptNote.ARAPDetails AS TSARAPDetails
	|			ON DocumentData.Ref = TSARAPDetails.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	Query.SetParameter("Ref", Var_Ref);
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection;
	
EndFunction

Function DetailsReceiptOfNonCashFunds(Var_Ref)
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	DocumentData.BankPostingDate	AS Date,
	|	DocumentData.Ref					AS Ref,
	|	DocumentData.Posted				AS Posted,
	|	DocumentData.BusinessOperation	AS BusinessOperation,
	|	CASE
	|		WHEN ISNULL(TSARAPDetails.ARAPObject.Organization,
	|				VALUE(Catalog.Companies.EmptyRef)) = VALUE(Catalog.Companies.EmptyRef)
	|			THEN DocumentData.Organization
	|		ELSE
	|			TSARAPDetails.ARAPObject.Organization
	|	END									AS Organization,
	|	CASE
	|		WHEN ISNULL(TSARAPDetails.ARAPObject.Organization,
	|				VALUE(Catalog.Companies.EmptyRef)) = VALUE(Catalog.Companies.EmptyRef)
	|			THEN DocumentData.Department
	|		ELSE
	|			TSARAPDetails.ARAPObject.Department
	|	END									AS Department,
	|	DocumentData.ProcessedByBank			AS ProcessedByBank,
	|	CASE WHEN
	|		DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany),
	|			VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
	|		)
	|	THEN
	|		DocumentData.SenderBankAccount.Owner
	|	ELSE
	|		DocumentData.Counterparty
	|	END 									AS Counterparty,
	|	DocumentData.VATTaxation		AS VATTaxation
	|FROM
	|	Document.BankAccountReceiptNote AS DocumentData
	|		LEFT JOIN Document.BankAccountReceiptNote.ARAPDetails AS TSARAPDetails
	|			ON DocumentData.Ref = TSARAPDetails.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	Query.SetParameter("Ref", Var_Ref);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection;
	
EndFunction

Procedure FillInPaymentDocument(DetailsOfFillingInForm)
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(DetailsOfFillingInForm.Ref, , Not DetailsOfFillingInForm.Posted);
	
	VATOperations = BusinessTransactionsVATAdvance();
	If VATOperations.Find(DetailsOfFillingInForm.BusinessOperation) = Undefined Then
		ErrorText = NStr("vi = 'Không cần nhập hóa đơn GTGT ứng trước trên cơ sở chứng từ %Document%';
						|ru = 'Не требуется вводить счет-фактуру на аванс на основании документа %Document%';
						|en = 'It is not required to enter a tax invoice for advance based on document %Document%'; fa = 'It is not required to enter a tax invoice for advance based on document %Document%';
						|it = 'Non è richiesto di inserire la fattura per il pagamento anticipato per il documento%Document%';
						|pl = 'Nie trzeba wprowadzać faktury dla zaliczki na podstawie dokumentu %Document%';
						|tr = '%Document% belgesi temelinde bir avans için fatura girmeye gerek yoktur'");
		ErrorText = StrReplace(ErrorText, "%Document%", DetailsOfFillingInForm.Ref);
		Raise ErrorText;
	EndIf;
	
	If CommonClientServer.HasAttributeOrObjectProperty(DetailsOfFillingInForm, "ProcessedByBank")
		And DetailsOfFillingInForm.ProcessedByBank <> True Then
		ErrorText = NStr("vi = 'Trước khi nhập hóa đơn GTGT cho khoản ứng trước theo chứng từ %Document%, cần thiết lập dấu hiệu ""Được thực hiện bởi ngân hàng""';
						|ru = 'Перед вводом счет-фактуры на аванс по документу %Document% необходимо установить признак ""Проведено банком""';
						|en = 'Set ""Processed by bank"" flag before entering tax invoice to advance by %Document% document'; fa = 'Set ""Processed by bank"" flag before entering tax invoice to advance by %Document% document';
						|it = 'Prima di inserire la fattura dell''anticipo in base al documento %Document% è necessario impostare l''indicazione ""Registrato dalla banca""';
						|pl = 'Przed wprowadzeniem faktury VAT na zaliczkę dla dokumentu %Document% należy zaznaczyć oznakę ""Potwierdzono przez bank""';
						|tr = '%Document% belgesine bir avans faturası girmeden önce, ""Banka tarafından gerçekleştirildi"" işareti ayarlanmalıdır'");
		ErrorText = StrReplace(ErrorText, "%Document%", DetailsOfFillingInForm.Ref);
		Raise ErrorText;
	EndIf;
	
	VATTaxation = DetailsOfFillingInForm.VATTaxation;
	
	If Not ValueIsFilled(VATTaxation) Then
		VATTaxation = VATAccountingERP.AccountingParametersForOrganization(DetailsOfFillingInForm.Organization, CurrentSessionDate()).BasicTaxationVATSales;
	EndIf;
	
	If VATTaxation = Enums.VATTaxationTypes.SubjectToVATAtCustomer Then
		TransactionKindCode = "33";
	EndIf;
	
	FillPropertyValues(ThisObject, DetailsOfFillingInForm, "Organization, Counterparty");
	CounterpartyDetails_ = PartnersAndCounterparties.CounterpartyDetails_(Counterparty, CurrentSessionDate());
	TINOfCounterparty = CounterpartyDetails_.TIN;
	
	DocumentBasis	= DetailsOfFillingInForm.Ref;
	IssueDate		= CurrentSessionDate();
	
	IncomingNumberAndDate = Documents.IssuedTaxInvoicePrepayment.IncomingDocumentNumberAndDate(DocumentBasis, Counterparty);
	FillPropertyValues(ThisObject, IncomingNumberAndDate);
	
	Query = New Query();
	Query.Text = "
	|SELECT DISTINCT
	|	CustomersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|WHERE
	|	CustomersARAPAccounting.Recorder = &Ref
	|	AND CustomersARAPAccounting.Active
	|";
	Query.SetParameter("Ref", DocumentBasis);
		
	AnalystTable = Query.Execute().Unload();
	ArrayOfAccountingAnalystsForPartners = AnalystTable.UnloadColumn("AccountingDimensionByPartners");
		
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		If ArrayOfAccountingAnalystsForPartners.Count() > 0 Then
			CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
			CalculationAnalysts.AccountingAnalyticsForPartners = ArrayOfAccountingAnalystsForPartners;
			Try
				ARAPAllocationServerCall.DistributeAllSettlementsWithCustomers(EndOfMonth(DetailsOfFillingInForm.Date),CalculationAnalysts);
			Except
				MessageText = NStr("vi = 'Mẫu in đã được lập theo dữ liệu không thực.
				|Cần cập nhật hạch toán công nợ một cách thủ công và lập lại mẫu in.';
				|ru = 'Печатная форма сформирована по неактуальным данным.
				|Необходимо актуализировать взаиморасчеты вручную и переформировать печатную форму.';
				|en = 'Print form is generated according to irrelevant data.
				|Update AR/AP accounting manually, and then create the print form again.'; fa = 'Print form is generated according to irrelevant data.
				|Update AR/AP accounting manually, and then create the print form again.';
				|it = 'La versione di stampa è stata creata in base ai dati obsoleti.
				| È necessario attualizzare manualmente le regolazioni reciproche dei conti e creare una nuova versione stampa.';
				|pl = 'Formularz wydruku jest tworzony na podstawie nieaktualnych danych.
				|Konieczna jest ręczna aktualizacja wzajemnych rozliczeń i ponowne drukowanie formularza wydruku.';
				|tr = 'Çıktı alakasız veriler kullanılarak oluşturulmuştur.
				| Hesapları manuel olarak güncellemeniz ve çıktıyı yeniden oluşturmanız gerekecektir.'");
				CommonClientServer.MessageToUser(MessageText);
			EndTry;
		EndIf;
	Else
		If ArrayOfAccountingAnalystsForPartners.Count() > 0 
			And InformationRegisters.JobsForARAPAllocating.CurrentPeriodOfCalculatedDataOnMutualSettlements(ArrayOfAccountingAnalystsForPartners,, EndOfMonth(DetailsOfFillingInForm.Date)) <> Undefined Then
			MessageText = ARAPAccountingServer.TextOfWarningOfAssignmentOfDistributionOfMutualSettlements();
			Common.MessageToUser(MessageText);
		EndIf;
	EndIf;
	
	SelectionOfAdvances = Documents.IssuedTaxInvoicePrepayment.SelectionOfAdvancesReceived();
	SelectionOfAdvances.Insert("BeginOfPeriod",		 BegOfDay(DetailsOfFillingInForm.Date));
	SelectionOfAdvances.Insert("EndOfPeriod",		 EndOfQuarter(DetailsOfFillingInForm.Date));
	SelectionOfAdvances.Insert("Organization",		 Organization);
	SelectionOfAdvances.Insert("ARAPDocument",	 DocumentBasis);
	SelectionOfAdvances.Insert("RuleOfPrepaymentFilter", Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllPayments);
	
	PrepaymentsFromCustomerLayout = Documents.IssuedTaxInvoicePrepayment.TableAdvancesReceived_();
	Documents.IssuedTaxInvoicePrepayment.FillInReceivedAdvancesForSF(SelectionOfAdvances, PrepaymentsFromCustomerLayout);
	
	RuleOfPrepaymentFilter = SelectionOfAdvances.RuleOfPrepaymentFilter;
	
	PrepaymentsFromCustomerLayout.GroupBy("VATRate,LineOfBusiness,ARAPObject", "Sum, VATAmount");
	For Each AdvanceLine_ In PrepaymentsFromCustomerLayout Do
		DocumentLine = Prepayments.Add();
		DocumentLine.InventoryType = Enums.InventoryTypes.OwnGoods;
		FillPropertyValues(DocumentLine, AdvanceLine_);
	EndDo;
	
	If GetFunctionalOption("UseSalesOrders") Then
		// We will fill in the goods invoices for orders
		Goods = Documents.IssuedTaxInvoicePrepayment.CustomerOrderProducts(DocumentBasis);
		If Goods.Count() <> 0 Then
			TableAdvances = Prepayments.Unload();
			Documents.IssuedTaxInvoicePrepayment.DistributeAdvancesOnGoods(TableAdvances, Goods, DocumentBasis);
			Prepayments.Load(TableAdvances);
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillInCorrectionOnInvoice(FillingData = Undefined) Export
	
	If FillingData <> Undefined Then
		Basis = FillingData.BaseDocumentTaxInvoice;
	Else
		Basis = BaseDocumentTaxInvoice;
		Patch = True;
	EndIf;
	
	ObjectDocumentBeingCorrected = Basis.GetObject();
	
	ArrayOfExcludedDetails = New Array;
	ArrayOfExcludedDetails.Add("Number");
	ArrayOfExcludedDetails.Add("Date");
	ArrayOfExcludedDetails.Add("Posted");
	ArrayOfExcludedDetails.Add("DeletionMark");
	ArrayOfExcludedDetails.Add("Ref");
	ArrayOfExcludedDetails.Add("EmployeeResponsible");
	ArrayOfExcludedDetails.Add("Patch");
	
	FillPropertyValues(ThisObject, ObjectDocumentBeingCorrected, , StrConcat(ArrayOfExcludedDetails, ","));
	For Each TabularSection In Metadata().TabularSections Do
		ThisObject[TabularSection.Name].Load(ObjectDocumentBeingCorrected[TabularSection.Name].Unload());
	EndDo;
	
	For Each LineAdvances In ThisObject.Prepayments Do
		LineAdvances.RowID = "";
	EndDo;
	
	If ObjectDocumentBeingCorrected.Patch Then
		BaseDocumentTaxInvoice = ObjectDocumentBeingCorrected.BaseDocumentTaxInvoice;
	Else
		BaseDocumentTaxInvoice = ObjectDocumentBeingCorrected.Ref;
	EndIf;
	
EndProcedure

Procedure FillInInvoiceReceivedInAdvance(FillingData)
	
	DocumentBasis = FillingData;
	RuleOfPrepaymentFilter = Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllPayments;
	
	FillPropertyValues(ThisObject, FillingData, "Date,Organization,VATTaxation,Department");
	
	DetailsOfFoundation = Common.ObjectAttributesValues(FillingData, "DocumentBasis, Counterparty, Prepayments");
	IncomingNumberAndDate = Documents.IssuedTaxInvoicePrepayment.IncomingDocumentNumberAndDate(DetailsOfFoundation.DocumentBasis, DetailsOfFoundation.Counterparty);
	FillPropertyValues(ThisObject, IncomingNumberAndDate);
	
	For Each TSRow In DetailsOfFoundation.Prepayments.Unload() Do
		AdvanceLine_ = Prepayments.Add();
		AdvanceLine_.InventoryType = Enums.InventoryTypes.GoodsInStorageWithRightToSell;
		AdvanceLine_.Sum = TSRow.AmountIncludingVATFee;
		AdvanceLine_.VATAmount = TSRow.AmountVATFee;
		AdvanceLine_.VATRate = TSRow.VATRate;
		AdvanceLine_.ARAPObject = TSRow.ARAPObject;
	EndDo;
	
EndProcedure

Procedure FillInOffsetOfDebt(FillingData, UpdateAbsolutely = False)
	
	UseSalesOrders = GetFunctionalOption("UseSalesOrders");
	
	PrepaymentsFromCustomerLayout = Documents.IssuedTaxInvoicePrepayment.TableAdvancesReceived_();
	
	DetailsOfFoundation = Common.ObjectAttributesValues(FillingData, "Date, Organization");
	Organization = DetailsOfFoundation.Organization;
	
	RuleOfPrepaymentFilter = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("VATAccountingSettings", 
							DetailsOfFoundation.Organization, DetailsOfFoundation.Date).RuleOfPrepaymentFilterToRegisterTaxInvoices;
	
	SelectionOfAdvances = Documents.IssuedTaxInvoicePrepayment.SelectionOfAdvancesReceived();
	SelectionOfAdvances.ARAPDocument   = FillingData;
	SelectionOfAdvances.BeginOfPeriod       = BegOfDay(DetailsOfFoundation.Date);
	SelectionOfAdvances.EndOfPeriod        = EndOfDay(DetailsOfFoundation.Date);
	SelectionOfAdvances.Organization         = Organization;
	SelectionOfAdvances.RuleOfPrepaymentFilter = RuleOfPrepaymentFilter;
	
	Documents.IssuedTaxInvoicePrepayment.FillInReceivedAdvancesForSF(SelectionOfAdvances, PrepaymentsFromCustomerLayout, Undefined);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	PrepaymentsFromCustomerLayout.Sfsformed,
	|	PrepaymentsFromCustomerLayout.Counterparty,
	|	PrepaymentsFromCustomerLayout.VATTaxation,
	|	PrepaymentsFromCustomerLayout.Sum,
	|	PrepaymentsFromCustomerLayout.VATRate,
	|	PrepaymentsFromCustomerLayout.LineOfBusiness,
	|	PrepaymentsFromCustomerLayout.VATAmount,
	|	PrepaymentsFromCustomerLayout.DocumentBasis,
	|	PrepaymentsFromCustomerLayout.ARAPObject,
	|	PrepaymentsFromCustomerLayout.DateOfDischarge,
	|	PrepaymentsFromCustomerLayout.DocumentCurrency,
	|	PrepaymentsFromCustomerLayout.CurrencyAmount,
	|	PrepaymentsFromCustomerLayout.TaxInvoiceAmount,
	|	PrepaymentsFromCustomerLayout.TaxInvoice,
	|	PrepaymentsFromCustomerLayout.EmployeeResponsible,
	|	PrepaymentsFromCustomerLayout.Department,
	|	PrepaymentsFromCustomerLayout.Director,
	|	PrepaymentsFromCustomerLayout.ChiefAccountant
	|INTO TableAdvances
	|FROM
	|	&PrepaymentsFromCustomerLayout AS PrepaymentsFromCustomerLayout
	|
	|INDEX BY
	|	PrepaymentsFromCustomerLayout.DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////3
	|
	|SELECT
	|	TableAdvances.Sfsformed,
	|	TableAdvances.Counterparty                                       AS Counterparty,
	|	TableAdvances.VATTaxation                               AS VATTaxation,
	|	ISNULL(TableAdvances.Counterparty.TIN, """")                   AS TINOfCounterparty,
	|	TableAdvances.Sum                                            AS Sum,
	|	TableAdvances.VATRate                                        AS VATRate,
	|	TableAdvances.LineOfBusiness                          AS LineOfBusiness,
	|	TableAdvances.VATAmount                                         AS VATAmount,
	|	TableAdvances.DocumentBasis                                AS DocumentBasis,
	|	TableAdvances.DateOfDischarge                                      AS DateOfDischarge,
	|	TableAdvances.DocumentCurrency                                  AS DocumentCurrency,
	|	TableAdvances.CurrencyAmount                                    AS CurrencyAmount,
	|	TableAdvances.TaxInvoiceAmount                                AS TaxInvoiceAmount,
	|	TableAdvances.TaxInvoice                                      AS TaxInvoice,
	|	TableAdvances.EmployeeResponsible                                    AS EmployeeResponsible,
	|	TableAdvances.Department                                    AS Department,
	|	TableAdvances.Director                                     AS Director,
	|	TableAdvances.ChiefAccountant                                 AS ChiefAccountant,
	|	TableAdvances.ARAPObject                                   AS ARAPObject,
	|	CASE 
	|		WHEN TableAdvances.VATRate = VALUE(Catalog.VATRates.EmptyRef)
	|		THEN TRUE
	|		ELSE FALSE
	|	END                                                          AS VATRateIsEmpty,
	|	CASE
	|		WHEN VALUETYPE(TableAdvances.DocumentBasis) = TYPE(Document.OBEntryARAP)
	|			THEN ISNULL(OBEntryARAP.NumberOfARAPDocument, SourceDocumentsData.Number) 
	|		ELSE ISNULL(OBEntry.NumberOfARAPDocument, SourceDocumentsData.Number)
	|	END AS SettlementDocumentNumber,
	|	CASE
	|		WHEN VALUETYPE(TableAdvances.DocumentBasis) = TYPE(Document.OBEntryARAP)
	|			THEN ISNULL(OBEntryARAP.APARDocumentDate, SourceDocumentsData.Date)
	|		ELSE ISNULL(OBEntry.APARDocumentDate, SourceDocumentsData.Date)
	|	END AS DateOfDocumentInARAPAccounting
	|FROM
	|	TableAdvances AS TableAdvances
	|	
	|	LEFT JOIN
	|		Document.OBEntry.PartnersARAPAccounting AS OBEntry
	|	ON
	|		TableAdvances.DocumentBasis = OBEntry.Ref
	|		AND TableAdvances.Counterparty = OBEntry.Counterparty
	|
	|	LEFT JOIN
	|		Document.OBEntryARAP.PartnersARAPAccounting AS OBEntryARAP
	|	ON
	|		TableAdvances.DocumentBasis = OBEntryARAP.Ref
	|		AND TableAdvances.Counterparty = OBEntryARAP.Counterparty
	|	
	|	LEFT JOIN
	|		InformationRegister.SourceDocumentsData AS SourceDocumentsData
	|	ON
	|		SourceDocumentsData.Organization = &Organization
	|		AND TableAdvances.DocumentBasis = SourceDocumentsData.Document
	|
	|ORDER BY
	|	TableAdvances.DateOfDischarge,
	|	TableAdvances.Counterparty,
	|	TableAdvances.DocumentBasis
	|
	|TOTALS
	|	SUM(Sum),
	|	SUM(TaxInvoiceAmount),
	|	MAX(VATRateIsEmpty),
	|	MAX(TaxInvoice),
	|	MAX(EmployeeResponsible),
	|	MAX(Department),
	|	MAX(Director),
	|	MAX(ChiefAccountant),
	|	MAX(DateOfDischarge),
	|	MAX(SettlementDocumentNumber),
	|	MAX(DateOfDocumentInARAPAccounting)
	|BY
	|	DocumentBasis,
	|	VATTaxation,
	|	Counterparty
	|";
	
	Query.SetParameter("PrepaymentsFromCustomerLayout", PrepaymentsFromCustomerLayout);
	Query.SetParameter("Organization",       Organization);
	
	SampleDocumentBase = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SampleDocumentBase.Next() Do
		SamplingVATTaxation = SampleDocumentBase.Select(QueryResultIteration.ByGroups);
		While SamplingVATTaxation.Next() Do
			CounterpartySelection = SamplingVATTaxation.Select(QueryResultIteration.ByGroups);
			While CounterpartySelection.Next() Do
				
				InvoiceAmountUpdateRequired = CounterpartySelection.Sum <> CounterpartySelection.TaxInvoiceAmount Or UpdateAbsolutely;
				If CounterpartySelection.VATRateIsEmpty And InvoiceAmountUpdateRequired Then
					Filter = New Structure();
					Filter.Insert("DocumentBasis",  CounterpartySelection.DocumentBasis);
					Filter.Insert("VATTaxation", CounterpartySelection.VATTaxation);
					Filter.Insert("Counterparty",         CounterpartySelection.Counterparty);
					Filter.Insert("VATRate",          Catalogs.VATRates.EmptyRef());
					RowsVATRateIsEmpty = PrepaymentsFromCustomerLayout.FindRows(Filter);
					For Each String In RowsVATRateIsEmpty Do
						MessageText = StrTemplate(NStr("vi = 'Để điền hóa đơn GTGT theo ""%1"" cần chỉ ra Thuế suất GTGT';
														|ru = 'Для заполнения счета-фактуры по ""%1"" требуется указать Ставку НДС';
														|en = 'Specify VAT Rate to fill in tax invoice using ""%1""'; fa = 'Specify VAT Rate to fill in tax invoice using ""%1""';
														|it = 'Per compilare la fattura secondo ""%1"" bisogna indicare l''aliquota IVA';
														|pl = 'Aby wypełnić faktury wg ""%1"" należy podać Stawkę VAT';
														|tr = '""%1"" faturasını tamamlamak için KDV oranı gereklidir'"), String.DocumentBasis);
						DataPath = StrTemplate("PrepaymentsFromCustomerLayout[%1].VATRate", String.GetID());
						Common.MessageToUser(MessageText, , DataPath);
					EndDo;
					Continue;
				EndIf;
				
				TaxInvoiceDate = EndOfDay(SampleDocumentBase.DateOfDischarge);
				
				FillPropertyValues(ThisObject, CounterpartySelection);
				
				Date = TaxInvoiceDate;
				IssueDate = TaxInvoiceDate;
				
				If TypeOf(CounterpartySelection.DocumentBasis) = Type("DocumentRef.ARAPSettlement")
					And CounterpartySelection.DocumentBasis.OperationKind = Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent
					And ValueIsFilled(CounterpartySelection.DocumentBasis.AccountsPayable[0].ARAPObject) Then
						CommissionAgreement = CounterpartySelection.DocumentBasis.AccountsPayable[0].ARAPObject.Contract;
				EndIf;
				
				Fill(Undefined); // Called so that the refilling of the object has worked
				
				Selection = CounterpartySelection.Select();
				InvoiceParameters = New Map;
				
				If InvoiceAmountUpdateRequired Then
					Prepayments.Clear();
					While Selection.Next() Do
						NewAdvanceLine = Prepayments.Add();
						NewAdvanceLine.InventoryType              = Enums.InventoryTypes.OwnGoods;
						NewAdvanceLine.Sum                   = Selection.Sum;
						NewAdvanceLine.VATRate               = Selection.VATRate;
						NewAdvanceLine.VATAmount                = Selection.VATAmount;
						NewAdvanceLine.LineOfBusiness = Selection.LineOfBusiness;
						NewAdvanceLine.ARAPObject          = Selection.ARAPObject;
						
						InvoiceParameters.Insert(NewAdvanceLine.VATRate, Selection.Sum);
					EndDo; 
				EndIf;
				
				Selection.Reset();
				If Selection.Next() Then
					TINOfCounterparty = Selection.TINOfCounterparty;
				EndIf;
				
				If UseSalesOrders Then
					// We will fill in the goods invoices for orders
					Goods = Documents.IssuedTaxInvoicePrepayment.CustomerOrderProducts(
								DocumentBasis,
								VATTaxation);
					If Goods.Count() <> 0 Then
						TableAdvances = Prepayments.Unload();
						Documents.IssuedTaxInvoicePrepayment.DistributeAdvancesOnGoods(TableAdvances, Goods, DocumentBasis);
						Prepayments.Load(TableAdvances);
					EndIf;
				EndIf;
			
				// We will add the remaining details of the document
				Fill(Undefined);
				
				// We will fill in the individual details, as indicated in the workplace.
				FillPropertyValues(ThisObject, CounterpartySelection, "EmployeeResponsible,Department,Director,ChiefAccountant");
	
			EndDo;
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

Procedure CheckDuplicateInvoices(Cancel)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	DocumentData.Ref AS Ref,
	|	DocumentData.DocumentBasis AS DocumentBasis
	|FROM
	|	Document.IssuedTaxInvoicePrepayment AS DocumentData
	|WHERE
	|	DocumentData.Ref <> &Ref
	|	AND DocumentData.DocumentBasis = &DocumentBasis
	|	AND DocumentData.VATTaxation = &VATTaxation
	|	AND DocumentData.Posted
	|	AND NOT DocumentData.Patch
	|	AND DocumentData.Counterparty = &Counterparty
	|	AND NOT TRUE IN 
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		WHERE
	|			DocumentsRegistry.RefType = &RefType
	|			AND DocumentsRegistry.ReversedDocument = DocumentData.Ref
	|			AND DocumentsRegistry.Posted)
	|";
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Query.SetParameter("VATTaxation", VATTaxation);
	Query.SetParameter("RefType", Common.MetadataObjectID(Metadata()));
	
	Result = Query.Execute();
	Selection = Result.Select();
	If Selection.Next() Then
		
		If Not Patch Then
		
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đối với chứng từ %1 đã nhập hóa đơn GTGT %2';
					|ru = 'Для документа %1 уже введен счет-фактура %2';
					|en = 'Tax invoice %2 is already entered for document %1'; fa = 'Tax invoice %2 is already entered for document %1';
					|it = 'È stata già inserita la fattura %2 per il documento%1';
					|pl = 'Dla dokumentu %1 juz wprowadzono fakturę %2';
					|tr = '%1 belgesi için %2 faturası zaten oluşturuldu'"),
				DocumentBasis,
				Selection.Ref);
			Common.MessageToUser(
				Text,
				ThisObject,
				"DocumentBasis",
				,
				Cancel);
			
		ElsIf Patch And BaseDocumentTaxInvoice <> Selection.Ref Then
			
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trên cơ sở chứng từ %1 đã nhập hóa đơn GTGT %2. Không thể chỉnh sửa hóa đơn GTGT %3.';
					|ru = 'На основании документа %1 введен счет-фактура %2. Недопустимо исправление счета-фактуры %3.';
					|en = 'Tax invoice %2 is entered based on document %1. Cannot correct tax invoice %3.'; fa = 'Tax invoice %2 is entered based on document %1. Cannot correct tax invoice %3.';
					|it = 'È stata inserita la fattura %2 corrispondente al documento%1. Fattura non valida%3.';
					|pl = 'Na podstawie dokumentu %1 wprowadzono fakturę.%2Korekta faktury %3 jest zabronione.';
					|tr = 'Fatura %2, belge %1 temel alınarak girilmiştir. Fatura %3 düzeltilemez.'"),
				Selection.DocumentBasis,
				Selection.Ref,
				BaseDocumentTaxInvoice);
				
			Common.MessageToUser(
				Text,
				ThisObject,
				,
				,
				Cancel);
				
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure GenerateStringOfSettlementAndPaymentDocuments()
	
	If Not ValueIsFilled(DocumentBasis) Then
		RowARAPDocuments = "";
		Return;
	EndIf;
	
	RowARAPDocuments = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '%1 ngày %2';
			|ru = '%1 от %2';
			|en = '%1 from %2'; fa = '%1 from %2';
			|it = '%1 del %2';
			|pl = '%1 z dn. %2';
			|tr = '%2 tarihli %1'"),
		SettlementDocumentNumber,
		Format(DateOfDocumentInARAPAccounting, "DLF=D"));

	For Each TableRow In ConsignorSPrincipalSARAPDocuments Do
		RowARAPDocuments = RowARAPDocuments
			+ ?(IsBlankString(RowARAPDocuments), "", ", ")
			+ StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 ngày %2';
					|ru = '%1 от %2';
					|en = '%1 from %2'; fa = '%1 from %2';
					|it = '%1 del %2';
					|pl = '%1 z dn. %2';
					|tr = '%2 tarihli %1'"),
				TableRow.SettlementDocumentNumber,
				Format(TableRow.DateOfDocumentInARAPAccounting, "DLF=D"));
	EndDo;
		
EndProcedure

Procedure FillInDateOfReceiptOfAdvance()
	
	If Patch Then
		PrepaymentReceiptDate = Date;
		Return;
	EndIf;
	
	Query = New Query();
	Query.SetParameter("DocumentBasis", DocumentBasis);
	If ValueIsFilled(DocumentBasis) Then
		Query.SetParameter("Organization", Common.ObjectAttributeValue(DocumentBasis, "Organization"));
	Else
		Query.SetParameter("Organization", Organization);
	EndIf;
	
	Query.Text =
	"SELECT
	|	ISNULL(DocumentsRegistry.RecordingInAccountingDate, SourceDocumentsData.RecorderDate) AS PrepaymentReceiptDate
	|FROM
	|	InformationRegister.SourceDocumentsData AS SourceDocumentsData
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON DocumentsRegistry.Ref = &DocumentBasis
	|			AND DocumentsRegistry.Organization = &Organization
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	SourceDocumentsData.Organization = &Organization
	|	AND SourceDocumentsData.Document = &DocumentBasis
	|	AND NOT (VALUETYPE(SourceDocumentsData.Document) = TYPE(Document.ARAPSettlement)
	|		AND CAST(SourceDocumentsData.Document AS Document.ARAPSettlement).OperationKind IN
	|			(VALUE(Enum.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent),
	|			VALUE(Enum.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent)))
	|
	|UNION ALL
	|
	|SELECT
	|	SourceDocumentsData.Date AS PrepaymentReceiptDate
	|FROM
	|	InformationRegister.SourceDocumentsData AS SourceDocumentsData
	|WHERE
	|	SourceDocumentsData.Organization = &Organization
	|	AND SourceDocumentsData.Document = &DocumentBasis
	|	AND (VALUETYPE(SourceDocumentsData.Document) = TYPE(Document.ARAPSettlement)
	|		AND CAST(SourceDocumentsData.Document AS Document.ARAPSettlement).OperationKind IN
	|			(VALUE(Enum.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent),
	|			VALUE(Enum.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent)))";
	
	Selection = Query.Execute().Select();
	If Selection.Next()
		And RuleOfPrepaymentFilter <> Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.NotSetOffBeforeQuarterEnd
		And ValueIsFilled(Selection.PrepaymentReceiptDate) Then
			PrepaymentReceiptDate = Selection.PrepaymentReceiptDate;
	Else
		PrepaymentReceiptDate = Date;
	EndIf;
	
EndProcedure

Function BusinessTransactionsVATAdvance()
	
	Operations = New Array;
	Operations.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
	Operations.Add(Enums.BusinessTransactions.CashRecieptFromCustomerByAcquiringTransactions);
	Operations.Add(Enums.BusinessTransactions.CashReceiptFromOtherCompany);
	
	Return Operations;
	
EndFunction


#EndRegion

#EndRegion

#EndIf
