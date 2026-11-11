
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData, StandardProcessing);
	ElsIf FillInDataType = Type("CatalogRef.LeaseContract") Then
		FillInBasedOnLeaseAgreement(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.FixedAssetsPhysicalCount") Then
		FillInBasedOnInventory(FillingData);
	EndIf;
	
	LeaseTerminationLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);
	
	InitializeDocument();
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentBasis = Undefined;
	Comment = "";
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "FA");
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
	LeasedAssetAccounting.CheckReturnFromSublease(ThisObject, Cancel);
	
	ItemsAndDimensionsSelectionParameters = Documents.LeaseTermination.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	FillInBankingDetailsBeforeWrite(WriteMode);
	
	ItemsAndDimensionsSelectionParameters = Documents.LeaseTermination.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	If AdditionalProperties.WriteMode = DocumentWriteMode.UndoPosting Then
		InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForFinancialInstruments(
			CommonClientServer.ValueInArray(Contract));
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.ClearDocumentRegisteredRecords(ThisObject, "GoodsForRegistrationOfImportDocuments");
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForFinancialInstruments(
		CommonClientServer.ValueInArray(Contract));
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);

EndProcedure

#EndRegion

#Region Private

#Region FillType

Procedure InitializeDocument()
	
	If Not ValueIsFilled(BusinessOperation) Then
		BusinessOperation = Enums.BusinessTransactions.LeaseTermination;
	EndIf;
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	ItemsAndDimensionsSelectionParameters = Documents.LeaseTermination.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);

EndProcedure

Procedure FillInSelectionDocument(FillingData, StandardProcessing)
	
	If FillingData.Property("Contract") Then
		FillInBasedOnLeaseAgreement(FillingData.Contract);
	ElsIf FillingData.Property("DocumentBasis")
		And TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.FixedAssetsPhysicalCount") Then
		FillInBasedOnInventory(FillingData);
	EndIf; 
	
EndProcedure

Procedure FillInBasedOnLeaseAgreement(FillingData)
	
	If Not ValueIsFilled(FillingData) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	LeaseContract.Organization,
	|	LeaseContract.Partner,
	|	LeaseContract.Counterparty,
	|	LeaseContract.DeletionMark,
	|	ISNULL(TermsOfLeaseContracts.State, UNDEFINED) AS State
	|FROM
	|	Catalog.LeaseContract AS LeaseContract
	|		LEFT JOIN InformationRegister.TermsOfLeaseContracts.SliceLast(&Date, Contract = &Contract) AS TermsOfLeaseContracts
	|		ON TermsOfLeaseContracts.Contract = &Contract
	|WHERE
	|	LeaseContract.Ref = &Contract";
	
	Query = New Query(QueryText);
	Query.SetParameter("Contract", FillingData);
	Query.SetParameter("Date", CurrentSessionDate());
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	If Selection.DeletionMark Then
		ErrorText = NStr("vi = 'Không thể tạo chứng từ, bởi vì hợp đồng đã bị đặt dấu xóa';
						|ru = 'Создание документа недоступно, т.к. договор помечен на удаление';
						|en = 'Document creation is not available because the contract is marked for deletion'; fa = 'Document creation is not available because the contract is marked for deletion';
						|it = 'Creazione del documento non disponibile, poiché l''accordo è contrassegnato per la cancellazione';
						|pl = 'Utworzenie dokumentu jest niedostępne, ponieważ umowa jest zaznaczony do usunięcia';
						|tr = 'Sözleşme silinmek üzere işaretlendiği için belge oluşturulamıyor'");
		Raise ErrorText
	ElsIf Selection.State <> Enums.CounterpartyContractStates.Valid Then
		ErrorText = NStr("vi = 'Không thể tạo chứng từ, bởi vì chưa ký kết hợp đồng';
						|ru = 'Создание документа недоступно, т.к. не оформлено заключение договора';
						|en = 'Document creation is not available because the contract signing has not been registered'; fa = 'Document creation is not available because the contract signing has not been registered';
						|it = 'Creazione del documento non disponibile, poiché non è stata registrata la conclusione del contratto';
						|pl = 'Utworzenie dokumentu jest niedostępne, ponieważ nie utworzono zawarcia umowy';
						|tr = 'Belgenin oluşturulması mevcut değildir, çünkü sözleşmenin imzalanması resmileştirilmemiştir'");
		Raise ErrorText
	EndIf;
	
	Organization = Selection.Organization;
	Partner = Selection.Partner;
	Counterparty = Selection.Counterparty;
	Contract = FillingData;
	
	Documents.LeaseTermination.FillInBasedOnLeaseAgreement(ThisObject);
	
EndProcedure

Procedure FillInBasedOnInventory(FillingData)
	
	ArrayOfLineNumbers = Undefined;
	ReportErrors = True;
	
	If TypeOf(FillingData) = Type("Structure") Then
		DocumentBasis = FillingData.DocumentBasis;
		ArrayOfLineNumbers = FillingData.ArrayOfLineNumbers;
		ReportErrors = FillingData.ReportErrors;
	Else
		DocumentBasis = FillingData;
	EndIf;
	
	Documents.LeaseTermination.FillInBasedOnInventory(ThisObject, ReportErrors, ArrayOfLineNumbers);
	
EndProcedure

#EndRegion

#Region Other

Procedure FillInBankingDetailsBeforeWrite(WriteMode)

	TMCommonUse.FillInDocumentIDs(ThisObject, "FA");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf