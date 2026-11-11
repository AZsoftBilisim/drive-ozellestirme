
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Property("ChartsOfAccounts") Then
		
		StandardProcessing = False;
		ChoiceData = New ValueList();
		
		Query = New Query;
		Query.Text =
		"SELECT DISTINCT
		|	FinancialReportTypes.Ref AS Ref,
		|	PRESENTATION(FinancialReportTypes.Ref) AS Presentation
		|FROM
		|	Catalog.FinancialReportTypes AS FinancialReportTypes
		|WHERE
		|	TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			Catalog.FinancialReportTypes.ChartsOfAccounts AS TableOfAccountPlans
		|		WHERE
		|			FinancialReportTypes.Ref = TableOfAccountPlans.Ref
		|			AND TableOfAccountPlans.ChartOfAccounts IN (&ChartsOfAccounts))
		|	AND NOT TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			Catalog.FinancialReportTypes.ChartsOfAccounts AS TableOfAccountPlans
		|		WHERE
		|			FinancialReportTypes.Ref = TableOfAccountPlans.Ref
		|			AND NOT TableOfAccountPlans.ChartOfAccounts IN (&ChartsOfAccounts))
		|	AND &Filter
		|	AND &SearchString
		|";
		Query.SetParameter("ChartsOfAccounts", Parameters.ChartsOfAccounts);
		
		SelectionStringArray = New Array;
		SelectionStringArray.Add("TRUE");
		If Parameters.Property("Filter") Then
			For Each KeyAndValue In Parameters.Filter Do
				SelectionStringArray.Add(StrTemplate("TableOfAccountPlans.Ref.%1 = &%1", KeyAndValue.Key));
				Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
			EndDo;
		EndIf;
		Query.Text = StrReplace(Query.Text, "&Filter", StrConcat(SelectionStringArray, Chars.LF + "And" + " "));
		
		If Parameters.Property("SearchString") Then
			ConditionSearchString = "FinancialReportTypes.Description LIKE &SearchString";
			Query.SetParameter("SearchString", "%" + Parameters.SearchString + "%");
		Else
			ConditionSearchString = "TRUE";
		EndIf;
		Query.Text = StrReplace(Query.Text, "&SearchString", ConditionSearchString);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ChoiceData.Add(Selection.Ref, Selection.Presentation);
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
