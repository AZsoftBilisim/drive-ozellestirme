// @strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	CustomerBonusCertificateLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	ItemsAndDimensionsSelectionParameters = Documents.CustomerBonusCertificate.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("DocumentRef.AccrualOfCustomerRebates") Then
		
		DocumentAccruals = FillingData; // DocumentRef.AccrualOfCustomerRebates
		
		PartyCountDetails = Common.ObjectAttributeValue(
			DocumentAccruals,
			"TermDocument.PartyCountDetails");
		
		If PartyCountDetails = Enums.ARAPAccountingDrilldownsOfRebatesParticipants.ByCustomer Then
			
			MessageTemplate = NStr("vi = 'Sử dụng tính toán chi tiết ""Theo khách hàng"". Không thể nhập chứng từ ""%1"".';
									|ru = 'Используется детализация расчета ""По клиенту"". Ввод документа ""%1"" не доступен.';
									|en = 'The ""By customer"" AR/AP item is used. Cannot register the ""%1"" document.'; fa = 'The ""By customer"" AR/AP item is used. Cannot register the ""%1"" document.';
									|it = 'Используется детализация расчета ""По клиенту"". Ввод документа ""%1"" не доступен.';
									|pl = 'The ""By customer"" AR/AP item is used. Cannot register the ""%1"" document.';
									|tr = '""Müşteriye göre"" hesaplama detayı kullanılır. ""%1"" belge girişi mevcut değildir.'");
			DocumentSynonym = Metadata().Synonym;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, DocumentSynonym);
			Common.MessageToUser(MessageText, DocumentAccruals, "TermDocument");
			
			StandardProcessing = False;
			
		Else
			
			FillInAccordingToAccrualDocument(DocumentAccruals, StandardProcessing);
			ARAPAccountingServer.Filling(ThisObject, FillingData);
			
			CalculateAmountOfSettlementsOfTabularPart();
			
		EndIf;
		
	ElsIf FillInDataType = Type("Structure") 
			And FillingData.Property("FillingByBalances") Then
		
		FillOutDocumentOnBalances(FillingData);
		ARAPAccountingServer.Filling(ThisObject, FillingData);
		
		CalculateAmountOfSettlementsOfTabularPart();
		
	EndIf;
	
	InitializeDocument();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array; // Array of String
	
	If Status <> Enums.CustomerBonusCertificateStatuses.Received Then
		
		NotCheckedAttributeArray.Add("AccountingRecognitionDate");
		NotCheckedAttributeArray.Add("ExpenseItemAssets");
		
	Else
		
		If AccountingRecognitionDate <> Date(1, 1, 1)
		   And BegOfDay(Date) > AccountingRecognitionDate Then
			
			MessageText = NStr("vi = 'Ngày đưa vào kế toán không thể nhỏ hơn ngày chứng từ';
								|ru = 'Дата признания в учете не может быть меньше даты документа';
								|en = 'Recognition date cannot be less than the document date'; fa = 'Recognition date cannot be less than the document date';
								|it = 'Дата признания в учете не может быть меньше даты документа';
								|pl = 'Recognition date cannot be less than the document date';
								|tr = 'Kabul tarihi, belgenin tarihinden daha önce olamaz'");
			Common.MessageToUser(MessageText, ThisObject, "AccountingRecognitionDate",, Cancel);
			
		EndIf;
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	ItemsAndDimensionsSelectionParameters = Documents.CustomerBonusCertificate.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(
		ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	CustomerBonusCertificateLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ExchangePlans.MasterNode() <> Undefined Then
		
		MessageText = NStr("vi = 'Cấm thay đổi chứng từ trong nút phụ trao đổi';
							|ru = 'Запрещено изменение документа в подчиненном узле обмена';
							|en = 'Cannot change the document in a subordinate exchange node'; fa = 'Cannot change the document in a subordinate exchange node';
							|it = 'Запрещено изменение документа в подчиненном узле обмена';
							|pl = 'Cannot change the document in a subordinate exchange node';
							|tr = 'Bağımlı değişim düğümündeki belgenin değiştirilmesi yasaktır'");
		Common.MessageToUser(MessageText, ThisObject,,, Cancel);
		
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	BonusAmount = Rebates.Total("BonusAmount");
	AmountARAP = Rebates.Total("AmountARAP");
	
	TMCommonUse.FillInDocumentIDs(ThisObject);
	SetupParameters = Documents.CustomerBonusCertificate.AccountingAccountSettings_();
	GLAccountSettingsServer.BeforeWrite(ThisObject, SetupParameters);
	ItemsAndDimensionsSelectionParameters = Documents.CustomerBonusCertificate.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If IsNew()
	   And Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	CustomerBonusCertificateLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	CustomerBonusCertificateLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	CustomerBonusCertificateLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	CustomerBonusCertificateLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Status = Enums.CustomerBonusCertificateStatuses.Prepared;
	ARAPAccountingServer.OnCopy(ThisObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject);
	
	InitializeDocument();
	
	CustomerBonusCertificateLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	If GetFunctionalOption("NotUseMultipleCurrencies") Then
		
		CurrencyByCompany = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		DocumentCurrency = CurrencyByCompany;
		ARAPCurrency = CurrencyByCompany;
		
	EndIf;
	
	Status = Enums.CustomerBonusCertificateStatuses.Prepared;
	AccountingRecognitionDate = Date(1, 1, 1);
	
EndProcedure

#Region InputOnBasis

// Parameters:
//  FillingData - Structure:
//   * Date - Date
//   * Organization - CatalogRef.Companies
//   * Counterparty - CatalogRef.Counterparties
//   * Partner - CatalogRef.Partners
//   * DocumentCurrency - CatalogRef.Currencies
//   * ARAPCurrency - CatalogRef.Currencies
//
Procedure FillOutDocumentOnBalances(FillingData)
	
	FillPropertyValues(ThisObject, FillingData);
	
	SummaryByCounterparty = (FillingData.Partner = Catalogs.Partners.EmptyRef());
	
	Query = New Query;
	Query.SetParameter("Organization", FillingData.Organization);
	Query.SetParameter("Counterparty", FillingData.Counterparty);
	Query.SetParameter("Currency", FillingData.ARAPCurrency);
	Query.SetParameter("SummaryByCounterparty", SummaryByCounterparty);
	BoundaryOfResidues = New Boundary(EndOfDay(FillingData.Date), BoundaryType.Including);
	Query.SetParameter("BoundaryOfResidues", BoundaryOfResidues);
	
	QueriesArray = New Array; // Array of String
	
	QueryText =
	"SELECT
	|	CustomerRebates.Organization AS Organization,
	|	CustomerRebates.Counterparty AS Counterparty,
	|	CustomerRebates.Partner AS Partner,
	|	CustomerRebates.BeginOfPeriod AS BeginOfPeriod,
	|	CustomerRebates.PeriodEnding AS PeriodEnding,
	|	CustomerRebates.TermDocument AS TermDocument,
	|	CustomerRebates.Currency AS Currency,
	|	CASE
	|		WHEN CustomerRebates.AmountBonusOpeningBalance - CustomerRebates.ToCertifyOpeningBalance - CustomerRebates.ToSignOpeningBalance - CustomerRebates.ToWriteOffOpeningBalance > CustomerRebates.AmountBonusClosingBalance - CustomerRebates.ToCertifyClosingBalance - CustomerRebates.ToSignClosingBalance - CustomerRebates.ToWriteOffClosingBalance
	|			THEN CustomerRebates.AmountBonusClosingBalance - CustomerRebates.ToCertifyClosingBalance - CustomerRebates.ToSignClosingBalance - CustomerRebates.ToWriteOffClosingBalance
	|		ELSE CustomerRebates.AmountBonusOpeningBalance - CustomerRebates.ToCertifyOpeningBalance - CustomerRebates.ToSignOpeningBalance - CustomerRebates.ToWriteOffOpeningBalance
	|	END AS BonusAmount,
	|	CASE
	|		WHEN CustomerRebates.AmountBonusOpeningBalance - CustomerRebates.ToCertifyOpeningBalance - CustomerRebates.ToSignOpeningBalance - CustomerRebates.ToWriteOffOpeningBalance > CustomerRebates.AmountBonusClosingBalance - CustomerRebates.ToCertifyClosingBalance - CustomerRebates.ToSignClosingBalance - CustomerRebates.ToWriteOffClosingBalance
	|			THEN CustomerRebates.AmountBonusClosingBalance - CustomerRebates.ToCertifyClosingBalance - CustomerRebates.ToSignClosingBalance - CustomerRebates.ToWriteOffClosingBalance
	|		ELSE CustomerRebates.AmountBonusOpeningBalance - CustomerRebates.ToCertifyOpeningBalance - CustomerRebates.ToSignOpeningBalance - CustomerRebates.ToWriteOffOpeningBalance
	|	END AS AmountARAP
	|FROM
	|	AccumulationRegister.CustomerRebates.BalanceAndTurnovers(
	|			&BoundaryOfResidues,
	|			,
	|			,
	|			,
	|			Organization = &Organization
	|				AND Counterparty = &Counterparty
	|				AND Currency = &Currency
	|				AND &AddlConditionBalance) AS CustomerRebates
	|WHERE
	|	CustomerRebates.AmountBonusOpeningBalance - CustomerRebates.ToCertifyOpeningBalance - CustomerRebates.ToSignOpeningBalance - CustomerRebates.ToWriteOffOpeningBalance > 0
	|	AND CustomerRebates.AmountBonusClosingBalance - CustomerRebates.ToCertifyClosingBalance - CustomerRebates.ToSignClosingBalance - CustomerRebates.ToWriteOffClosingBalance > 0";
	
	QueriesArray.Add(QueryText);
	
	If Not SummaryByCounterparty Then
		
		QueryText = 
		"SELECT TOP 2
		|	CounterpartyContracts.Ref AS Contract,
		|	CounterpartyContracts.FinancialAccountingGroup AS FinancialAccountingGroup,
		|	CounterpartyContracts.LineOfBusiness AS LineOfBusiness
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	CounterpartyContracts.Organization = &Organization
		|	AND CounterpartyContracts.Counterparty = &Counterparty
		|	AND CounterpartyContracts.ARAPCurrency = &Currency
		|	AND CounterpartyContracts.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|	AND NOT CounterpartyContracts.DeletionMark
		|	AND CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
		|	AND CounterpartyContracts.Partner IN (&PartnerList)
		|	AND CounterpartyContracts.ItIsAllowedToWorkWithSubsidiaryPartners
		|
		|UNION
		|
		|SELECT TOP 2
		|	CounterpartyContracts.Ref,
		|	CounterpartyContracts.FinancialAccountingGroup,
		|	CounterpartyContracts.LineOfBusiness
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	CounterpartyContracts.Organization = &Organization
		|	AND CounterpartyContracts.Counterparty = &Counterparty
		|	AND CounterpartyContracts.ARAPCurrency = &Currency
		|	AND CounterpartyContracts.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|	AND NOT CounterpartyContracts.DeletionMark
		|	AND CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
		|	AND CounterpartyContracts.Partner = &Partner
		|	AND NOT CounterpartyContracts.ItIsAllowedToWorkWithSubsidiaryPartners";
		
		PartnerList = New ValueList;
		Partner = FillingData.Partner;
		PartnersAndCounterparties.FillInListOfPartnersWithParents(Partner, PartnerList);
		
		Query.SetParameter("Partner", Partner);
		Query.SetParameter("PartnerList", PartnerList);
		
	Else
		
		QueryText = 
		"SELECT TOP 2
		|	CounterpartyContracts.Ref AS Contract,
		|	CounterpartyContracts.FinancialAccountingGroup AS FinancialAccountingGroup,
		|	CounterpartyContracts.LineOfBusiness AS LineOfBusiness
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	CounterpartyContracts.Organization = &Organization
		|	AND CounterpartyContracts.Counterparty = &Counterparty
		|	AND CounterpartyContracts.ARAPCurrency = &Currency
		|	AND CounterpartyContracts.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|	AND NOT CounterpartyContracts.DeletionMark
		|	AND CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Counterparties.Partner AS Partner
		|FROM
		|	Catalog.Counterparties AS Counterparties
		|WHERE
		|	Counterparties.Ref = &Counterparty";
		
	EndIf;
	
	QueriesArray.Add(QueryText);
	QueryText = StrConcat(QueriesArray, Common.QueryBatchSeparator());
	
	If Not SummaryByCounterparty Then
		
		QueryText = StrReplace(QueryText, "&AddlConditionBalance", "Partner = &Partner");
		
	Else
		
		QueryText = StrReplace(QueryText, "&AddlConditionBalance", "TRUE");
		
	EndIf;
	
	Query.Text = QueryText;
	Result = Query.ExecuteBatch();
	
	If Not Result[0].IsEmpty() Then
		
		Rebates.Load(Result[0].Unload());
		
	EndIf;
	
	If Not Result[1].IsEmpty() Then 
		
		Selection = Result[1].Select();
		
		If Selection.Count() = 1 Then
			
			Selection.Next();
			FillPropertyValues(ThisObject, Selection);
			
		EndIf;
		
	EndIf;
	
	If SummaryByCounterparty
	   And Not Result[2].IsEmpty() Then
		
		Selection = Result[2].Select();
		Selection.Next();
		FillPropertyValues(ThisObject, Selection);
		
	EndIf;
	
EndProcedure

// Parameters:
//  AccrualDocument - DocumentRef.AccrualOfCustomerRebates
//  StandardProcessing - Boolean - 
//
Procedure FillInAccordingToAccrualDocument(AccrualDocument, StandardProcessing)
	
	HeaderData_ = Documents.AccrualOfCustomerRebates.DataOfAccrualDocument(AccrualDocument);
	
	If HeaderData_ <> Undefined Then
		
		Organization = HeaderData_.Organization;
		Counterparty = HeaderData_.Counterparty;
		Partner = HeaderData_.CounterpartySPartner;
		DocumentCurrency = HeaderData_.Currency;
		ARAPCurrency = HeaderData_.Currency;
		
		FillContract(HeaderData_);
		
		If HeaderData_.Sum = 0 Then
			
			MessageText = NStr("vi = 'Trong chứng từ tính toán không có khoản thưởng được tính có số tiền dương';
								|ru = 'По документу начислений нет начисленных бонусов с положительными суммами';
								|en = 'For the accrual document, there are no accrued rebates with positive amounts'; fa = 'For the accrual document, there are no accrued rebates with positive amounts';
								|it = 'По документу начислений нет начисленных бонусов с положительными суммами';
								|pl = 'For the accrual document, there are no accrued rebates with positive amounts';
								|tr = 'Tahakkuk belgesinde artı tutarlı olarak tahakkuk eden herhangi bir bonus mevcut değildir'");
			Common.MessageToUser(MessageText, AccrualDocument);
			StandardProcessing = False;
			
		Else
			
			SamplingDetailedData = HeaderData_.Select();
			FillInAccrualRebatesAccordingToDocument(SamplingDetailedData);
			
		EndIf;
		
	Else
		
		MessageText = NStr("vi = 'Không thể nhận dữ liệu chứng từ tính toán. Có thể là, chứng từ chưa được kết chuyển.';
							|ru = 'Не удалось получить данные документа начислений. Возможно, документ не проведен.';
							|en = 'Cannot get data of the accrual document. The document might not be posted.'; fa = 'Cannot get data of the accrual document. The document might not be posted.';
							|it = 'Не удалось получить данные документа начислений. Возможно, документ не проведен.';
							|pl = 'Cannot get data of the accrual document. The document might not be posted.';
							|tr = 'Tahakkuk belgesi verileri alınamadı. Belge kontrol edilmemiş olabilir.'");
		Common.MessageToUser(MessageText, AccrualDocument);
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

Procedure FillContract(HeaderData_)
	
	ContractBusinessTransaction = Enums.BusinessTransactions.SaleToCustomer;
	ContractStatus = Enums.CounterpartyContractStatuses.Valid;
	
	PartnerList = New ValueList;
	PartnersAndCounterparties.FillInListOfPartnersWithParents(HeaderData_.CounterpartySPartner, PartnerList);
	
	QueryText =
	"SELECT TOP 2
	|	CounterpartyContracts.Ref AS Contract,
	|	CounterpartyContracts.ARAPCurrency AS ARAPCurrency,
	|	CounterpartyContracts.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	CounterpartyContracts.LineOfBusiness AS LineOfBusiness
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|WHERE
	|	NOT CounterpartyContracts.DeletionMark
	|	AND CounterpartyContracts.Organization = &Organization
	|	AND CounterpartyContracts.Counterparty = &Counterparty
	|	AND CounterpartyContracts.Partner IN (&PartnerList)
	|	AND CounterpartyContracts.ARAPCurrency = &Currency
	|	AND CounterpartyContracts.BusinessOperation = &BusinessOperation
	|	AND CounterpartyContracts.Status = &Status";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Organization", HeaderData_.Organization);
	Query.SetParameter("Counterparty", HeaderData_.Counterparty);
	Query.SetParameter("PartnerList", PartnerList);
	Query.SetParameter("Currency", HeaderData_.Currency);
	Query.SetParameter("BusinessOperation", ContractBusinessTransaction);
	Query.SetParameter("Status", ContractStatus);
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		If Selection.Count() = 1
		   And Selection.Next() Then
			
			FillPropertyValues(ThisObject, Selection);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//  DataFromRebates - QueryResultSelection:
//  * TermDocument - DocumentRef.ConditionsOfCustomerRebates
//  * Partner - CatalogRef.Partners
//  * BeginOfPeriod - Date
//  * PeriodEnding - Date
//  * Sum - Number
// 
Procedure FillInAccrualRebatesAccordingToDocument(DataFromRebates)
	
	While DataFromRebates.Next() Do
		
		If DataFromRebates.Sum > 0 Then
			
			NewRow = Rebates.Add();
			FillPropertyValues(NewRow, DataFromRebates);
			NewRow.BonusAmount = DataFromRebates.Sum;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CalculateAmountOfSettlementsOfTabularPart()
	
	If Rebates.Count() = 0 Then
		Return;
	EndIf;
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	CalculationParameters = New Structure;
	CalculationParameters.Insert("Currency", DocumentCurrency);
	CalculationParameters.Insert("CourseNumerator", CourseNumerator);
	CalculationParameters.Insert("CourseDenominator", CourseDenominator);
	CalculationParameters.Insert("ARAPCurrency", ARAPCurrency);
	
	For Each TSRow In Rebates Do
		
		TSRow.AmountARAP = RebatesClientServer.RecalculateAmountOfSettlementsInLine(
			CalculationParameters, TSRow.BonusAmount, CurrencyOfComplianceAccounting);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf