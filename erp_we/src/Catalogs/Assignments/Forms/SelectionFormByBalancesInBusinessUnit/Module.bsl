
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	// Required parameter
	FillPropertyValues(ThisForm, Parameters, "Organization, Department, Products, Characteristic");
	
	// Optional parameters
	Parameters.Property("DocumentReturnPolicy", DocumentReturnPolicy);
	
	FillInTableOfBalances();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBalanceTable

&AtClient
Procedure BalanceTableValueChoice(Item, Value, StandardProcessing)
	
	CurrentData = Items.BalanceTable.CurrentData;
	
	If CurrentData <> Undefined Then
		NotifyChoice(CurrentData.Purpose);
	Else
		NotifyChoice(PredefinedValue("Catalog.Assignments.EmptyRef"));
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Change(Command)
	
	CurrentData = Items.BalanceTable.CurrentData;
	
	If CurrentData <> Undefined Then
		
		FormParameters = New Structure("Key, ReadOnly", CurrentData.Purpose, True);
		OpenForm("Catalog.Assignments.ObjectForm", FormParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInTableOfBalances()
	
	TempTablesManager = New TempTablesManager;
	ParametersStructure = New Structure("Organization, Department, DocumentReturnPolicy, Products, Characteristic");
	FillPropertyValues(ParametersStructure, ThisForm, "Organization, Department, DocumentReturnPolicy, Products, Characteristic");
	
	SetPrivilegedMode(True);
	InventoriesServer.TableOfMaterialBalancesInSubdivision(TempTablesManager, ParametersStructure);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	BalanceTable.Purpose AS Purpose,
	|	BalanceTable.Products AS Products,
	|	BalanceTable.Characteristic AS Characteristic,
	|	BalanceTable.Count AS Count
	|FROM
	|	BalanceTable AS BalanceTable
	|WHERE
	|	BalanceTable.Purpose <> VALUE(Catalog.Assignments.EmptyRef)";
	
	Query.TempTablesManager = TempTablesManager;
	
	BalanceTable.Load(Query.Execute().Unload());
	
EndProcedure

#EndRegion
