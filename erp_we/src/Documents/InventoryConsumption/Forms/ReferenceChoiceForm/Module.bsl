
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Var FilterValue;
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Texts = New Array();
	
	Text =
		"SELECT ALLOWED
		|	OrdersTable.OrderDocument AS OrderDocument
		|INTO OrderBalances
		|FROM(
		|	SELECT
		|		Balance.InventoryConsumptionOrder AS OrderDocument,
		|		Balance.ToRegisterBalance AS ToRegister
		|	FROM
		|		AccumulationRegister.InventoryConsumptionOrders.Balance(, Warehouse = &Warehouse) AS Balance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TrafficOrders.InventoryConsumptionOrder AS OrderDocument,
		|		CASE WHEN TrafficOrders.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
		|					-TrafficOrders.ToRegister
		|				ELSE
		|					TrafficOrders.ToRegister
		|			END AS ToRegister
		|	FROM
		|		AccumulationRegister.InventoryConsumptionOrders AS TrafficOrders
		|	WHERE
		|		TrafficOrders.Recorder = &Recorder
		|			AND TrafficOrders.Active) AS OrdersTable
		|GROUP BY
		|	OrdersTable.OrderDocument
		|HAVING
		|	SUM(OrdersTable.ToRegister) > 0
		|INDEX BY
		|	OrderDocument";
		
	Texts.Add(Text);
	
	SelectionTexts = New Array();
	
	If AccessRight("Read", Metadata.Documents.InventoryConsumptionOrder) Then
		
		Text =
			"SELECT
			|	Balance.OrderDocument AS OrderDocument
			|FROM
			|	OrderBalances AS Balance
			|		
			|		LEFT JOIN Document.InventoryConsumptionOrder AS Orders
			|		ON Orders.Ref = Balance.OrderDocument
			|WHERE
			|	Orders.Department = &Department
			|		AND Orders.Organization = &Organization
			|		AND Orders.SalesOpportunity = &SalesOpportunity
			|		AND Orders.BusinessOperation = &BusinessOperation
			|		AND Orders.LineOfBusiness = &LineOfBusiness";
		
		SelectionTexts.Add(Text);
		
	EndIf;
	If AccessRight("Read", Metadata.Documents.RMOrder) Then
		
		Text =
			"SELECT
			|	Balance.OrderDocument AS OrderDocument
			|FROM
			|	OrderBalances AS Balance
			|		
			|		LEFT JOIN Document.RMOrder AS Orders
			|		ON Orders.Ref = Balance.OrderDocument
			|WHERE
			|	Orders.Department = &Department
			|		AND Orders.Organization = &Organization
			|		AND Orders.LineOfBusiness = &LineOfBusiness";
			
		SelectionTexts.Add(Text);
		
	EndIf;
	TextSelections = StrConcat(SelectionTexts, TMCommonUse.QuerySeparatorInJoin());
	
	Text =
		"SELECT ALLOWED
		|	Table.OrderDocument AS Ref
		|FROM
		|	&Substitution AS Table";
	Text = StrReplace(Text, "&Substitution" , StrTemplate("(%1)", TextSelections));
	
	Texts.Add(Text);
	Text = StrConcat(Texts, Common.QueryBatchSeparator());
	
	Query = New Query(Text);
	Query.SetParameter("Recorder",             Parameters.Recorder);
	Query.SetParameter("Organization",             Parameters.Organization);
	Query.SetParameter("Department",           Parameters.Department);
	Query.SetParameter("Warehouse",                   Parameters.Warehouse);
	Query.SetParameter("SalesOpportunity",                  Parameters.SalesOpportunity);
	Query.SetParameter("BusinessOperation",   Parameters.BusinessOperation);
	Query.SetParameter("LineOfBusiness", Parameters.LineOfBusiness);
	
	References = Query.Execute().Unload().UnloadColumn("Ref");
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"References",
		References);
		
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	Close(Items.List.CurrentData.Ref);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	If TMCommonUseClient.CheckForSelectedLinesInList(Items.List) Then
		Close(Items.List.CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
