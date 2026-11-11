#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillPropertyValues(ThisForm, Parameters.Filter);

	If Parameters.Property("ColvoShopping") Then
		Client = Parameters.ColvoShopping;
	ElsIf Parameters.Property("ColvoPurchasesTotal") Then
		Client = Parameters.ColvoPurchasesTotal;
	EndIf;
	
	Text_Title = NStr("vi = 'Danh sách mua hàng: [Client]';
						|ru = 'Список покупок: [Client]';
						|en = 'Shopping list: [Client]'; fa = 'Shopping list: [Client]';
						|it = 'Elenco degli acquisti: [Client]';
						|pl = 'Lista zakupów: [Client]';
						|tr = 'Satın alma listesi: [Client]'");	
	Values = New Structure("Client", Client);
	Title =  StringFunctionsClientServer.InsertParametersIntoString(Text_Title,Values); 
	TypeOfPurchase =  Parameters.TypeOfPurchase;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ExecutionResult = List();
	If Not ExecutionResult.Status = "Completed2" Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		CallbackOnCompletion = New CallbackDescription("GenerateAlertReport", ThisObject);
		
		TimeConsumingOperationsClient.WaitCompletion(ExecutionResult, CallbackOnCompletion, IdleParameters);
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "ReportGeneration");
		
	EndIf;

EndProcedure

#EndRegion

#Region Private

&AtServer
Function List()
	
	If ValueIsFilled(JobID) Then
		CancelBackgroundTask(JobID);
		JobID = Undefined;
	EndIf;

	SelectionParameterNames = "StartDate,EndDate,PeriodOfUse,
		|Organization,OrganizationUsage,
		|Manager,ManagerUsage,Client,
		|Products,NomenclatureUsage,
		|CustomerSegment,CustomerSegmentUsage,
		|ProductSegment,ItemSegmentUsage,
		|AmountOfPurchases,PurchaseAmountUsage, TypeOfPurchase";

	QueryOptions = New Structure(SelectionParameterNames);
	FillPropertyValues(QueryOptions, ThisForm);
	QueryOptions.Insert("BeginningDateOfPeriod",StartDate);
	QueryOptions.Insert("EndingDateOfPeriod",EndDate);
	
	BackgroundExecutionParameters=TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionResult = TimeConsumingOperations.ExecuteInBackground(
		"Reports.RepeatedSales.FillInShoppingList", 
		QueryOptions,
		BackgroundExecutionParameters);
	
	JobID = ExecutionResult.JobID;
	StorageAddress       = ExecutionResult.ResultAddress;
	
	If ExecutionResult.Status = "Completed2" Then
		OutputList();
	EndIf;

	Return ExecutionResult;
	
EndFunction

&AtServer
Procedure OutputList()
	
	ResultList = GetFromTempStorage(StorageAddress);
	DeleteFromTempStorage(StorageAddress);
	JobID = Undefined;

	Template = Reports.RepeatedSales.GetTemplate("ShoppingList");
	
	//Output the table header
	Area_TableHeader = Template.GetArea("Header");
	Result.Put(Area_TableHeader);
	
	Currency = Constants.ManagementAccountingCurrency.Get();
	Values = New Structure("Currency", Currency);
	Text = NStr("vi = 'Tổng số, [Currency]';
				|ru = 'Сумма, [Currency]';
				|en = 'Amount, [Currency]'; fa = 'مبلغ، [Currency]';
				|it = 'Importo, [Currency]';
				|pl = 'Wartość, [Currency]';
				|tr = 'Tutar, [Currency]'");	
	Result.Area("Sum").Text =StringFunctionsClientServer.InsertParametersIntoString(Text,Values);

	AreaRow = Template.GetArea("String");
	
	RowNumber_ = 0;	
	//Fill in the table
	ShoppingList = ResultList.ShoppingList;
	For Each String In ShoppingList Do
		AreaRow.Parameters.RowNumber_ = RowNumber_+1;
		AreaRow.Parameters.Document = String.Document;
		DecryptionOfD = New Structure ("Document",String.Document);
		AreaRow.Parameters.PDocument = DecryptionOfD;
		
		AreaRow.Parameters.Sum= String.Sum;
		RowNumber_ = RowNumber_+1;
		Result.Put(AreaRow);
	EndDo;

	ScopeOfApplication_1 = Template.GetArea("Total");
	ScopeOfApplication_1.Parameters.Total = ResultList.Total.Total;
	Result.Put(ScopeOfApplication_1);

EndProcedure

&AtClient
Procedure GenerateAlertReport(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "DontUse");
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		OutputList();
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "DontUse");
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CancelBackgroundTask(JobID)
	TimeConsumingOperations.CancelJobExecution(JobID);
EndProcedure

&AtClient
Procedure ResultDetailProcessing(Item, Details, StandardProcessing, AdditionalParameters)
	
	StandardProcessing = False;

	If Details.Property("Document") Then
		ShowValue(,Details.Document);
	EndIf;
	
EndProcedure

#EndRegion