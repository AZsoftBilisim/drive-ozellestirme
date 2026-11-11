#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Query = New Query("
	|SELECT
	|	ExpenseItems.ValueType AS ValueType
	|FROM
	|	ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|WHERE
	|	ExpenseItems.Ref = &ExpenseItem
	|");
	
	Query.SetParameter("ExpenseItem", Owner);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		ExpenseAnalyticsValueType = Selection.ValueType;
	Else
		ExpenseAnalyticsValueType = Undefined;
	EndIf;
	
	If ValueIsFilled(Owner) And Not ExpenseAnalyticsValueType.ContainsType(Type("CatalogRef.OtherExpenses")) Then
		Text = NStr("vi = 'Cần chỉ ra dạng chi phí có đối tượng phân tích ""Chi phí khác""';
					|ru = 'Необходимо указать статью расходов с аналитикой ""Прочие расходы""';
					|en = 'Specify an expense item with the ""Other expenses"" dimension'; fa = 'Specify an expense item with the ""Other expenses"" dimension';
					|it = 'È necessario specificare la voce di spesa con analitica ""Altre Spese""';
					|pl = 'Należy wskazać pozycję kosztów z analityką ""Inne koszty""';
					|tr = '""Diğer giderler"" boyutu ile bir gider kalemi belirtilmeli'");
		CommonClientServer.MessageToUser(
			Text,
			ThisObject,
			"Owner",
			,
			Cancel);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
