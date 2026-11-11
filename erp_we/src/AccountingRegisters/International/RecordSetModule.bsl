
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the transaction subconto from the transmitted transaction data
//
// Parameters:
//  AccountingEntry - AccountingRegisterRecordAccountingRegisterName - the transaction that you want to fill out a subconto for
//  Data   - Structure - structure containing the data
//             of the subcontent structure key specifies the name of the transaction field - "Vidsubcontodt1, Subcontodt1...."
//             structure value corresponding to the value of the transaction field
//  RecordType - String- "Dt" or "CT".
//
Procedure InstallExtdimension(AccountingEntry, Data, RecordType) Export
	
	If RecordType = "Dr" Then
		Name_Account = "AccountDr";
		NameExtdimension = "ExtDimensionDr";
		ExtraDimensionTypeName = "ExtDimensionTypeDr";
	Else
		Name_Account = "AccountCr";
		NameExtdimension = "ExtDimensionCr";
		ExtraDimensionTypeName = "ExtDimensionTypeCr";
	EndIf;
	
	Account = AccountingEntry[Name_Account];
	AccountProperties = FinancialAccountingServerCached.AccountProperties(Account);
	For Number = 1 To AccountProperties.ExtDimensionCount Do
		ExtDimensionType = Data[ExtraDimensionTypeName + Number];
		If RecordType = "Dr" Then
			AccountingEntry.ExtDimensionsDr[ExtDimensionType] = Data[NameExtdimension + Number];
		Else
			AccountingEntry.ExtDimensionsCr[ExtDimensionType] = Data[NameExtdimension + Number];
		EndIf;
	EndDo;
	
EndProcedure

