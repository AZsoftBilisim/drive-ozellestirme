#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the code of the invoice operation type
//
Procedure FillInOperationTypeCode() Export
	
	ReceivedTaxInvoicePrepaymentLocalization.FillInOperationTypeCode(ThisObject);
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	BasisType = TypeOf(FillingData);
	
	If BasisType = Type("DocumentRef.BankAccountIssue") 
		Or BasisType = Type("DocumentRef.CashVoucher") Then
		
		If BasisType = Type("DocumentRef.BankAccountIssue") Then
			AttributesValues = DetailsWriteOffOfNonCashFunds(FillingData);
		Else
			AttributesValues = AccountDetailsCashOrder(FillingData);
		EndIf;
		
		If AttributesValues.BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Đối với chứng từ có giao dịch ""%1"" không nên nhập điều chỉnh.';
							|ru = 'Для документа с операцией ""%1"" не требуется вводить корректировку.';
							|en = 'It is not required to enter adjustment for a document with transaction ""%1"".'; fa = 'It is not required to enter adjustment for a document with transaction ""%1"".';
							|it = 'Non è richiesta correzione per il documento con operazione ""%1"".';
							|pl = 'Dla dokumentu z operacja ""%1"" nie trzeba wprowdzać korekty.';
							|tr = '""%1"" işlemine sahip bir belge için düzeltme girilmesine gerek yoktur.'"),
						AttributesValues.BusinessOperation);
			Raise Text;
		EndIf;
		
		DocumentBasis    = FillingData;
		Organization          = AttributesValues.Organization;
		Counterparty           = IncomeAndExpensesServer.GetCounterpartyFromBase(DocumentBasis);
		Department        = AttributesValues.Department;
		VATTaxation   = AttributesValues.VATTaxation;
		If VATTaxation = Enums.VATTaxationTypes.SubjectToVATAtCustomer Then
			TransactionKindCode = "41";
		EndIf;
		
		FillInDependentDetailsOfCounterparty();
		FillInAdvances();
		
	ElsIf BasisType = Type("DocumentRef.ExpenseReport") Then
		
		DocumentBasis = FillingData;
		Organization       = FillingData.Organization;
		Department     = FillingData.Department;
		FillInAdvances();
		
	ElsIf BasisType = Type("Structure") Then
		
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
			
		Else
			FillPropertyValues(ThisObject, FillingData);
			FillInDependentDetailsOfCounterparty();
			FillInAdvances();
		EndIf;
		
	EndIf; 
	
	ReceivedTaxInvoicePrepaymentLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	ReceivedTaxInvoicePrepaymentLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	ReceivedTaxInvoicePrepaymentLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If TypeOf(DocumentBasis) <> Type("DocumentRef.OBEntry")
		And TypeOf(DocumentBasis) <> Type("DocumentRef.OBEntryARAP")
		And TypeOf(DocumentBasis) <> Type("DocumentRef.ExpenseReport") 
		And TypeOf(DocumentBasis) <> Type("DocumentRef.ARAPSettlement") Then
		
		NotCheckedAttributeArray.Add("Counterparty");
	EndIf; 
	
	If Not Patch Then
		NotCheckedAttributeArray.Add("CorrectionNumber");
		NotCheckedAttributeArray.Add("CorrectionDate");
		NotCheckedAttributeArray.Add("BaseDocumentTaxInvoice");
	EndIf;
	
	If Patch Then
		NotCheckedAttributeArray.Add("Number");
		NotCheckedAttributeArray.Add("DateCreated");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	ReceivedTaxInvoicePrepaymentLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
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
	
	If Patch And ValueIsFilled(BaseDocumentTaxInvoice) Then
		
		Attributes = Common.ObjectAttributesValues(BaseDocumentTaxInvoice, "Number, DateCreated");
		Number           = Attributes.Number;
		DateCreated = Attributes.DateCreated;
		
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Prepayments");
	
	RecordingInAccountingDate = Date;
	
	ReceivedTaxInvoicePrepaymentLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
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
	
	ReceivedTaxInvoicePrepaymentLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	VATRate = VATAccountingERP.DefaultVATRate(Organization, Date, True);
	For Each String In Prepayments Do
		String.VATRate= VATRate;
	EndDo;
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.TreatTS(Prepayments, StructureOfActions, Undefined);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Prepayments");
	
	ReceivedTaxInvoicePrepaymentLocalization.OnCopy(ThisObject, CopiedObject);
	
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

