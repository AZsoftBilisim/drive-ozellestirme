
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure ReEvaluationRequired(Command)
	
	SpreadsheetDocument = RevaluationOnServerIsRequired(Items.List.CurrentItem.Name);
	If SpreadsheetDocument.TableHeight > 0 Then
		SpreadsheetDocument.Show(NStr("vi = 'Số dư cần đánh giá lại';
										|ru = 'Остатки к переоценке';
										|en = 'Balances to revalue'; fa = 'Balances to revalue';
										|it = 'Balances to revalue';
										|pl = 'Balances to revalue';
										|tr = 'Yeniden değerleme bakiyeleri'"));
	EndIf;

EndProcedure

&AtClient
Procedure ReFillRegistersTA(Command)

	Return;
	
EndProcedure
#EndRegion

#Region Private
&AtServer
Function RevaluationOnServerIsRequired(CurrentColumn)
	
	Companies = New Array;
	Operations = New Array;
	Period = Date(1,1,1);
	For Each ListLine In Items.List.SelectedRows Do
		Period = Max(Period, ListLine.Date);
		If Companies.Find(ListLine.Organization) = Undefined Then
			Companies.Add(ListLine.Organization);
		EndIf;
	EndDo;
	
	ForDebugging = New Structure;
	Documents.ExchangeDifferenceCalculation.ReEvaluationRequired(Companies,Period,,,,ForDebugging);
	
	Query = ForDebugging.ReEvaluationRequired;
	Query.TempTablesManager = New TempTablesManager;
	
	QueryResult = Query.Execute().Unload();
	
	SpreadsheetDocument = New SpreadsheetDocument;
	ReportBuilder = New ReportBuilder; 
	ReportBuilder.DataSource = New DataSourceDescription(QueryResult);
	ReportBuilder.Execute();
	ReportBuilder.Put(SpreadsheetDocument);
	
	SpreadsheetDocument.ShowHeaders = False;
	SpreadsheetDocument.ShowGrid = False;
	SpreadsheetDocument.ReadOnly = True;
	
	Return SpreadsheetDocument;
	
EndFunction


#EndRegion