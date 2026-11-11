#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocument();
	
	ExchangeDifferenceCalculationLocalization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("CarryingOutCalculationOfExchangeDifferences");
	AdditionalProperties.Insert("MeasurementDetails", MeasurementDetails);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If WriteMode <> DocumentWriteMode.UndoPosting And Not DeletionMark Then
		CheckDuplicateCurPeriodDocuments(Cancel);
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject);
	
	ExchangeDifferenceCalculationLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	If Not AdditionalProperties.Property("CalculationIsExecuted") Then
		
		AccessManagement.DisableAccessKeysUpdate(True);
		BeginTransaction();
		Try
			ClearMotionRecordSets(ThisObject);
			NewSettlementArchitecture = GetFunctionalOption("NewOnlineARAPAccounting");
			TheseAreCalculations = BusinessOperation = Enums.BusinessTransactions.RevaluationOfCustomersARAP
				Or BusinessOperation = Enums.BusinessTransactions.RevaluationOfVendorsARAPAccounting;
			If TheseAreCalculations And NewSettlementArchitecture Then
				Documents.ExchangeDifferenceCalculation.CalculateExchangeDifferencesByTerms(Organization, Date, BusinessOperation, RevaluationByDays);
			Else
				Documents.ExchangeDifferenceCalculation.Calculate_ExchangeDifferences(ThisObject.Ref);
			EndIf;
			AccessManagement.DisableAccessKeysUpdate(False);
			CommitTransaction();
		Except
			RollbackTransaction();
			AccessManagement.DisableAccessKeysUpdate(False, False);
			ErrorText = DetailErrorDescription(ErrorInfo());
			Raise ErrorText;
		EndTry;
	EndIf;
	
	If Constants.MigrationToOnlineARAPAccountingHasStarted.Get() Then
		AdditionalProperties.Insert("SkipPeriodClosingCheck", True);
		For Each Set In RegisterRecords Do
			Set.AdditionalProperties.Insert("SkipPeriodClosingCheck", True);
		EndDo;
	EndIf;
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	ExchangeDifferenceCalculationLocalization.Posting(ThisObject, Cancel, PostingMode);
	
	MeasurementDetails = Undefined;
	If AdditionalProperties.Property("MeasurementDetails", MeasurementDetails) Then
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);
	EndIf;
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	TheseAreCalculations = ThisObject.BusinessOperation = Enums.BusinessTransactions.RevaluationOfVendorsARAPAccounting
		Or ThisObject.BusinessOperation = Enums.BusinessTransactions.RevaluationOfCustomersARAP;
	If TheseAreCalculations And GetFunctionalOption("NewOnlineARAPAccounting") And ThereAreRegisteredRecordsOnTerms() Then
		
		ErrorText = NStr("vi = 'Để hủy kết chuyển ""%1"" cần
		|hủy kết chuyển tất cả chứng từ hình thành số dư nguyên tệ
		|theo doanh nghiệp ""%2""';
		|ru = 'Для отмены проведения ""%1"" необходимо
		|снять с проведения все документы формирующие валютные остатки
		|по организации ""%2""';
		|en = 'To cancel posting ""%1"" you need to
		|clear from posting all documents generating currency balances
		|by company ""%2""'; fa = 'To cancel posting ""%1"" you need to
		|clear from posting all documents generating currency balances
		|by company ""%2""';
		|it = 'Per annullare la registrazione di ""%1"" è necessario 
		| rimuovere la registrazione di tutti i documenti che formano i saldi in valuta 
		| per l''azienda ""%2""';
		|pl = 'Dla anulowania zaksięgowanie ""%1"" należy
		|zdjąć z zaksięgowania wszystkie dokumenty formujące salda walutowe
		|dla firmy ""%2""';
		|tr = '""%1"" kaydını 
		|iptal etmek için ""%2"" iş yeri 
		|için para birimi bakiyelerini oluşturan tüm belgeleri iptal etmek gerekir'");
		ErrorText = StrTemplate(ErrorText, Ref, Organization);
		Raise ErrorText;
		
	EndIf;
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	ExchangeDifferenceCalculationLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	TMCommonUse.ClearDocumentIDs(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument()
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
EndProcedure

Procedure CheckDuplicateCurPeriodDocuments(Cancel)
	
	If AdditionalProperties.Property("DisableDoubleChecking") Then
		Return;
	EndIf;
	
	Query = New Query(
	"SELECT TOP 1
	|	T.Ref
	|FROM
	|	Document.ExchangeDifferenceCalculation AS T
	|WHERE
	|	T.Posted
	|	AND T.Organization = &Organization
	|	AND T.Date BETWEEN &PeriodBeginning AND &PeriodEnd
	|	AND NOT T.Ref = &CurrentDocument
	|	AND T.BusinessOperation = &Operation");
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("CurrentDocument", Ref);
	Query.SetParameter("PeriodBeginning", BegOfMonth(Date));
	Query.SetParameter("PeriodEnd", EndOfMonth(Date));
	Query.SetParameter("Operation", BusinessOperation);
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		ErrorText = NStr("vi = 'Đối với doanh nghiệp ""%1"" trong tháng hiện tại %2 đã có chứng từ tương tự ""%3"".
							|Hãy đặt dấu xóa tất cả chứng từ tính chênh lệch tỷ giá mà chưa kết chuyển.';
							|ru = 'Для организации ""%1"" в текущем месяце %2 уже существует аналогичный документ ""%3"".
							|Пометьте на удаление все непроведенные документы расчета курсовых разниц.';
							|en = 'Similar document %3 already exists for company %1 in the current month %2. 
							|Mark for deletion all unposted documents of exchange difference calculation.'; fa = 'Similar document %3 already exists for company %1 in the current month %2. 
							|Mark for deletion all unposted documents of exchange difference calculation.';
							|it = 'Per la società ""%1"" nel mese corrente %2 esiste già un documento analogo ""%3"". 
							| Contrassegnate per l''eliminazione tutti i documenti non registrati di calcolo di differenze di cambio.';
							|pl = 'Dla firmy ""%1"" w bieżącym miesiącu %2 istnieje już podobny dokument ""%3"". 
							|Zaznacz usunięcie wszystkich niezatwierdzonych dokumentów obliczania różnicy walut.';
							|tr = 'İçinde bulunulan %2 ayında ""%1"" iş yeri için benzer bir belge ""%3"" zaten mevcuttur.
							|Kaydedilmemiş tüm kur farkı hesaplama belgelerini silmek için seç.'");
		ErrorText = StrTemplate(ErrorText, Organization, Format(Date, "DF=MM.yyyy"), BusinessOperation);
		Raise ErrorText;
	EndIf;
	
EndProcedure

Procedure ClearMotionRecordSets(Var_ThisObject)
	
	SetsOfRegisteredRecords = New Array;
	SetsOfRegisteredRecords.Add("VendorsARAPAccountingByDocuments");
	SetsOfRegisteredRecords.Add("CustomersARAPAccountingByDocuments");
	SetsOfRegisteredRecords.Add("BankAccountCash");
	SetsOfRegisteredRecords.Add("CashAccountBalance");
	SetsOfRegisteredRecords.Add("CashInCashRegistersCR");
	SetsOfRegisteredRecords.Add("CashInTransit");
	SetsOfRegisteredRecords.Add("AdvanceHolderCash");
	SetsOfRegisteredRecords.Add("FinancialInstrumentsARAP");
	SetsOfRegisteredRecords.Add("DiscountInterestExpense");
	SetsOfRegisteredRecords.Add("GoodsToBeRegisteredInReportsToConsignor");
	SetsOfRegisteredRecords.Add("GoodsAndServicesToRegisterPurchasingReportsToConsignor");
	SetsOfRegisteredRecords.Add("ServicesForRegistrationOfReportsToPrincipal");
	SetsOfRegisteredRecords.Add("InvestmentInRent");
	ExchangeDifferenceCalculationLocalization.CompleteCleaningSets(SetsOfRegisteredRecords);
	
	For Each SetName In SetsOfRegisteredRecords Do
		Set = Var_ThisObject.RegisterRecords[SetName]; // AccumulationRegisterRecordSet - 
		Set.Clear();
		Set.Write();
	EndDo;
	
EndProcedure

Function ThereAreRegisteredRecordsOnTerms()
	
	QueryText = 
	"SELECT TOP 1
	|	CalculationsByTerms.DocumentRecorder AS DocumentRecorder
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS CalculationsByTerms
	|WHERE
	|	CalculationsByTerms.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND CalculationsByTerms.DocumentRecorder = &DocumentRecorder";
	If BusinessOperation = Enums.BusinessTransactions.RevaluationOfCustomersARAP Then
		QueryText = StrReplace(QueryText, "VendorsARAPAccounting", "CustomersARAPAccounting");
	EndIf;
	
	Query = New Query(QueryText);
	
	Query.SetParameter("BeginOfPeriod", BegOfMonth(Date));
	Query.SetParameter("EndOfPeriod", EndOfMonth(Date));
	Query.SetParameter("DocumentRecorder", Ref);
	
	RecordsSet = Query.Execute();
	
	Return Not RecordsSet.IsEmpty();
	
EndFunction

#EndRegion

#EndIf
