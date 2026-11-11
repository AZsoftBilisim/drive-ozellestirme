#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	Query = New Query();
	Text = 
	"SELECT DISTINCT
	|	Table.DateOfRemainingGoods AS DateOfRemainingGoods,
	|	Table.BudgetBalanceItem AS BudgetBalanceItem,
	|	Table.Scenario AS Scenario,
	|	Table.Organization AS Organization,
	|	Table.Department AS Department,
	|	&TextTableOfAnalyticsSuite,
	|	Table.Currency AS Currency
	|INTO SetTable
	|FROM
	|	&Table AS Table
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	OpeningBalanceOfEstimates.DateOfRemainingGoods AS DateOfRemainingGoods,
	|	OpeningBalanceOfEstimates.Recorder AS Recorder,
	|	OpeningBalanceOfEstimates.BudgetBalanceItem AS BudgetBalanceItem,
	|	OpeningBalanceOfEstimates.Scenario AS Scenario,
	|	OpeningBalanceOfEstimates.Organization AS Organization,
	|	OpeningBalanceOfEstimates.Department AS Department,
	|	&TextRegisterTable,
	|	OpeningBalanceOfEstimates.Currency AS Currency
	|INTO RegisterTable
	|FROM
	|	InformationRegister.OpeningBalanceOfEstimates AS OpeningBalanceOfEstimates
	|WHERE
	|	OpeningBalanceOfEstimates.Recorder <> &Recorder
	|	AND (OpeningBalanceOfEstimates.DateOfRemainingGoods,
	|		OpeningBalanceOfEstimates.BudgetBalanceItem,
	|		OpeningBalanceOfEstimates.Scenario,
	|		OpeningBalanceOfEstimates.Organization,
	|		OpeningBalanceOfEstimates.Department,
	|		&TextTableAndAnalyticsConditions,
	|		OpeningBalanceOfEstimates.Currency) IN
	|		(SELECT
	|			SetTable.DateOfRemainingGoods,
	|			SetTable.BudgetBalanceItem,
	|			SetTable.Scenario,
	|			SetTable.Organization,
	|			SetTable.Department,
	|			&TextRegisterTableAnalyticsSubquery,
	|			SetTable.Currency
	|		FROM
	|			SetTable)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	OpeningBalanceOfEstimates.DateOfRemainingGoods AS DateOfRemainingGoods,
	|	OpeningBalanceOfEstimates.Recorder AS Recorder,
	|	OpeningBalanceOfEstimates.BudgetBalanceItem AS BudgetBalanceItem,
	|	PRESENTATION(OpeningBalanceOfEstimates.BudgetBalanceItem) AS BudgetBalanceItemPresentation,
	|	PRESENTATION(OpeningBalanceOfEstimates.Recorder) AS RecorderPresentation
	|FROM
	|	RegisterTable AS OpeningBalanceOfEstimates";
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	TextTableOfAnalyticsSuite = "";
	TextRegisterTable = "";
	TextTableAndAnalyticsConditions = "";
	TextRegisterTableAnalyticsSubquery = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextTableOfAnalyticsSuite = TextTableOfAnalyticsSuite + ?(TextTableOfAnalyticsSuite = "", "", ","
			+ Chars.LF + Chars.Tab) + StringFunctionsClientServer.SubstituteParametersToString(
			"Table.Dimension%1 AS Dimension%1", DimensionNumber);
		
		TextRegisterTable = TextRegisterTable + ?(TextRegisterTable = "", "", ","
			+ Chars.LF + Chars.Tab) + StringFunctionsClientServer.SubstituteParametersToString(
			"OpeningBalanceOfEstimates.Dimension%1 AS Dimension%1", DimensionNumber);
		
		TextTableAndAnalyticsConditions = TextTableAndAnalyticsConditions + ?(
			TextTableAndAnalyticsConditions = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString("OpeningBalanceOfEstimates.Dimension%1",
			DimensionNumber);
		
		TextRegisterTableAnalyticsSubquery = TextRegisterTableAnalyticsSubquery + ?(
			TextRegisterTableAnalyticsSubquery = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString("SetTable.Dimension%1", DimensionNumber);
	EndDo;
	Text = StrReplace(Text, "&TextTableOfAnalyticsSuite", TextTableOfAnalyticsSuite);
	Text = StrReplace(Text, "&TextRegisterTable", TextRegisterTable);
	Text = StrReplace(Text, "&TextTableAndAnalyticsConditions", TextTableAndAnalyticsConditions);
	Text = StrReplace(Text, "&TextRegisterTableAnalyticsSubquery", TextRegisterTableAnalyticsSubquery);
	
	Query.Text = Text;
	
	Query.SetParameter("Table", Unload());
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	DuplicatesTable = Query.Execute().Unload();
	
	DuplicatesTable.Indexes.Add("BudgetBalanceItem");
	DuplicatesTable.Indexes.Add("BudgetBalanceItem, Recorder");
	
	ArrayOfCalculatedIndicators = New Array;
	CommonClientServer.SupplementArray(ArrayOfCalculatedIndicators, DuplicatesTable.UnloadColumn(
		"BudgetBalanceItem"), True);
	Errors = Undefined;
	For Each CalculatedIndicator In ArrayOfCalculatedIndicators Do
		PresentationOfCalculatedIndicator = DuplicatesTable.Find(CalculatedIndicator,
			"BudgetBalanceItem").BudgetBalanceItemPresentation;
		MessageText = NStr("vi = 'Đối với chỉ tiêu tính toán ""%1"" vào ngày %2, các giá trị đã được đặt theo chứng từ ""%3""';
							|ru = 'Для расчетного показателя ""%1"" на даты %2 значения уже установлены документом ""%3""';
							|en = 'Values are already set for the ""%1"" estimate on dates %2 by the ""%3"" document'; fa = 'Values are already set for the ""%1"" estimate on dates %2 by the ""%3"" document';
							|it = 'Values are already set for the ""%1"" estimate on dates %2 by the ""%3"" document';
							|pl = 'Values are already set for the ""%1"" estimate on dates %2 by the ""%3"" document';
							|tr = '""%1"" hesaplanan göstergesi için %2 tarihlerindeki değerler ""%3"" belgesi ile zaten belirlenmiş'");
		
		ArrayOfLoggers = New Array;
		RegistrarsByIndicator = DuplicatesTable.Copy(New Structure("BudgetBalanceItem", CalculatedIndicator));
		CommonClientServer.SupplementArray(ArrayOfLoggers, RegistrarsByIndicator.UnloadColumn(
			"Recorder"), True);
		
		For Each Recorder In ArrayOfLoggers Do
			
			DatesArray = New Array;
			DatesByIndicator = DuplicatesTable.Copy(New Structure("BudgetBalanceItem, Recorder",
				CalculatedIndicator, Recorder));
			CommonClientServer.SupplementArray(DatesArray, DatesByIndicator.UnloadColumn("DateOfRemainingGoods"),
				True);
			ConvolutionArray = New Array;
			For Each Value In DatesArray Do
				ConvolutionArray.Add(Format(Value, "DLF=D"));
			EndDo;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
				PresentationOfCalculatedIndicator, StrConcat(ConvolutionArray, ", "),
				DatesByIndicator[0].RecorderPresentation);
			CommonClientServer.AddUserError(Errors, Undefined, MessageText, "");
			
		EndDo;
		
	EndDo;
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
EndProcedure

#EndRegion

#EndIf