#EndRegion

#Region Other

// The procedure checks whether the invoice is duplicated.
//
// Parameters:
//	Cancel - Boolean - indicates that the document was not recorded.
//
Procedure CheckDuplicateInvoices(Cancel)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	DocumentData.Ref AS Ref,
	|	DocumentData.DocumentBasis AS DocumentBasis
	|FROM
	|	Document.ReceivedTaxInvoicePrepayment AS DocumentData
	|WHERE
	|	DocumentData.Ref <> &Ref
	|	AND DocumentData.DocumentBasis = &DocumentBasis
	|	AND DocumentData.Posted
	|	AND NOT DocumentData.Patch
	|	AND DocumentData.VATTaxation = &VATTaxation
	|	AND DocumentData.Counterparty = &Counterparty
	|	AND NOT TRUE IN 
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		WHERE
	|			DocumentsRegistry.RefType = &RefType
	|			AND DocumentsRegistry.ReversedDocument = DocumentData.Ref
	|			AND DocumentsRegistry.Posted)";
	
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
				NStr("vi = 'Đối với chứng từ %1 đã ghi nhận hóa đơn GTGT %2';
					|ru = 'Для документа %1 уже зарегистрирован счет-фактура %2';
					|en = 'Tax invoice %2 is already registered for document %1'; fa = 'Tax invoice %2 is already registered for document %1';
					|it = 'È già stata registrata la fattura %2 per il documento%1';
					|pl = 'Dla dokumentu %1 juz zarejestrowano fakturę %2';
					|tr = '%2 numaralı vergi faturası %1 numaralı belge için artık kaydedildi'"),
				DocumentBasis,
				Selection.Ref);
			CommonClientServer.MessageToUser(
				Text,
				ThisObject,
				"DocumentBasis",
				,
				Cancel);
			
		ElsIf Patch And BaseDocumentTaxInvoice <> Selection.Ref Then
			
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trên cơ sở chứng từ %1 đã ghi nhận hóa đơn GTGT %2. Không thể chỉnh sửa hóa đơn GTGT %3.';
					|ru = 'На основании документа %1 зарегистрирован счет-фактура %2. Недопустимо исправление счета-фактуры %3.';
					|en = 'Tax invoice %2 is registered based on document %1. Cannot correct tax invoice %3.'; fa = 'Tax invoice %2 is registered based on document %1. Cannot correct tax invoice %3.';
					|it = 'È stata registrata la fattura %2 corrispondente al documento%1 . Fattura non valida%3';
					|pl = 'Na podstawie dokumentu %1 zarejestrowano fakturę %2. Korekta faktury %3 jest zabroniona.';
					|tr = '%2 numaralı fatura %1 numaralı belgeye dayanılarak kaydedildi. Vergi faturasının düzeltmesi erişilebilir değil %3.'"),
				Selection.DocumentBasis,
				Selection.Ref,
				BaseDocumentTaxInvoice);
				
			CommonClientServer.MessageToUser(
				Text,
				ThisObject,
				,
				,
				Cancel);
				
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInAdvances()
	
	If Not ValueIsFilled(Organization) Then
		Return;
	EndIf;
	
	BeginOfPeriod = Date('00010101');
	EndOfPeriod = CurrentSessionDate();
	
	AdditionalParameters = Documents.ReceivedTaxInvoicePrepayment.AdditionalParametersOfAdvancesIssued();
	AdditionalParameters.ARAPDocument = DocumentBasis;
	AdditionalParameters.ByVATRates = True;
	AdditionalParameters.InContextOfOR = True;
	
	PrepaymentsToVendor_ = Documents.ReceivedTaxInvoicePrepayment.ReceiveAdvancesIssued(
		Organization,
		BeginOfPeriod,
		EndOfPeriod,
		AdditionalParameters);
	
	For Each String In PrepaymentsToVendor_ Do
		
		If String.Vendor <> Counterparty Then
			Continue;
		EndIf;
		
		NewRow = Prepayments.Add();
		
		FillPropertyValues(NewRow, String);
		
		NewRow.Sum = String.AmountOfSchedAdvance;
		
	EndDo;
	
