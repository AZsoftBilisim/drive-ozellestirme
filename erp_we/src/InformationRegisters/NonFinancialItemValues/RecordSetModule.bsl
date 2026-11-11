#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	Var Errors;
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	Table = ThisObject.Unload();
	Query = New Query();
	Text = 
	"SELECT DISTINCT
	|	Table.Period AS Period,
	|	Table.NonFinancialItem AS NonFinancialItem,
	|	Table.Scenario AS Scenario,
	|	Table.Organization AS Organization,
	|	Table.Department AS Department,
	|	&TextTableOfAnalyticsSuite
	|INTO SetTable
	|FROM
	|	&Table AS Table
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	NonFinancialItemValues.Period AS Period,
	|	NonFinancialItemValues.Recorder AS Recorder,
	|	NonFinancialItemValues.NonFinancialItem AS NonFinancialItem,
	|	NonFinancialItemValues.Scenario AS Scenario,
	|	NonFinancialItemValues.Organization AS Organization,
	|	NonFinancialItemValues.Department AS Department,
	|	&TextRegisterTable
	|INTO RegisterTable
	|FROM
	|	InformationRegister.NonFinancialItemValues AS NonFinancialItemValues
	|WHERE
	|	NonFinancialItemValues.Recorder <> &Recorder
	|	AND (NonFinancialItemValues.Period,
	|		NonFinancialItemValues.NonFinancialItem,
	|		NonFinancialItemValues.Scenario,
	|		NonFinancialItemValues.Organization,
	|		NonFinancialItemValues.Department,
	|		&TextTableAndAnalyticsConditions) IN
	|		(SELECT
	|			SetTable.Period,
	|			SetTable.NonFinancialItem,
	|			SetTable.Scenario,
	|			SetTable.Organization,
	|			SetTable.Department,
	|			&TextRegisterTableAnalyticsSubquery
	|		FROM
	|			SetTable)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	NonFinancialItemValues.Period AS Period,
	|	NonFinancialItemValues.Recorder AS Recorder,
	|	NonFinancialItemValues.NonFinancialItem AS NonFinancialItem,
	|	PRESENTATION(NonFinancialItemValues.NonFinancialItem) AS NonFinancialItemPresentation,
	|	PRESENTATION(NonFinancialItemValues.Recorder) AS RecorderPresentation
	|FROM
	|	SetTable AS SetTable
	|		INNER JOIN RegisterTable AS NonFinancialItemValues
	|		ON SetTable.Period = NonFinancialItemValues.Period
	|		AND SetTable.NonFinancialItem = NonFinancialItemValues.NonFinancialItem
	|		AND SetTable.Scenario = NonFinancialItemValues.Scenario
	|		AND SetTable.Organization = NonFinancialItemValues.Organization
	|		AND SetTable.Department = NonFinancialItemValues.Department
	|		AND &TextAnalytics";
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	TextTableOfAnalyticsSuite = "";
	TextRegisterTable = "";
	TextTableAndAnalyticsConditions = "";
	TextRegisterTableAnalyticsSubquery = "";
	TextAnalytics = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextTableOfAnalyticsSuite = TextTableOfAnalyticsSuite
			+ ?(TextTableOfAnalyticsSuite = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"Table.Dimension%1 AS Dimension%1",
				DimensionNumber);
		
		TextRegisterTable = TextRegisterTable
			+ ?(TextRegisterTable = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"NonFinancialItemValues.Dimension%1 AS Dimension%1",
				DimensionNumber);
		
		TextTableAndAnalyticsConditions = TextTableAndAnalyticsConditions
			+ ?(TextTableAndAnalyticsConditions = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"NonFinancialItemValues.Dimension%1",
				DimensionNumber);
		
		TextRegisterTableAnalyticsSubquery = TextRegisterTableAnalyticsSubquery
			+ ?(TextRegisterTableAnalyticsSubquery = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"SetTable.Dimension%1",
				DimensionNumber);
		
		TextAnalytics = TextAnalytics
			+ ?(TextAnalytics = "", "", Chars.LF + Chars.Tab + Chars.Tab + "And ")
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"SetTable.Dimension%1 = NonFinancialItemValues.Dimension%1",
				DimensionNumber);
	EndDo;
	Text = StrReplace(Text, "&TextTableOfAnalyticsSuite", TextTableOfAnalyticsSuite);
	Text = StrReplace(Text, "&TextRegisterTable", TextRegisterTable);
	Text = StrReplace(Text, "&TextTableAndAnalyticsConditions", TextTableAndAnalyticsConditions);
	Text = StrReplace(Text, "&TextRegisterTableAnalyticsSubquery", TextRegisterTableAnalyticsSubquery);
	Text = StrReplace(Text, "&TextAnalytics", TextAnalytics);
	
	Query.Text = Text;
	
	Query.SetParameter("Table", Table);
	Query.SetParameter("Recorder", ThisObject.Filter.Recorder.Value);
	DuplicatesTable = Query.Execute().Unload();
	
	DuplicatesTable.Indexes.Add("NonFinancialItem");
	DuplicatesTable.Indexes.Add("NonFinancialItem, Recorder");
	
	NFPArray = New Array;
	CommonClientServer.SupplementArray(NFPArray, DuplicatesTable.UnloadColumn("NonFinancialItem"), True);
	For Each NFP In NFPArray Do
		NFPPresentation = DuplicatesTable.Find(NFP, "NonFinancialItem").NonFinancialItemPresentation;
		MessageText = NStr("vi = 'Đối với chỉ tiêu ""%1"" vào ngày %2, các giá trị đã được đặt theo chứng từ ""%3""';
							|ru = 'Для показателя ""%1"" на даты %2 значения уже установлены документом ""%3""';
							|en = 'Values are already set for the ""%1"" indicator on dates %2 by the ""%3"" document'; fa = 'Values are already set for the ""%1"" indicator on dates %2 by the ""%3"" document';
							|it = 'Per l''indice ""%1"" in date %2 i valori sono stati già impostati tramite il documento ""%3""';
							|pl = 'Dla wskaźnika ""%1"" na daty %2 wartości są już ustawione przez dokument ""%3""';
							|tr = 'Göstergeler ""%1"" için tarih %2 değerler artık belge ""%3"" ile kurulu'");
		
		ArrayOfLoggers = New Array;
		RegistrarsByIndicator = DuplicatesTable.Copy(New Structure("NonFinancialItem", NFP));
		CommonClientServer.SupplementArray(ArrayOfLoggers, RegistrarsByIndicator.UnloadColumn("Recorder"), True);
		
		For Each Recorder In ArrayOfLoggers Do
			
			DatesArray = New Array;
			DatesByIndicator = DuplicatesTable.Copy(New Structure("NonFinancialItem, Recorder", NFP, Recorder));
			CommonClientServer.SupplementArray(DatesArray, DatesByIndicator.UnloadColumn("Period"), True);
			ConvolutionArray = New Array;
			For Each Value In DatesArray Do
				ConvolutionArray.Add(Format(Value, "DLF=D"));
			EndDo;
			DateText_ = StrConcat(DatesArray, ", ");
			LoggerText = DatesByIndicator[0].RecorderPresentation;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, NFPPresentation, DateText_, LoggerText);
			CommonClientServer.AddUserError(Errors,,MessageText, "");
			
		EndDo;
		
	EndDo;
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
EndProcedure

#EndRegion

#EndIf
