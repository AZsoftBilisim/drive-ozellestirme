//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not ValueIsFilled(Parameters.Organization)
	 Or Not ValueIsFilled(Parameters.Counterparty) Then
		
		Cancel = True;
		Return;
		
	EndIf;
	
	SetConditionalAppearance();
	
	Organization = Parameters.Organization;
	Counterparty = Parameters.Counterparty;
	UpdateDate = Parameters.UpdateDate;
	If ValueIsFilled(Parameters.Currency) Then
		
		DocumentCurrency = Parameters.Currency;
		
	EndIf;
	
	If ValueIsFilled(Parameters.AddressOfTableOfSelectedRows) Then
		
		AddressInStorage = Parameters.AddressOfTableOfSelectedRows;
		SelectedLines_ = GetFromTempStorage(AddressInStorage); // ValueTable
		DeleteFromTempStorage(AddressInStorage);
		BalanceOfRebates.Load(SelectedLines_);
		
	EndIf;
	
	DataIsStoredInTableOfValues();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectAllCommand(Command)
	
	For Each LineNumber In Items.BalanceOfRebates.SelectedRows Do // Number
		
		RemainderLine_ = BalanceOfRebates.FindByID(LineNumber);
		
		If Not RemainderLine_.DocumentSelected Then
			
			RemainderLine_.DocumentSelected = True;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearAll(Command)
	
	For Each LineNumber In Items.BalanceOfRebates.SelectedRows Do // Number
		
		RemainderLine_ = BalanceOfRebates.FindByID(LineNumber);
		
		If RemainderLine_.DocumentSelected Then
			
			RemainderLine_.DocumentSelected = False;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure TableOfBalancesOfRBPerformValueSelection(Command)
	
	ClearMessages();
	
	Filter = New Structure;
	Filter.Insert("DocumentSelected", True);
	FoundRows = BalanceOfRebates.FindRows(Filter);
	If FoundRows.Count() > 0 Then
		
		AddressInStorage = AddressOfResultInRepository();
		Close(AddressInStorage);
		
	Else
		
		PerformValueSelectionWithQuestion();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BalanceOfRebates.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BalanceOfRebates.DocumentSelected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	
EndProcedure