EndProcedure

Procedure FillInDependentDetailsOfCounterparty()

	If ValueIsFilled(Counterparty)
		And TypeOf(Counterparty) = Type("CatalogRef.Counterparties") Then
		
		CounterpartyDetails_ = PartnersAndCounterparties.CounterpartyDetails_(Counterparty, Date);
		TINOfCounterparty       = CounterpartyDetails_.TIN;

	EndIf;
	
EndProcedure

Function AccountDetailsCashOrder(PaymentDocumentLink_)
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	CASE
	|		WHEN ISNULL(TSARAPDetails.ARAPObject.Organization,
	|			VALUE(Catalog.Companies.EmptyRef)) = VALUE(Catalog.Companies.EmptyRef)
	|			THEN DocumentData.Organization
	|		ELSE TSARAPDetails.ARAPObject.Organization
	|	END AS Organization,
	|	CASE
	|		WHEN ISNULL(TSARAPDetails.ARAPObject.Organization,
	|			VALUE(Catalog.Companies.EmptyRef)) = VALUE(Catalog.Companies.EmptyRef)
	|			THEN DocumentData.Department
	|		ELSE TSARAPDetails.ARAPObject.Department
	|	END AS Department,
	|	DocumentData.VATTaxation AS VATTaxation,
	|	TSARAPDetails.ARAPObject AS ARAPObject
	|FROM
	|	Document.CashVoucher AS DocumentData
	|		INNER JOIN Document.CashVoucher.ARAPDetails AS TSARAPDetails
	|		ON DocumentData.Ref = TSARAPDetails.Ref
	|WHERE
	|	DocumentData.Ref = &Ref";
	Query.SetParameter("Ref", PaymentDocumentLink_);
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection;
	
EndFunction

Function DetailsWriteOffOfNonCashFunds(PaymentDocumentLink_)
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	CASE
	|		WHEN ISNULL(TSARAPDetails.ARAPObject.Organization,
	|			VALUE(Catalog.Companies.EmptyRef)) = VALUE(Catalog.Companies.EmptyRef)
	|			THEN DocumentData.Organization
	|		ELSE TSARAPDetails.ARAPObject.Organization
	|	END AS Organization,
	|	CASE
	|		WHEN ISNULL(TSARAPDetails.ARAPObject.Organization,
	|			VALUE(Catalog.Companies.EmptyRef)) = VALUE(Catalog.Companies.EmptyRef)
	|			THEN DocumentData.Department
	|		ELSE TSARAPDetails.ARAPObject.Department
	|	END AS Department,
	|	DocumentData.VATTaxation AS VATTaxation,
	|	TSARAPDetails.ARAPObject AS ARAPObject
	|FROM
	|	Document.BankAccountIssue AS DocumentData
	|		INNER JOIN Document.BankAccountIssue.ARAPDetails AS TSARAPDetails
	|		ON DocumentData.Ref = TSARAPDetails.Ref
	|WHERE
	|	DocumentData.Ref = &Ref";
	Query.SetParameter("Ref", PaymentDocumentLink_);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
