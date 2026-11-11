
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the transaction subconto from the transmitted transaction data
//
// Parameters:
//  AccountingEntry - AccountingRegisterRecord.InternationalWithoutCorrespondence - the transaction that you want to fill out a subconto for
//  Data   - KeyAndValue of Structure - a structure containing ExtDimension data:
//             * Key - String - The fields of the subconto posting are "Viewsubconto1,Subconto1...."
//             * Value - Arbitrary - The value of the subconto fields
//
Procedure InstallExtdimension(AccountingEntry, Data) Export
	
	Name_Account = "Account";
	NameExtdimension = "ExtDimension";
	ExtraDimensionTypeName = "ExtDimensionType";

	Account = AccountingEntry[Name_Account];
	AccountProperties = FinancialAccountingServerCached.AccountProperties(Account);
	For Number = 1 To AccountProperties.ExtDimensionCount Do
		ExtDimensionType = Data[ExtraDimensionTypeName + Number];
		AccountingEntry.ExtDimensions[ExtDimensionType] = Data[NameExtdimension + Number];
	EndDo;
	
EndProcedure

// Adds the transferred transaction to the current recordset
//
// Parameters:
//  AccountingEntry - AccountingRegisterRecord.InternationalWithoutCorrespondence, Structure - transaction to add
//  ContentText - String - text of the transaction content.
//
Procedure AddTransaction(AccountingEntry, ContentText = "") Export
	
	NewEntry = Add();
	FillPropertyValues(NewEntry, AccountingEntry);
	If Not IsBlankString(ContentText) Then
		NewEntry.Content = ContentText;
	EndIf;
	For Each ExtDimension In AccountingEntry.ExtDimensions Do
		NewEntry.ExtDimensions[ExtDimension.Key] = ExtDimension.Value;
	EndDo;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	EmptyTransactionAmounts = False;
	For Each Record In ThisObject Do
		If Record.Sum = 0 And Record.PresentationAmount = 0 Then
			EmptyTransactionAmounts = True;
			Break;
		EndIf;
	EndDo;
	
	If Not EmptyTransactionAmounts Then
		NotCheckedAttributeArray = New Array;
		NotCheckedAttributeArray.Add("Sum");
		NotCheckedAttributeArray.Add("PresentationAmount");
		Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	AccountingRegisters.InternationalWithoutCorrespondence.PerformAdditionalProcessingOfTransactions(ThisObject);
	
	Recorder = Filter.Recorder.Value;
	TempTablesManager = New TempTablesManager();
	GenerateCorrectiveTransactions_ = ThereIsNeedForFormationOfCorrectivePostings(Recorder, TempTablesManager);
	Text = NStr("vi = 'Đặt ngày cấm thay đổi bút toán theo kế toán quốc tế.
				|Việc hủy bỏ kết chuyển chứng từ bị cấm.';
				|ru = 'Установлена дата запрета изменения проводок по международному учету.
				|Отмена проведения документа запрещена.';
				|en = 'A period-end closing date for financial accounting entries is set.
				|You cannot unpost the document.'; fa = 'A period-end closing date for financial accounting entries is set.
				|You cannot unpost the document.';
				|it = 'Установлена дата запрета изменения проводок по международному учету.
				|Отмена проведения документа запрещена.';
				|pl = 'A period-end closing date for financial accounting entries is set.
				|You cannot unpost the document.';
				|tr = 'Uluslararası muhasebe girişlerinde değişiklik dönem sonu kapanış tarihi belirlendi.
				|Belge kaydı iptali yasaktır.'");
	
	If TypeOf(Recorder) = Type("DocumentRef.TransactionFinancialAccounting") Then
		EnterPeriodByRows = AdditionalProperties.Property("EnterPeriodByRows");
		If GenerateCorrectiveTransactions_ And Not EnterPeriodByRows Then
			Text = Text + Chars.LF + Chars.LF
				+ NStr("vi = 'Chỉ được phép sửa các bút toán của chứng từ ""Giao dịch thủ công (kế toán quốc tế)"" trong kỳ kế toán quốc tế đã đóng 
				|khi đặt dấu hộp kiểm ""Nhập ngày vào dòng"" trên thẻ ""Chung"".';
				|ru = 'Корректировать проводки документа ""Операция (международный учет)"" в закрытом периоде по международному учету
				|допускается только с включенным флагом ""Вводить дату в строках"" на закладке ""Основное"".';
				|en = 'You can make adjustments to the ""Transaction (financial accounting)"" document entries for the closed period of international accounting
				|only if the ""Enter date in lines"" check box on the Main tab is selected.'; fa = 'You can make adjustments to the ""Transaction (financial accounting)"" document entries for the closed period of international accounting
				|only if the ""Enter date in lines"" check box on the Main tab is selected.';
				|it = 'É concesso rettificare le voci del registro relative al documento ""Operazione (contabilità internazionale)"" secondo i principi contabili internazionali nel periodo chiuso 
				| soltanto previa attivazione del flag ""Inserire la data nelle righe"" nella scheda ""Principale"".';
				|pl = 'Korekta dekretowania dokumentu „Operacja (ewidencja międzynarodowa)” w zamkniętym okresie ewidencji międzynarodowej
				|jest możliwa wyłącznie z włączonym zaznaczeniem ""Wprowadzać datę w wierszach"" na karcie ""Podstawowe"".';
				|tr = '""İşlem (uluslararası muhasebe)"" belgesinin girişlerini, uluslararası muhasebe kapsamındaki kapalı bir dönemde yalnızca
				|""Ana"" sekmesindeki ""Tarihi satırlara gir"" bayrağı etkinken düzeltmeye izin verilir.'");
			Raise Text;
		EndIf;
	EndIf;
	
	If GenerateCorrectiveTransactions_ Then
		
		UndoPosting = AdditionalProperties.Property("DocumentProperties")
			And AdditionalProperties.DocumentProperties.WriteMode = DocumentWriteMode.UndoPosting;
		
		ClearRecordSet = False;
		
		If Count() = 0 And Not UndoPosting Then
			Read();
			ClearRecordSet = True;
		EndIf;
		
		NoActiveEntries = Count() = 0 Or Not ThisObject[0].Active;
		
		If UndoPosting Or NoActiveEntries Then
			WriteEmptySet = False;
			If Not AdditionalProperties.Property("WriteEmptySet", WriteEmptySet) Or Not WriteEmptySet Then
				Raise Text;
			EndIf;
		EndIf;
		
		If ClearRecordSet Then
			Clear();
		EndIf;
		
		GenerateCorrectiveTransactions(Recorder, TempTablesManager);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure GenerateCorrectiveTransactions(Recorder, TempTablesManager)
	
	Query = New Query(TextOfRequestForCorrectiveTransactions());
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Document", Recorder);
	Query.SetParameter("RecordsSet", Unload());
	
	Clear();
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		NewEntry = Add();
		FillPropertyValues(NewEntry, Selection);
		InstallExtdimension(NewEntry, Selection);
	EndDo;
	
EndProcedure

Function TextOfRequestForCorrectiveTransactions()
	
	QueryText = "
	|SELECT
	|	RecordsSet.RecordType,
	|	RecordsSet.Period,
	|	RecordsSet.Recorder,
	|	RecordsSet.ChartOfAccounts,
	|	RecordsSet.Organization,
	|	RecordsSet.Account,
	|	RecordsSet.Department,
	|	RecordsSet.LineOfBusiness,
	|	RecordsSet.ExtDimensionType1,
	|	RecordsSet.ExtDimension1,
	|	RecordsSet.ExtDimensionType2,
	|	RecordsSet.ExtDimension2,
	|	RecordsSet.ExtDimensionType3,
	|	RecordsSet.ExtDimension3,
	|	RecordsSet.Currency,
	|	RecordsSet.CurrencyAmount,
	|	RecordsSet.Count,
	|	RecordsSet.Sum,
	|	RecordsSet.PresentationAmount,
	|	RecordsSet.PostingTemplate
	|INTO RecordsSet
	|FROM
	|	&RecordsSet AS RecordsSet
	|INDEX BY
	|	Account
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RecordsSet.Account AS Account
	|INTO SetAccounts
	|FROM
	|	RecordsSet AS RecordsSet
	|INDEX BY
	|	Account
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExtDimensionTypes.Ref AS Account,
	|	ExtDimensionTypes.LineNumber AS ExtDimensionNumber,
	|	ExtDimensionTypes.ExtDimensionType AS ExtDimensionType
	|INTO ExtdimensionOfAccounts
	|FROM
	|	ChartOfAccounts.International.ExtDimensionTypes AS ExtDimensionTypes
	|	INNER JOIN SetAccounts AS SetAccounts
	|		ON ExtDimensionTypes.Ref = SetAccounts.Account
	|INDEX BY
	|	Account,
	|	ExtDimensionNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RecordsSet.RecordType,
	|	RecordsSet.Period,
	|	RecordsSet.Recorder,
	|	RecordsSet.ChartOfAccounts,
	|	RecordsSet.Organization,
	|	RecordsSet.Account,
	|	RecordsSet.Department,
	|	RecordsSet.LineOfBusiness,
	|	ISNULL(ExtdimensionOfAccounts1.ExtDimensionType, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionType1,
	|	CASE
	|		WHEN ExtdimensionOfAccounts1.ExtDimensionType = RecordsSet.ExtDimensionType1
	|			THEN RecordsSet.ExtDimension1
	|		WHEN ExtdimensionOfAccounts1.ExtDimensionType = RecordsSet.ExtDimensionType2
	|			THEN RecordsSet.ExtDimension2
	|		WHEN ExtdimensionOfAccounts1.ExtDimensionType = RecordsSet.ExtDimensionType3
	|			THEN RecordsSet.ExtDimension3
	|		ELSE UNDEFINED
	|	END AS ExtDimension1,
	|	ISNULL(ExtdimensionOfAccounts2.ExtDimensionType, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionType2,
	|	CASE
	|		WHEN ExtdimensionOfAccounts2.ExtDimensionType = RecordsSet.ExtDimensionType1
	|			THEN RecordsSet.ExtDimension1
	|		WHEN ExtdimensionOfAccounts2.ExtDimensionType = RecordsSet.ExtDimensionType2
	|			THEN RecordsSet.ExtDimension2
	|		WHEN ExtdimensionOfAccounts2.ExtDimensionType = RecordsSet.ExtDimensionType3
	|			THEN RecordsSet.ExtDimension3
	|		ELSE UNDEFINED
	|	END AS ExtDimension2,
	|	ISNULL(ExtdimensionOfAccounts3.ExtDimensionType, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionType3,
	|	CASE
	|		WHEN ExtdimensionOfAccounts3.ExtDimensionType = RecordsSet.ExtDimensionType1
	|			THEN RecordsSet.ExtDimension1
	|		WHEN ExtdimensionOfAccounts3.ExtDimensionType = RecordsSet.ExtDimensionType2
	|			THEN RecordsSet.ExtDimension2
	|		WHEN ExtdimensionOfAccounts3.ExtDimensionType = RecordsSet.ExtDimensionType3
	|			THEN RecordsSet.ExtDimension3
	|		ELSE UNDEFINED
	|	END AS ExtDimension3,
	|	RecordsSet.Currency,
	|	RecordsSet.CurrencyAmount,
	|	RecordsSet.Count,
	|	RecordsSet.Sum,
	|	RecordsSet.PresentationAmount,
	|	RecordsSet.PostingTemplate,
	|	CASE
	|		WHEN RecordsSet.Period > ISNULL(DatesBannedByOrganization_.PeriodEndClosingDate, DATETIME(1,1,1)) 
	|			THEN RecordsSet.Period
	|		ELSE DATEADD(DatesBannedByOrganization_.PeriodEndClosingDate, SECOND, 1)
	|	END AS AdjustmentPeriod_
	|INTO NewTransactions
	|FROM
	|	RecordsSet AS RecordsSet
	|	LEFT JOIN ExtdimensionOfAccounts AS ExtdimensionOfAccounts1
	|		ON RecordsSet.Account = ExtdimensionOfAccounts1.Account
	|		 AND ExtdimensionOfAccounts1.ExtDimensionNumber = 1
	|	LEFT JOIN ExtdimensionOfAccounts AS ExtdimensionOfAccounts2
	|		ON RecordsSet.Account = ExtdimensionOfAccounts2.Account
	|		 AND ExtdimensionOfAccounts2.ExtDimensionNumber = 2
	|	LEFT JOIN ExtdimensionOfAccounts AS ExtdimensionOfAccounts3
	|		ON RecordsSet.Account = ExtdimensionOfAccounts3.Account
	|		 AND ExtdimensionOfAccounts3.ExtDimensionNumber = 3
	|	LEFT JOIN DatesBannedByOrganization_ AS DatesBannedByOrganization_
	|		ON RecordsSet.Organization = DatesBannedByOrganization_.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OriginalPostings.RecordType,
	|	OriginalPostings.Period,
	|	OriginalPostings.Recorder,
	|	OriginalPostings.ChartOfAccounts,
	|	OriginalPostings.Organization,
	|	OriginalPostings.Account,
	|	ISNULL(OriginalPostings.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|	ISNULL(OriginalPostings.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|	ISNULL(OriginalPostings.ExtDimensionType1, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionType1,
	|	ISNULL(OriginalPostings.ExtDimension1, UNDEFINED) AS ExtDimension1,
	|	ISNULL(OriginalPostings.ExtDimensionType2, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionType2,
	|	ISNULL(OriginalPostings.ExtDimension2, UNDEFINED) AS ExtDimension2,
	|	ISNULL(OriginalPostings.ExtDimensionType3, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionType3,
	|	ISNULL(OriginalPostings.ExtDimension3, UNDEFINED) AS ExtDimension3,
	|	ISNULL(OriginalPostings.Currency, VALUE(Catalog.Currencies.EmptyRef)) AS Currency,
	|	ISNULL(OriginalPostings.CurrencyAmount, 0) AS CurrencyAmount,
	|	ISNULL(OriginalPostings.Count, 0) AS Count,
	|	OriginalPostings.Sum,
	|	OriginalPostings.PresentationAmount,
	|	OriginalPostings.PostingTemplate,
	|	OriginalPostings.PostingType,
	|	OriginalPostings.Content,
	|	DATEADD(DatesBannedByOrganization_.PeriodEndClosingDate, SECOND, 1) AS AdjustmentPeriod_
	|INTO OriginalPostings
	|FROM
	|	AccountingRegister.InternationalWithoutCorrespondence.RecordsWithExtDimensions(, , Recorder IN (&Document), , ) AS OriginalPostings
	|	INNER JOIN DatesBannedByOrganization_ AS DatesBannedByOrganization_
	|		ON OriginalPostings.Organization = DatesBannedByOrganization_.Organization
	|			AND OriginalPostings.Period <= DatesBannedByOrganization_.PeriodEndClosingDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.RecordType,
	|	NestedQuery.Period,
	|	NestedQuery.Recorder,
	|	NestedQuery.ChartOfAccounts,
	|	NestedQuery.Organization,
	|	NestedQuery.Account,
	|	NestedQuery.Department,
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.ExtDimensionType1,
	|	NestedQuery.ExtDimension1,
	|	NestedQuery.ExtDimensionType2,
	|	NestedQuery.ExtDimension2,
	|	NestedQuery.ExtDimensionType3,
	|	NestedQuery.ExtDimension3,
	|	NestedQuery.Currency,
	|	SUM(NestedQuery.CurrencyAmount) AS CurrencyAmount,
	|	SUM(NestedQuery.Count) AS Count,
	|	SUM(NestedQuery.Sum) AS Sum,
	|	SUM(NestedQuery.PresentationAmount) AS PresentationAmount,
	|	NestedQuery.PostingTemplate AS PostingTemplate,
	|	VALUE(Enum.PostingTypesFinancialAccounting.Adjusting) AS PostingType
	|INTO AdjustmentEntries
	|FROM
	|	(SELECT
	|		PostingsStorno.RecordType AS RecordType,
	|		PostingsStorno.AdjustmentPeriod_ AS Period,
	|		PostingsStorno.Recorder AS Recorder,
	|		PostingsStorno.ChartOfAccounts AS ChartOfAccounts,
	|		PostingsStorno.Organization AS Organization,
	|		PostingsStorno.Account AS Account,
	|		PostingsStorno.Department AS Department,
	|		PostingsStorno.LineOfBusiness AS LineOfBusiness,
	|		PostingsStorno.ExtDimensionType1 AS ExtDimensionType1,
	|		PostingsStorno.ExtDimension1 AS ExtDimension1,
	|		PostingsStorno.ExtDimensionType2 AS ExtDimensionType2,
	|		PostingsStorno.ExtDimension2 AS ExtDimension2,
	|		PostingsStorno.ExtDimensionType3 AS ExtDimensionType3,
	|		PostingsStorno.ExtDimension3 AS ExtDimension3,
	|		PostingsStorno.Currency AS Currency,
	|		-PostingsStorno.CurrencyAmount AS CurrencyAmount,
	|		-PostingsStorno.Count AS Count,
	|		-PostingsStorno.Sum AS Sum,
	|		-PostingsStorno.PresentationAmount AS PresentationAmount,
	|		PostingsStorno.PostingTemplate AS PostingTemplate
	|	FROM
	|		OriginalPostings AS PostingsStorno
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NewTransactions.RecordType,
	|		NewTransactions.AdjustmentPeriod_,
	|		NewTransactions.Recorder,
	|		NewTransactions.ChartOfAccounts,
	|		NewTransactions.Organization,
	|		NewTransactions.Account,
	|		NewTransactions.Department,
	|		NewTransactions.LineOfBusiness,
	|		NewTransactions.ExtDimensionType1,
	|		NewTransactions.ExtDimension1,
	|		NewTransactions.ExtDimensionType2,
	|		NewTransactions.ExtDimension2,
	|		NewTransactions.ExtDimensionType3,
	|		NewTransactions.ExtDimension3,
	|		NewTransactions.Currency,
	|		NewTransactions.CurrencyAmount,
	|		NewTransactions.Count,
	|		NewTransactions.Sum,
	|		NewTransactions.PresentationAmount,
	|		NewTransactions.PostingTemplate
	|	FROM
	|		NewTransactions AS NewTransactions) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.RecordType,
	|	NestedQuery.Period,
	|	NestedQuery.Recorder,
	|	NestedQuery.ChartOfAccounts,
	|	NestedQuery.Organization,
	|	NestedQuery.Account,
	|	NestedQuery.Department,
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.ExtDimensionType1,
	|	NestedQuery.ExtDimension1,
	|	NestedQuery.ExtDimensionType2,
	|	NestedQuery.ExtDimension2,
	|	NestedQuery.ExtDimensionType3,
	|	NestedQuery.ExtDimension3,
	|	NestedQuery.Currency,
	|	NestedQuery.PostingTemplate
	|	
	|HAVING
	|	SUM(NestedQuery.Sum) <> 0
	|	OR SUM(NestedQuery.Count) <> 0
	|	OR SUM(NestedQuery.CurrencyAmount) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OriginalPostings.RecordType,
	|	OriginalPostings.Period,
	|	OriginalPostings.Recorder,
	|	OriginalPostings.ChartOfAccounts,
	|	OriginalPostings.Organization,
	|	OriginalPostings.Account,
	|	OriginalPostings.Department,
	|	OriginalPostings.LineOfBusiness,
	|	OriginalPostings.ExtDimensionType1,
	|	OriginalPostings.ExtDimension1,
	|	OriginalPostings.ExtDimensionType2,
	|	OriginalPostings.ExtDimension2,
	|	OriginalPostings.ExtDimensionType3,
	|	OriginalPostings.ExtDimension3,
	|	OriginalPostings.Currency,
	|	OriginalPostings.CurrencyAmount,
	|	OriginalPostings.Count,
	|	OriginalPostings.Sum,
	|	OriginalPostings.PresentationAmount,
	|	OriginalPostings.PostingTemplate,
	|	OriginalPostings.PostingType,
	|	OriginalPostings.Content
	|FROM
	|	OriginalPostings AS OriginalPostings
	|
	|UNION ALL
	|
	|SELECT
	|	AdjustmentEntries.RecordType,
	|	AdjustmentEntries.Period,
	|	AdjustmentEntries.Recorder,
	|	AdjustmentEntries.ChartOfAccounts,
	|	AdjustmentEntries.Organization,
	|	AdjustmentEntries.Account,
	|	AdjustmentEntries.Department,
	|	AdjustmentEntries.LineOfBusiness,
	|	AdjustmentEntries.ExtDimensionType1,
	|	AdjustmentEntries.ExtDimension1,
	|	AdjustmentEntries.ExtDimensionType2,
	|	AdjustmentEntries.ExtDimension2,
	|	AdjustmentEntries.ExtDimensionType3,
	|	AdjustmentEntries.ExtDimension3,
	|	AdjustmentEntries.Currency,
	|	AdjustmentEntries.CurrencyAmount,
	|	AdjustmentEntries.Count,
	|	AdjustmentEntries.Sum,
	|	AdjustmentEntries.PresentationAmount,
	|	AdjustmentEntries.PostingTemplate,
	|	AdjustmentEntries.PostingType,
	|	""""
	|FROM
	|	AdjustmentEntries AS AdjustmentEntries
	|";
	
	Return QueryText;
	
EndFunction

Function TextOfRequestToCheckBanDate()
	
	QueryText = "
	|SELECT DISTINCT
	|	Companies.Ref AS Organization,
	|	CASE
	|		WHEN NOT DatesBannedByOrganization.PeriodEndClosingDate IS NULL 
	|			THEN ENDOFPERIOD(DatesBannedByOrganization.PeriodEndClosingDate, DAY)
	|		WHEN NOT DatesOfBanAreGeneral.PeriodEndClosingDate IS NULL 
	|			THEN ENDOFPERIOD(DatesOfBanAreGeneral.PeriodEndClosingDate, DAY)
	|		ELSE DATETIME(1, 1, 1)
	|	END AS PeriodEndClosingDate
	|INTO DatesBannedByOrganization_
	|FROM
	|	Catalog.Companies AS Companies
	|	LEFT JOIN InformationRegister.ClosingDatesOfFinancialAccountingPostingGeneration AS DatesBannedByOrganization
	|		ON Companies.Ref = DatesBannedByOrganization.Organization
	|	LEFT JOIN InformationRegister.ClosingDatesOfFinancialAccountingPostingGeneration AS DatesOfBanAreGeneral
	|		ON (DatesOfBanAreGeneral.Organization = VALUE(Catalog.Companies.EmptyRef))
	|WHERE
	|	CASE
	|		WHEN NOT DatesBannedByOrganization.PeriodEndClosingDate IS NULL 
	|			THEN ENDOFPERIOD(DatesBannedByOrganization.PeriodEndClosingDate, DAY)
	|		WHEN NOT DatesOfBanAreGeneral.PeriodEndClosingDate IS NULL 
	|			THEN ENDOFPERIOD(DatesOfBanAreGeneral.PeriodEndClosingDate, DAY)
	|		ELSE DATETIME(1, 1, 1)
	|	END <> DATETIME(1, 1, 1)
	|INDEX BY
	|	Organization,
	|	PeriodEndClosingDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RecruitmentPeriods.Period AS Period,
	|	RecruitmentPeriods.Organization AS Organization
	|INTO RecruitmentPeriods
	|FROM
	|	&RecruitmentPeriods AS RecruitmentPeriods
	|INDEX BY
	|	Period,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	AccountingRegister.InternationalWithoutCorrespondence AS OriginalPostings
	|	INNER JOIN DatesBannedByOrganization_ AS DatesBannedByOrganization_
	|		ON OriginalPostings.Organization = DatesBannedByOrganization_.Organization
	|		 AND OriginalPostings.Period <= DatesBannedByOrganization_.PeriodEndClosingDate
	|WHERE
	|	OriginalPostings.Recorder = &Document
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	RecruitmentPeriods AS RecruitmentPeriods
	|	INNER JOIN DatesBannedByOrganization_ AS DatesBannedByOrganization_
	|		ON RecruitmentPeriods.Organization = DatesBannedByOrganization_.Organization
	|		 AND RecruitmentPeriods.Period <= DatesBannedByOrganization_.PeriodEndClosingDate
	|";
	
	Return QueryText;
	
EndFunction

Function ThereIsNeedForFormationOfCorrectivePostings(Recorder, TempTablesManager)
	
	RecruitmentPeriods = ThisObject.Unload(, "Period,Organization");
	RecruitmentPeriods.GroupBy("Period,Organization");
	
	Query = New Query(TextOfRequestToCheckBanDate());
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Document", Recorder);
	Query.SetParameter("RecruitmentPeriods", RecruitmentPeriods);
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();
	
EndFunction

#EndRegion

#EndIf