&AtClient
Async Procedure PerformValueSelectionWithQuestion()
	
	QueryText = NStr("vi = 'Chưa chọn dòng nào. Tiếp tục?';
					|ru = 'Не выбрано ни одной строки. Продолжить?';
					|en = 'No line is selected. Continue?'; fa = 'No line is selected. Continue?';
					|it = 'Не выбрано ни одной строки. Продолжить?';
					|pl = 'No line is selected. Continue?';
					|tr = 'Hiçbir satır seçilmemiş. Devam mi?'");
	Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
	
	If Response = DialogReturnCode.Yes Then
		
		AddressInStorage = AddressOfResultInRepository();
		Close(AddressInStorage);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DataIsStoredInTableOfValues()
	
	Boundary =  New Boundary(EndOfDay(UpdateDate), BoundaryType.Including);
	RowsCount = BalanceOfRebates.Count();
	
	QueryText =
	"SELECT
	|	BalancesSelected.Currency AS Currency,
	|	BalancesSelected.LineNumber AS LineNumber,
	|	BalancesSelected.DocumentSelected AS DocumentSelected,
	|	BalancesSelected.TermDocument AS TermDocument,
	|	BalancesSelected.Contract AS Contract,
	|	BalancesSelected.BeginOfPeriod AS BeginOfPeriod,
	|	BalancesSelected.PeriodEnding AS PeriodEnding,
	|	BalancesSelected.Partner AS Partner
	|INTO TT_BalancesSelected
	|FROM
	|	&BalanceOfRebates AS BalancesSelected
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VendorRebatesTurnovers.Partner AS Partner,
	|	VendorRebatesTurnovers.Contract AS Contract,
	|	VendorRebatesTurnovers.TermDocument AS TermDocument,
	|	VendorRebatesTurnovers.BeginOfPeriod AS BeginOfPeriod,
	|	VendorRebatesTurnovers.PeriodEnding AS PeriodEnding,
	|	VendorRebatesTurnovers.Currency AS Currency,
	|	SUM(CASE
	|			WHEN VendorRebatesTurnovers.TypeOfRegisterMovement = VALUE(Enum.AccumulationRecordTypes.Receipt)
	|				THEN VendorRebatesTurnovers.AccruedTurnover
	|			ELSE -VendorRebatesTurnovers.ToWriteOffTurnover - VendorRebatesTurnovers.WrittenOffTurnover - VendorRebatesTurnovers.CertifiedTurnover
	|		END) AS Sum
	|INTO TT_BalancesAtEnd
	|FROM
	|	AccumulationRegister.VendorRebates.Turnovers(
	|			,
	|			,
	|			,
	|			Organization = &Organization
	|				AND Counterparty = &Counterparty
	|				AND TermDocument <> VALUE(Document.ConditionsOfVendorRebates.EmptyRef)
	|				AND &ConditionCurrency) AS VendorRebatesTurnovers
	|
	|GROUP BY
	|	VendorRebatesTurnovers.Partner,
	|	VendorRebatesTurnovers.Contract,
	|	VendorRebatesTurnovers.TermDocument,
	|	VendorRebatesTurnovers.BeginOfPeriod,
	|	VendorRebatesTurnovers.PeriodEnding,
	|	VendorRebatesTurnovers.Currency,
	|	VendorRebatesTurnovers.Organization,
	|	VendorRebatesTurnovers.Counterparty
	|
	|HAVING
	|	SUM(CASE
	|			WHEN VendorRebatesTurnovers.TypeOfRegisterMovement = VALUE(Enum.AccumulationRecordTypes.Receipt)
	|				THEN VendorRebatesTurnovers.AccruedTurnover
	|			ELSE -VendorRebatesTurnovers.ToWriteOffTurnover - VendorRebatesTurnovers.WrittenOffTurnover - VendorRebatesTurnovers.CertifiedTurnover
	|		END) > 0
	|
	|INDEX BY
	|	Partner,
	|	Contract,
	|	TermDocument,
	|	BeginOfPeriod,
	|	PeriodEnding,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VendorRebatesTurnovers.Partner AS Partner,
	|	VendorRebatesTurnovers.Contract AS Contract,
	|	VendorRebatesTurnovers.TermDocument AS TermDocument,
	|	VendorRebatesTurnovers.BeginOfPeriod AS BeginOfPeriod,
	|	VendorRebatesTurnovers.PeriodEnding AS PeriodEnding,
	|	VendorRebatesTurnovers.Currency AS Currency,
	|	SUM(CASE
	|			WHEN VendorRebatesTurnovers.TypeOfRegisterMovement = VALUE(Enum.AccumulationRecordTypes.Receipt)
	|				THEN VendorRebatesTurnovers.AccruedTurnover
	|			ELSE -VendorRebatesTurnovers.ToWriteOffTurnover - VendorRebatesTurnovers.WrittenOffTurnover - VendorRebatesTurnovers.CertifiedTurnover
	|		END) AS Sum
	|INTO VT_BalancesDate
	|FROM
	|	AccumulationRegister.VendorRebates.Turnovers(
	|			,
	|			&BoundaryOfRelevance,
	|			,
	|			Organization = &Organization
	|				AND Counterparty = &Counterparty
	|				AND (TermDocument, Contract, Partner, BeginOfPeriod, PeriodEnding, Currency) IN
	|					(SELECT
	|						TT_BalancesAtEnd.TermDocument,
	|						TT_BalancesAtEnd.Contract,
	|						TT_BalancesAtEnd.Partner,
	|						TT_BalancesAtEnd.BeginOfPeriod,
	|						TT_BalancesAtEnd.PeriodEnding,
	|						TT_BalancesAtEnd.Currency
	|					FROM
	|						TT_BalancesAtEnd AS TT_BalancesAtEnd)) AS VendorRebatesTurnovers
	|
	|GROUP BY
	|	VendorRebatesTurnovers.Partner,
	|	VendorRebatesTurnovers.Contract,
	|	VendorRebatesTurnovers.BeginOfPeriod,
	|	VendorRebatesTurnovers.PeriodEnding,
	|	VendorRebatesTurnovers.TermDocument,
	|	VendorRebatesTurnovers.Currency
	|
	|HAVING
	|	SUM(CASE
	|			WHEN VendorRebatesTurnovers.TypeOfRegisterMovement = VALUE(Enum.AccumulationRecordTypes.Receipt)
	|				THEN VendorRebatesTurnovers.AccruedTurnover
	|			ELSE -VendorRebatesTurnovers.ToWriteOffTurnover - VendorRebatesTurnovers.WrittenOffTurnover - VendorRebatesTurnovers.CertifiedTurnover
	|		END) > 0
	|
	|INDEX BY
	|	Partner,
	|	Contract,
	|	BeginOfPeriod,
	|	PeriodEnding,
	|	TermDocument,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VT_BalancesDate.Partner AS Partner,
	|	VT_BalancesDate.Contract AS Contract,
	|	VT_BalancesDate.TermDocument AS TermDocument,
	|	VT_BalancesDate.BeginOfPeriod AS BeginOfPeriod,
	|	VT_BalancesDate.PeriodEnding AS PeriodEnding,
	|	VT_BalancesDate.Currency AS Currency,
	|	CASE
	|		WHEN VT_BalancesDate.Sum > TT_BalancesAtEnd.Sum
	|			THEN TT_BalancesAtEnd.Sum
	|		ELSE VT_BalancesDate.Sum
	|	END AS Sum
	|INTO TT_Balance
	|FROM
	|	VT_BalancesDate AS VT_BalancesDate
	|		INNER JOIN TT_BalancesAtEnd AS TT_BalancesAtEnd
	|		ON VT_BalancesDate.Partner = TT_BalancesAtEnd.Partner
	|			AND VT_BalancesDate.Contract = TT_BalancesAtEnd.Contract
	|			AND VT_BalancesDate.BeginOfPeriod = TT_BalancesAtEnd.BeginOfPeriod
	|			AND VT_BalancesDate.PeriodEnding = TT_BalancesAtEnd.PeriodEnding
	|			AND VT_BalancesDate.TermDocument = TT_BalancesAtEnd.TermDocument
	|			AND VT_BalancesDate.Currency = TT_BalancesAtEnd.Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(TT_BalancesSelected.DocumentSelected, FALSE) AS DocumentSelected,
	|	ISNULL(TT_BalancesSelected.LineNumber, &RowsCount) AS LineNumber,
	|	ISNULL(RebatesTermsAndConditions.Kind, VALUE(Catalog.CustomerRebatesKinds.EmptyRef)) AS RebateKind,
	|	ISNULL(RebatesTermsAndConditions.BonusType, VALUE(Enum.VendorRebateTypes.EmptyRef)) AS BonusType,
	|	ISNULL(RebatesTermsAndConditions.LongDesc, """") AS LongDesc,
	|	BonusBalances.Partner AS Partner,
	|	BonusBalances.Contract AS Contract,
	|	BonusBalances.BeginOfPeriod AS BeginOfPeriod,
	|	BonusBalances.PeriodEnding AS PeriodEnding,
	|	BonusBalances.TermDocument AS TermDocument,
	|	BonusBalances.Currency AS Currency,
	|	BonusBalances.Sum AS Sum
	|INTO VT_Preparation
	|FROM
	|	TT_Balance AS BonusBalances
	|		LEFT JOIN TT_BalancesSelected AS TT_BalancesSelected
	|		ON BonusBalances.Partner = TT_BalancesSelected.Partner
	|			AND BonusBalances.Contract = TT_BalancesSelected.Contract
	|			AND BonusBalances.Currency = TT_BalancesSelected.Currency
	|			AND BonusBalances.TermDocument = TT_BalancesSelected.TermDocument
	|			AND BonusBalances.BeginOfPeriod = TT_BalancesSelected.BeginOfPeriod
	|			AND BonusBalances.PeriodEnding = TT_BalancesSelected.PeriodEnding
	|		LEFT JOIN InformationRegister.VendorRebatesConditions AS RebatesTermsAndConditions
	|		ON BonusBalances.TermDocument = RebatesTermsAndConditions.TermDocument
	|		LEFT JOIN InformationRegister.CompletedConditionsOfVendorRebates AS CompletedConditionsOfVendorRebates
	|		ON BonusBalances.TermDocument = CompletedConditionsOfVendorRebates.TermDocument
	|WHERE
	|	NOT ISNULL(CompletedConditionsOfVendorRebates.Completed, FALSE)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(VT_Preparation.DocumentSelected) AS DocumentSelected,
	|	MIN(VT_Preparation.LineNumber) AS LineNumber,
	|	VT_Preparation.RebateKind AS RebateKind,
	|	VT_Preparation.BonusType AS BonusType,
	|	VT_Preparation.LongDesc AS LongDesc,
	|	VT_Preparation.Partner AS Partner,
	|	VT_Preparation.Contract AS Contract,
	|	VT_Preparation.BeginOfPeriod AS BeginOfPeriod,
	|	VT_Preparation.PeriodEnding AS PeriodEnding,
	|	VT_Preparation.TermDocument AS TermDocument,
	|	VT_Preparation.Currency AS Currency,
	|	VT_Preparation.Sum AS Sum
	|FROM
	|	VT_Preparation AS VT_Preparation
	|
	|GROUP BY
	|	VT_Preparation.RebateKind,
	|	VT_Preparation.BonusType,
	|	VT_Preparation.LongDesc,
	|	VT_Preparation.Partner,
	|	VT_Preparation.Contract,
	|	VT_Preparation.BeginOfPeriod,
	|	VT_Preparation.PeriodEnding,
	|	VT_Preparation.TermDocument,
	|	VT_Preparation.Currency,
	|	VT_Preparation.Sum
	|
	|ORDER BY
	|	DocumentSelected DESC,
	|	LineNumber";
	
	If ValueIsFilled(DocumentCurrency) Then
		ConditionTextCurrency = "Currency = &Currency";
	Else
		ConditionTextCurrency = "TRUE";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ConditionCurrency", ConditionTextCurrency);
	
	Query = New Query;
	Query.SetParameter("BalanceOfRebates", BalanceOfRebates.Unload());
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("BoundaryOfRelevance", Boundary);
	Query.SetParameter("Currency", DocumentCurrency);
	Query.SetParameter("RowsCount", RowsCount);
	Query.Text = QueryText;
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		DataAboutBalance = QueryResult.Unload();
		BalanceOfRebates.Load(DataAboutBalance);
		
	Else
		BalanceOfRebates.Clear();
	EndIf;
	
EndProcedure

&AtServer
Function AddressOfResultInRepository()
	
	Filter = New Structure;
	Filter.Insert("DocumentSelected", True);
	
	Return PutToTempStorage(BalanceOfRebates.Unload(Filter));
	
EndFunction

#EndRegion	