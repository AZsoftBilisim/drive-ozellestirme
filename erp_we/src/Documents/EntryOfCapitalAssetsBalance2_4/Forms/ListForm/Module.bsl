
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	CustomizeFormWhenCreatingIt();
	
	#Region StandardMechanisms
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
		
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
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

#Region AttachableCommands

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
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject);
	
EndProcedure

&AtServer
Procedure CustomizeFormWhenCreatingIt()

	List.Parameters.SetParameterValue("AccountingStartDate", NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24());

	If NonCurrentAssetsInternal.ComplianceCAAccountingIsKept() Then
		Items.ListRecordInOperationalAccounting.Visible = GetFunctionalOption("UseLocal");
		Items.ListPostInFinancialAndTaxAccounting.Visible = GetFunctionalOption("UseLocal");
		Items.ListRecordInMA.Visible = GetFunctionalOption("KeepManagementAccountingOnSelfFinancingChartOfAccounts");
	Else
		Items.ListRecordInOperationalAccounting.Visible = False;
		Items.ListPostInFinancialAndTaxAccounting.Visible = False;
		Items.ListRecordInMA.Visible = False;
	EndIf;
	
	If Parameters.Property("ListFormSelections") Then
		
		If Parameters.Property("FormAssignmentKey")
			And Parameters.FormAssignmentKey = "TransitionAssistant" Then
				
			CommonClientServer.SetDynamicListFilterItem(
				List,
				"CreatedToUpgradeToVersion24",
				1,
				DataCompositionComparisonType.Equal,,
				True);
				
			AutoTitle = False;
			Title = NStr("vi = 'Chứng từ nhập số dư đã tạo để chuyển sang kế toán tài sản dài hạn phiên bản 2.4';
						|ru = 'Документы ввода остатков, созданные для перехода на учет внеоборотных активов версии 2.4';
						|en = 'Documents of entering balance created for migration to fixed asset accounting 2.4'; fa = 'Documents of entering balance created for migration to fixed asset accounting 2.4';
						|it = 'Documenti per inserimento di rimanenze creati per passare alla contabilizzazione delle attività immobilizzate versione 2.4';
						|pl = 'Dokument wprowadzenia ostatków wprowadzone w celu przejścia na ewidencję aktywów pozaobrotowych wersji 2.4';
						|tr = 'Duran varlıkların muhasebesi sürüm 2.4''e geçiş için oluşturulan bakiye giriş belgeleri'");
			
		EndIf; 
		
	EndIf;
	
EndProcedure

#EndRegion
