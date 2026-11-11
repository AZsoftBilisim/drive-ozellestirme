//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not ValueIsFilled(Parameters.Organization)
	 Or Not ValueIsFilled(Parameters.Counterparty)  Then
		
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
		
		Cancel = False;
		For Each TableRow In FoundRows Do
			
			If Not ValueIsFilled(DocumentCurrency) Then
				DocumentCurrency = TableRow.Currency;
			EndIf;
			
			If TableRow.Currency <> DocumentCurrency Then
				
				DocumentCurrency = PredefinedValue("Catalog.Currencies.EmptyRef");
				MessageText = NStr("vi = 'Đã chọn các dòng có tiền tệ khác nhau, không thể chuyển vào chứng từ';
									|ru = 'Выбраны строки с разной валютой, перенос в документ невозможен';
									|en = 'Lines with different currencies are selected, cannot transfer them to the document'; fa = 'Lines with different currencies are selected, cannot transfer them to the document';
									|it = 'Выбраны строки с разной валютой, перенос в документ невозможен';
									|pl = 'Lines with different currencies are selected, cannot transfer them to the document';
									|tr = 'Farklı para birimine sahip satırlar seçildiğinde, belgeye aktarım mümkün değildir'");
				CommonClient.MessageToUser(MessageText,,,, Cancel);
				Break;
				
			EndIf;
			
		EndDo;	
		
		If Not Cancel Then
			
			AddressInStorage = AddressOfResultInRepository();
			Close(AddressInStorage);
			
		EndIf;
		
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
	|	CustomerRebates.Partner AS Partner,
	|	CustomerRebates.BeginOfPeriod AS BeginOfPeriod,
	|	CustomerRebates.PeriodEnding AS PeriodEnding,
	|	CustomerRebates.TermDocument AS TermDocument,
	|	CustomerRebates.Currency AS Currency,
	|	CASE
	|		WHEN CustomerRebates.AmountBonusOpeningBalance - CustomerRebates.ToCertifyOpeningBalance - CustomerRebates.ToSignOpeningBalance - CustomerRebates.ToWriteOffOpeningBalance > CustomerRebates.AmountBonusClosingBalance - CustomerRebates.ToCertifyClosingBalance - CustomerRebates.ToSignClosingBalance - CustomerRebates.ToWriteOffClosingBalance
	|			THEN CustomerRebates.AmountBonusClosingBalance - CustomerRebates.ToCertifyClosingBalance - CustomerRebates.ToSignClosingBalance - CustomerRebates.ToWriteOffClosingBalance
	|		ELSE CustomerRebates.AmountBonusOpeningBalance - CustomerRebates.ToCertifyOpeningBalance - CustomerRebates.ToSignOpeningBalance - CustomerRebates.ToWriteOffOpeningBalance
	|	END AS Sum
	|INTO TT_BonusBalances
	|FROM
	|	AccumulationRegister.CustomerRebates.BalanceAndTurnovers(
	|			&Period,
	|			,
	|			,
	|			,
	|			Organization = &Organization
	|				AND Counterparty = &Counterparty
	|				AND &ConditionCurrency) AS CustomerRebates
	|WHERE
	|	CustomerRebates.AmountBonusOpeningBalance - CustomerRebates.ToCertifyOpeningBalance - CustomerRebates.ToSignOpeningBalance - CustomerRebates.ToWriteOffOpeningBalance > 0
	|	AND CustomerRebates.AmountBonusClosingBalance - CustomerRebates.ToCertifyClosingBalance - CustomerRebates.ToSignClosingBalance - CustomerRebates.ToWriteOffClosingBalance > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(TT_BalancesSelected.DocumentSelected, FALSE) AS DocumentSelected,
	|	ISNULL(TT_BalancesSelected.LineNumber, &RowsCount) AS LineNumber,
	|	BonusBalances.Partner AS Partner,
	|	BonusBalances.TermDocument AS TermDocument,
	|	BonusBalances.BeginOfPeriod AS BeginOfPeriod,
	|	BonusBalances.PeriodEnding AS PeriodEnding,
	|	BonusBalances.Currency AS Currency,
	|	ISNULL(CustomerRebatesConditions.Kind, VALUE(Catalog.CustomerRebatesKinds.EmptyRef)) AS RebateKind,
	|	ISNULL(CustomerRebatesConditions.LongDesc, """") AS LongDesc,
	|	BonusBalances.Sum AS Sum
	|INTO VT_Preparation
	|FROM
	|	TT_BonusBalances AS BonusBalances
	|		LEFT JOIN TT_BalancesSelected AS TT_BalancesSelected
	|		ON BonusBalances.Partner = TT_BalancesSelected.Partner
	|			AND BonusBalances.Currency = TT_BalancesSelected.Currency
	|			AND BonusBalances.TermDocument = TT_BalancesSelected.TermDocument
	|			AND BonusBalances.BeginOfPeriod = TT_BalancesSelected.BeginOfPeriod
	|			AND BonusBalances.PeriodEnding = TT_BalancesSelected.PeriodEnding
	|		LEFT JOIN InformationRegister.CustomerRebatesConditions AS CustomerRebatesConditions
	|		ON BonusBalances.TermDocument = CustomerRebatesConditions.TermDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(VT_Preparation.DocumentSelected) AS DocumentSelected,
	|	MIN(VT_Preparation.LineNumber) AS LineNumber,
	|	VT_Preparation.Partner AS Partner,
	|	VT_Preparation.TermDocument AS TermDocument,
	|	VT_Preparation.BeginOfPeriod AS BeginOfPeriod,
	|	VT_Preparation.PeriodEnding AS PeriodEnding,
	|	VT_Preparation.Currency AS Currency,
	|	VT_Preparation.RebateKind AS RebateKind,
	|	VT_Preparation.LongDesc AS LongDesc,
	|	VT_Preparation.Sum AS Sum
	|FROM
	|	VT_Preparation AS VT_Preparation
	|
	|GROUP BY
	|	VT_Preparation.Partner,
	|	VT_Preparation.TermDocument,
	|	VT_Preparation.BeginOfPeriod,
	|	VT_Preparation.PeriodEnding,
	|	VT_Preparation.Currency,
	|	VT_Preparation.RebateKind,
	|	VT_Preparation.LongDesc,
	|	VT_Preparation.Sum
	|
	|ORDER BY
	|	DocumentSelected DESC,
	|	LineNumber,
	|	TermDocument,
	|	Partner";
	
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
	Query.SetParameter("Period", Boundary);
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