// Adds the transferred transaction to the current recordset
//
// Parameters:
//  AccountingEntry - AccountingRegisterRecord.International, Structure - transaction to add
//  ContentText - String - text of the transaction content.
//
Procedure AddTransaction(AccountingEntry, ContentText = "") Export
	
	NewEntry = ThisObject.Add();
	FillPropertyValues(NewEntry, AccountingEntry);
	If Not IsBlankString(ContentText) Then
		NewEntry.Content = ContentText;
	EndIf;
	For Each ExtDimension In AccountingEntry.ExtDimensionsDr Do
		NewEntry.ExtDimensionsDr[ExtDimension.Key] = ExtDimension.Value;
	EndDo;
	For Each ExtDimension In AccountingEntry.ExtDimensionsCr Do
		NewEntry.ExtDimensionsCr[ExtDimension.Key] = ExtDimension.Value;
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
	
	AccountingRegisters.International.PerformAdditionalProcessingOfTransactions(ThisObject);
	
	Recorder = ThisObject.Filter.Recorder.Value;
	TempTablesManager = New TempTablesManager();
	GenerateCorrectiveTransactions_ = ThereIsNeedForFormationOfCorrectivePostings(Recorder, TempTablesManager);
	Text = NStr("vi = 'Đặt ngày cấm thay đổi bút toán theo kế toán quốc tế.
				|Việc hủy bỏ kết chuyển chuyển từ bị cấm.';
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
				+ NStr("vi = 'Được phép sửa các bút toán của chứng từ ""Giao dịch thủ công (kế toán quốc tế)"" trong kỳ đóng đối với kế toán quốc tế 
				|chỉ cho phép khi đánh dấu tích vào hộp kiểm ""Nhập ngày vào dòng"" trên thẻ ""Chung"".';
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
		InstallExtdimension(NewEntry, Selection, "Dr");
		InstallExtdimension(NewEntry, Selection, "Cr");
	EndDo;
	
EndProcedure

Function TextOfRequestForCorrectiveTransactions()
	
	QueryText = "
	|SELECT
	|	RecordsSet.Period,
	|	RecordsSet.Recorder,
	|	RecordsSet.ChartOfAccounts,
	|	RecordsSet.Organization,
	|	RecordsSet.AccountDr,
	|	RecordsSet.DepartmentDr,
	|	RecordsSet.LineOfBusinessDr,
	|	RecordsSet.ExtDimensionTypeDr1,
	|	RecordsSet.ExtDimensionDr1,
	|	RecordsSet.ExtDimensionTypeDr2,
	|	RecordsSet.ExtDimensionDr2,
	|	RecordsSet.ExtDimensionTypeDr3,
	|	RecordsSet.ExtDimensionDr3,
	|	RecordsSet.CurrencyDr,
	|	RecordsSet.CurrencyAmountDr,
	|	RecordsSet.CountDr,
	|	RecordsSet.AccountCr,
	|	RecordsSet.DepartmentCr,
	|	RecordsSet.LineOfBusinessCr,
	|	RecordsSet.ExtDimensionTypeCr1,
	|	RecordsSet.ExtDimensionCr1,
	|	RecordsSet.ExtDimensionTypeCr2,
	|	RecordsSet.ExtDimensionCr2,
	|	RecordsSet.ExtDimensionTypeCr3,
	|	RecordsSet.ExtDimensionCr3,
	|	RecordsSet.CurrencyCr,
	|	RecordsSet.CurrencyAmountCr,
	|	RecordsSet.CountCr,
	|	RecordsSet.Sum,
	|	RecordsSet.PresentationAmount,
	|	RecordsSet.PostingTemplate
	|INTO RecordsSet
	|FROM
	|	&RecordsSet AS RecordsSet
	|INDEX BY
	|	AccountDr,
	|	AccountCr
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RecordsSet.AccountDr AS Account
	|INTO SetAccounts
	|FROM
	|	RecordsSet AS RecordsSet
	|
	|UNION
	|
	|SELECT DISTINCT
	|	RecordsSet.AccountCr AS Account
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
	|	RecordsSet.Period,
	|	RecordsSet.Recorder,
	|	RecordsSet.ChartOfAccounts,
	|	RecordsSet.Organization,
	|	RecordsSet.AccountDr,
	|	RecordsSet.DepartmentDr,
	|	RecordsSet.LineOfBusinessDr,
	|	ISNULL(ExtdimensionOfAccountsDr1.ExtDimensionType, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeDr1,
	|	CASE
	|		WHEN ExtdimensionOfAccountsDr1.ExtDimensionType = RecordsSet.ExtDimensionTypeDr1
	|			THEN RecordsSet.ExtDimensionDr1
	|		WHEN ExtdimensionOfAccountsDr1.ExtDimensionType = RecordsSet.ExtDimensionTypeDr2
	|			THEN RecordsSet.ExtDimensionDr2
	|		WHEN ExtdimensionOfAccountsDr1.ExtDimensionType = RecordsSet.ExtDimensionTypeDr3
	|			THEN RecordsSet.ExtDimensionDr3
	|		ELSE UNDEFINED
	|	END AS ExtDimensionDr1,
	|	ISNULL(ExtdimensionOfAccountsDr2.ExtDimensionType, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeDr2,
	|	CASE
	|		WHEN ExtdimensionOfAccountsDr2.ExtDimensionType = RecordsSet.ExtDimensionTypeDr1
	|			THEN RecordsSet.ExtDimensionDr1
	|		WHEN ExtdimensionOfAccountsDr2.ExtDimensionType = RecordsSet.ExtDimensionTypeDr2
	|			THEN RecordsSet.ExtDimensionDr2
	|		WHEN ExtdimensionOfAccountsDr2.ExtDimensionType = RecordsSet.ExtDimensionTypeDr3
	|			THEN RecordsSet.ExtDimensionDr3
	|		ELSE UNDEFINED
	|	END AS ExtDimensionDr2,
	|	ISNULL(ExtdimensionOfAccountsDr3.ExtDimensionType, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeDr3,
	|	CASE
	|		WHEN ExtdimensionOfAccountsDr3.ExtDimensionType = RecordsSet.ExtDimensionTypeDr1
	|			THEN RecordsSet.ExtDimensionDr1
	|		WHEN ExtdimensionOfAccountsDr3.ExtDimensionType = RecordsSet.ExtDimensionTypeDr2
	|			THEN RecordsSet.ExtDimensionDr2
	|		WHEN ExtdimensionOfAccountsDr3.ExtDimensionType = RecordsSet.ExtDimensionTypeDr3
	|			THEN RecordsSet.ExtDimensionDr3
	|		ELSE UNDEFINED
	|	END AS ExtDimensionDr3,
	|	RecordsSet.CurrencyDr,
	|	RecordsSet.CurrencyAmountDr,
	|	RecordsSet.CountDr,
	|	RecordsSet.AccountCr,
	|	RecordsSet.DepartmentCr,
	|	RecordsSet.LineOfBusinessCr,
	|	ISNULL(ExtdimensionOfAccountsCr1.ExtDimensionType, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeCr1,
	|	CASE
	|		WHEN ExtdimensionOfAccountsCr1.ExtDimensionType = RecordsSet.ExtDimensionTypeCr1
	|			THEN RecordsSet.ExtDimensionCr1
	|		WHEN ExtdimensionOfAccountsCr1.ExtDimensionType = RecordsSet.ExtDimensionTypeCr2
	|			THEN RecordsSet.ExtDimensionCr2
	|		WHEN ExtdimensionOfAccountsCr1.ExtDimensionType = RecordsSet.ExtDimensionTypeCr3
	|			THEN RecordsSet.ExtDimensionCr3
	|		ELSE UNDEFINED
	|	END AS ExtDimensionCr1,
	|	ISNULL(ExtdimensionOfAccountsCr2.ExtDimensionType, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeCr2,
	|	CASE
	|		WHEN ExtdimensionOfAccountsCr2.ExtDimensionType = RecordsSet.ExtDimensionTypeCr1
	|			THEN RecordsSet.ExtDimensionCr1
	|		WHEN ExtdimensionOfAccountsCr2.ExtDimensionType = RecordsSet.ExtDimensionTypeCr2
	|			THEN RecordsSet.ExtDimensionCr2
	|		WHEN ExtdimensionOfAccountsCr2.ExtDimensionType = RecordsSet.ExtDimensionTypeCr3
	|			THEN RecordsSet.ExtDimensionCr3
	|		ELSE UNDEFINED
	|	END AS ExtDimensionCr2,
	|	ISNULL(ExtdimensionOfAccountsCr3.ExtDimensionType, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeCr3,
	|	CASE
	|		WHEN ExtdimensionOfAccountsCr3.ExtDimensionType = RecordsSet.ExtDimensionTypeCr1
	|			THEN RecordsSet.ExtDimensionCr1
	|		WHEN ExtdimensionOfAccountsCr3.ExtDimensionType = RecordsSet.ExtDimensionTypeCr2
	|			THEN RecordsSet.ExtDimensionCr2
	|		WHEN ExtdimensionOfAccountsCr3.ExtDimensionType = RecordsSet.ExtDimensionTypeCr3
	|			THEN RecordsSet.ExtDimensionCr3
	|		ELSE UNDEFINED
	|	END AS ExtDimensionCr3,
	|	RecordsSet.CurrencyCr,
	|	RecordsSet.CurrencyAmountCr,
	|	RecordsSet.CountCr,
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
	|	LEFT JOIN ExtdimensionOfAccounts AS ExtdimensionOfAccountsDr1
	|		ON RecordsSet.AccountDr = ExtdimensionOfAccountsDr1.Account
	|		 AND ExtdimensionOfAccountsDr1.ExtDimensionNumber = 1
	|	LEFT JOIN ExtdimensionOfAccounts AS ExtdimensionOfAccountsDr2
	|		ON RecordsSet.AccountDr = ExtdimensionOfAccountsDr2.Account
	|		 AND ExtdimensionOfAccountsDr2.ExtDimensionNumber = 2
	|	LEFT JOIN ExtdimensionOfAccounts AS ExtdimensionOfAccountsDr3
	|		ON RecordsSet.AccountDr = ExtdimensionOfAccountsDr3.Account
	|		 AND ExtdimensionOfAccountsDr3.ExtDimensionNumber = 3
	|	LEFT JOIN ExtdimensionOfAccounts AS ExtdimensionOfAccountsCr1
	|		ON RecordsSet.AccountCr = ExtdimensionOfAccountsCr1.Account
	|		 AND ExtdimensionOfAccountsCr1.ExtDimensionNumber = 1
	|	LEFT JOIN ExtdimensionOfAccounts AS ExtdimensionOfAccountsCr2
	|		ON RecordsSet.AccountCr = ExtdimensionOfAccountsCr2.Account
	|		 AND ExtdimensionOfAccountsCr2.ExtDimensionNumber = 2
	|	LEFT JOIN ExtdimensionOfAccounts AS ExtdimensionOfAccountsCr3
	|		ON RecordsSet.AccountCr = ExtdimensionOfAccountsCr3.Account
	|		 AND ExtdimensionOfAccountsCr3.ExtDimensionNumber = 3
	|	LEFT JOIN DatesBannedByOrganization_ AS DatesBannedByOrganization_
	|		ON RecordsSet.Organization = DatesBannedByOrganization_.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OriginalPostings.Period,
	|	OriginalPostings.Recorder,
	|	OriginalPostings.ChartOfAccounts,
	|	OriginalPostings.Organization,
	|	OriginalPostings.AccountDr,
	|	ISNULL(OriginalPostings.DepartmentDr, VALUE(Catalog.BusinessStructure.EmptyRef)) AS DepartmentDr,
	|	ISNULL(OriginalPostings.LineOfBusinessDr, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusinessDr,
	|	ISNULL(OriginalPostings.ExtDimensionTypeDr1, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeDr1,
	|	ISNULL(OriginalPostings.ExtDimensionDr1, UNDEFINED) AS ExtDimensionDr1,
	|	ISNULL(OriginalPostings.ExtDimensionTypeDr2, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeDr2,
	|	ISNULL(OriginalPostings.ExtDimensionDr2, UNDEFINED) AS ExtDimensionDr2,
	|	ISNULL(OriginalPostings.ExtDimensionTypeDr3, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeDr3,
	|	ISNULL(OriginalPostings.ExtDimensionDr3, UNDEFINED) AS ExtDimensionDr3,
	|	ISNULL(OriginalPostings.CurrencyDr, VALUE(Catalog.Currencies.EmptyRef)) AS CurrencyDr,
	|	ISNULL(OriginalPostings.CurrencyAmountDr, 0) AS CurrencyAmountDr,
	|	ISNULL(OriginalPostings.CountDr, 0) AS CountDr,
	|	OriginalPostings.AccountCr,
	|	ISNULL(OriginalPostings.DepartmentCr, VALUE(Catalog.BusinessStructure.EmptyRef)) AS DepartmentCr,
	|	ISNULL(OriginalPostings.LineOfBusinessCr, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusinessCr,
	|	ISNULL(OriginalPostings.ExtDimensionTypeCr1, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeCr1,
	|	ISNULL(OriginalPostings.ExtDimensionCr1, UNDEFINED) AS ExtDimensionCr1,
	|	ISNULL(OriginalPostings.ExtDimensionTypeCr2, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeCr2,
	|	ISNULL(OriginalPostings.ExtDimensionCr2, UNDEFINED) AS ExtDimensionCr2,
	|	ISNULL(OriginalPostings.ExtDimensionTypeCr3, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeCr3,
	|	ISNULL(OriginalPostings.ExtDimensionCr3, UNDEFINED) AS ExtDimensionCr3,
	|	ISNULL(OriginalPostings.CurrencyCr, VALUE(Catalog.Currencies.EmptyRef)) AS CurrencyCr,
	|	ISNULL(OriginalPostings.CurrencyAmountCr, 0) AS CurrencyAmountCr,
	|	ISNULL(OriginalPostings.CountCr, 0) AS CountCr,
	|	OriginalPostings.Sum,
	|	OriginalPostings.PresentationAmount,
	|	OriginalPostings.PostingTemplate,
	|	OriginalPostings.PostingType,
	|	OriginalPostings.Content,
	|	DATEADD(DatesBannedByOrganization_.PeriodEndClosingDate, SECOND, 1) AS AdjustmentPeriod_
	|INTO OriginalPostings
	|FROM
	|	AccountingRegister.International.RecordsWithExtDimensions(, , Recorder IN (&Document), , ) AS OriginalPostings
	|	INNER JOIN DatesBannedByOrganization_ AS DatesBannedByOrganization_
	|		ON OriginalPostings.Organization = DatesBannedByOrganization_.Organization
	|			AND OriginalPostings.Period <= DatesBannedByOrganization_.PeriodEndClosingDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Period,
	|	NestedQuery.Recorder,
	|	NestedQuery.ChartOfAccounts,
	|	NestedQuery.Organization,
	|	NestedQuery.AccountDr,
	|	NestedQuery.DepartmentDr,
	|	NestedQuery.LineOfBusinessDr,
	|	NestedQuery.ExtDimensionTypeDr1,
	|	NestedQuery.ExtDimensionDr1,
	|	NestedQuery.ExtDimensionTypeDr2,
	|	NestedQuery.ExtDimensionDr2,
	|	NestedQuery.ExtDimensionTypeDr3,
	|	NestedQuery.ExtDimensionDr3,
	|	NestedQuery.CurrencyDr,
	|	NestedQuery.AccountCr,
	|	NestedQuery.DepartmentCr,
	|	NestedQuery.LineOfBusinessCr,
	|	NestedQuery.ExtDimensionTypeCr1,
	|	NestedQuery.ExtDimensionCr1,
	|	NestedQuery.ExtDimensionTypeCr2,
	|	NestedQuery.ExtDimensionCr2,
	|	NestedQuery.ExtDimensionTypeCr3,
	|	NestedQuery.ExtDimensionCr3,
	|	NestedQuery.CurrencyCr,
	|	SUM(NestedQuery.CurrencyAmountDr) AS CurrencyAmountDr,
	|	SUM(NestedQuery.CurrencyAmountCr) AS CurrencyAmountCr,
	|	SUM(NestedQuery.CountDr) AS CountDr,
	|	SUM(NestedQuery.CountCr) AS CountCr,
	|	SUM(NestedQuery.Sum) AS Sum,
	|	SUM(NestedQuery.PresentationAmount) AS PresentationAmount,
	|	NestedQuery.PostingTemplate AS PostingTemplate,
	|	VALUE(Enum.PostingTypesFinancialAccounting.Adjusting) AS PostingType
	|INTO AdjustmentEntries
	|FROM
	|	(SELECT
	|		PostingsStorno.AdjustmentPeriod_ AS Period,
	|		PostingsStorno.Recorder AS Recorder,
	|		PostingsStorno.ChartOfAccounts AS ChartOfAccounts,
	|		PostingsStorno.Organization AS Organization,
	|		PostingsStorno.AccountDr AS AccountDr,
	|		PostingsStorno.DepartmentDr AS DepartmentDr,
	|		PostingsStorno.LineOfBusinessDr AS LineOfBusinessDr,
	|		PostingsStorno.ExtDimensionTypeDr1 AS ExtDimensionTypeDr1,
	|		PostingsStorno.ExtDimensionDr1 AS ExtDimensionDr1,
	|		PostingsStorno.ExtDimensionTypeDr2 AS ExtDimensionTypeDr2,
	|		PostingsStorno.ExtDimensionDr2 AS ExtDimensionDr2,
	|		PostingsStorno.ExtDimensionTypeDr3 AS ExtDimensionTypeDr3,
	|		PostingsStorno.ExtDimensionDr3 AS ExtDimensionDr3,
	|		PostingsStorno.CurrencyDr AS CurrencyDr,
	|		PostingsStorno.AccountCr AS AccountCr,
	|		PostingsStorno.DepartmentCr AS DepartmentCr,
	|		PostingsStorno.LineOfBusinessCr AS LineOfBusinessCr,
	|		PostingsStorno.ExtDimensionTypeCr1 AS ExtDimensionTypeCr1,
	|		PostingsStorno.ExtDimensionCr1 AS ExtDimensionCr1,
	|		PostingsStorno.ExtDimensionTypeCr2 AS ExtDimensionTypeCr2,
	|		PostingsStorno.ExtDimensionCr2 AS ExtDimensionCr2,
	|		PostingsStorno.ExtDimensionTypeCr3 AS ExtDimensionTypeCr3,
	|		PostingsStorno.ExtDimensionCr3 AS ExtDimensionCr3,
	|		PostingsStorno.CurrencyCr AS CurrencyCr,
	|		-PostingsStorno.CurrencyAmountDr AS CurrencyAmountDr,
	|		-PostingsStorno.CurrencyAmountCr AS CurrencyAmountCr,
	|		-PostingsStorno.CountDr AS CountDr,
	|		-PostingsStorno.CountCr AS CountCr,
	|		-PostingsStorno.Sum AS Sum,
	|		-PostingsStorno.PresentationAmount AS PresentationAmount,
	|		PostingsStorno.PostingTemplate AS PostingTemplate
	|	FROM
	|		OriginalPostings AS PostingsStorno
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NewTransactions.AdjustmentPeriod_,
	|		NewTransactions.Recorder,
	|		NewTransactions.ChartOfAccounts,
	|		NewTransactions.Organization,
	|		NewTransactions.AccountDr,
	|		NewTransactions.DepartmentDr,
	|		NewTransactions.LineOfBusinessDr,
	|		NewTransactions.ExtDimensionTypeDr1,
	|		NewTransactions.ExtDimensionDr1,
	|		NewTransactions.ExtDimensionTypeDr2,
	|		NewTransactions.ExtDimensionDr2,
	|		NewTransactions.ExtDimensionTypeDr3,
	|		NewTransactions.ExtDimensionDr3,
	|		NewTransactions.CurrencyDr,
	|		NewTransactions.AccountCr,
	|		NewTransactions.DepartmentCr,
	|		NewTransactions.LineOfBusinessCr,
	|		NewTransactions.ExtDimensionTypeCr1,
	|		NewTransactions.ExtDimensionCr1,
	|		NewTransactions.ExtDimensionTypeCr2,
	|		NewTransactions.ExtDimensionCr2,
	|		NewTransactions.ExtDimensionTypeCr3,
	|		NewTransactions.ExtDimensionCr3,
	|		NewTransactions.CurrencyCr,
	|		NewTransactions.CurrencyAmountDr,
	|		NewTransactions.CurrencyAmountCr,
	|		NewTransactions.CountDr,
	|		NewTransactions.CountCr,
	|		NewTransactions.Sum,
	|		NewTransactions.PresentationAmount,
	|		NewTransactions.PostingTemplate
	|	FROM
	|		NewTransactions AS NewTransactions) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Period,
	|	NestedQuery.Recorder,
	|	NestedQuery.ChartOfAccounts,
	|	NestedQuery.Organization,
	|	NestedQuery.AccountDr,
	|	NestedQuery.DepartmentDr,
	|	NestedQuery.LineOfBusinessDr,
	|	NestedQuery.ExtDimensionTypeDr1,
	|	NestedQuery.ExtDimensionDr1,
	|	NestedQuery.ExtDimensionTypeDr2,
	|	NestedQuery.ExtDimensionDr2,
	|	NestedQuery.ExtDimensionTypeDr3,
	|	NestedQuery.ExtDimensionDr3,
	|	NestedQuery.CurrencyDr,
	|	NestedQuery.AccountCr,
	|	NestedQuery.DepartmentCr,
	|	NestedQuery.LineOfBusinessCr,
	|	NestedQuery.ExtDimensionTypeCr1,
	|	NestedQuery.ExtDimensionCr1,
	|	NestedQuery.ExtDimensionTypeCr2,
	|	NestedQuery.ExtDimensionCr2,
	|	NestedQuery.ExtDimensionTypeCr3,
	|	NestedQuery.ExtDimensionCr3,
	|	NestedQuery.CurrencyCr,
	|	NestedQuery.PostingTemplate
	|
	|HAVING
	|	SUM(NestedQuery.Sum) <> 0
	|	OR SUM(NestedQuery.CurrencyAmountDr) <> 0
	|	OR SUM(NestedQuery.CurrencyAmountCr) <> 0
	|	OR SUM(NestedQuery.CountDr) <> 0
	|	OR SUM(NestedQuery.CountCr) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OriginalPostings.Period,
	|	OriginalPostings.Recorder,
	|	OriginalPostings.ChartOfAccounts,
	|	OriginalPostings.Organization,
	|	OriginalPostings.AccountDr,
	|	OriginalPostings.DepartmentDr,
	|	OriginalPostings.LineOfBusinessDr,
	|	OriginalPostings.ExtDimensionTypeDr1,
	|	OriginalPostings.ExtDimensionDr1,
	|	OriginalPostings.ExtDimensionTypeDr2,
	|	OriginalPostings.ExtDimensionDr2,
	|	OriginalPostings.ExtDimensionTypeDr3,
	|	OriginalPostings.ExtDimensionDr3,
	|	OriginalPostings.AccountCr,
	|	OriginalPostings.DepartmentCr,
	|	OriginalPostings.LineOfBusinessCr,
	|	OriginalPostings.ExtDimensionTypeCr1,
	|	OriginalPostings.ExtDimensionCr1,
	|	OriginalPostings.ExtDimensionTypeCr2,
	|	OriginalPostings.ExtDimensionCr2,
	|	OriginalPostings.ExtDimensionTypeCr3,
	|	OriginalPostings.ExtDimensionCr3,
	|	OriginalPostings.CurrencyDr,
	|	OriginalPostings.CurrencyCr,
	|	OriginalPostings.CurrencyAmountDr,
	|	OriginalPostings.CurrencyAmountCr,
	|	OriginalPostings.CountDr,
	|	OriginalPostings.CountCr,
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
	|	AdjustmentEntries.Period,
	|	AdjustmentEntries.Recorder,
	|	AdjustmentEntries.ChartOfAccounts,
	|	AdjustmentEntries.Organization,
	|	AdjustmentEntries.AccountDr,
	|	AdjustmentEntries.DepartmentDr,
	|	AdjustmentEntries.LineOfBusinessDr,
	|	AdjustmentEntries.ExtDimensionTypeDr1,
	|	AdjustmentEntries.ExtDimensionDr1,
	|	AdjustmentEntries.ExtDimensionTypeDr2,
	|	AdjustmentEntries.ExtDimensionDr2,
	|	AdjustmentEntries.ExtDimensionTypeDr3,
	|	AdjustmentEntries.ExtDimensionDr3,
	|	AdjustmentEntries.AccountCr,
	|	AdjustmentEntries.DepartmentCr,
	|	AdjustmentEntries.LineOfBusinessCr,
	|	AdjustmentEntries.ExtDimensionTypeCr1,
	|	AdjustmentEntries.ExtDimensionCr1,
	|	AdjustmentEntries.ExtDimensionTypeCr2,
	|	AdjustmentEntries.ExtDimensionCr2,
	|	AdjustmentEntries.ExtDimensionTypeCr3,
	|	AdjustmentEntries.ExtDimensionCr3,
	|	AdjustmentEntries.CurrencyDr,
	|	AdjustmentEntries.CurrencyCr,
	|	AdjustmentEntries.CurrencyAmountDr,
	|	AdjustmentEntries.CurrencyAmountCr,
	|	AdjustmentEntries.CountDr,
	|	AdjustmentEntries.CountCr,
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
	|	AccountingRegister.International AS OriginalPostings
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