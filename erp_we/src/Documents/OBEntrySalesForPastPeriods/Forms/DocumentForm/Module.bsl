#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)

	If ValueIsFilled(Object.BusinessOperation) Then
		
		Cancel = True;
		
		FillingValues = New Structure;
		FillingValues.Insert("CopyingValue", CopyingValue);
		
		OpenFormForBusinessTransactions(Object.BusinessOperation, FillingValues);
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("FillingValues") 
		And Parameters.FillingValues.Property("CopyingValue") Then
		
		CopyingValue = Parameters.FillingValues.CopyingValue;
	
	Else
		
		ObjectID = Common.MetadataObjectID(Metadata.Documents.OBEntrySalesForPastPeriods);
		FilterParameters = OBEntryServer.InitializeSelectionParametersForAvailableBusinessOperations();
		FilterParameters.BalanceInputDocument = ObjectID;
		TransactionKindList.LoadValues(OBEntryServer.AvailableBusinessTransactions(FilterParameters));
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
		// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
EndProcedure


#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectOperation(Command)

	If Items.TransactionKindList.CurrentData = Undefined Then
		ShowMessageBox(,NStr("vi = 'Cần chọn giao dịch.';
							|ru = 'Необходимо выбрать операцию.';
							|en = 'Select a transaction.'; fa = 'Select a transaction.';
							|it = 'Необходимо выбрать операцию.';
							|pl = 'Select a transaction.';
							|tr = 'İşlem seçilmelidir.'")); 
		Return;
	EndIf;
	
	BusinessOperation = Items.TransactionKindList.CurrentData.Value;
	
	If ValueIsFilled(BusinessOperation) Then
		
		FillingValues = New Structure;
		FillingValues.Insert("BusinessOperation", BusinessOperation);
		
		OpenFormForBusinessTransactions(BusinessOperation, FillingValues);
		
	EndIf;EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands
#EndRegion

#Region TableHandlersListOfTypesOfOperations

&AtClient
Procedure TransactionKindListSelection(Item, RowSelected, Field, StandardProcessing)
	
	BusinessOperation = Item.CurrentData.Value;
	StandardProcessing = False;
	
	If ValueIsFilled(BusinessOperation) Then
		
		FillingValues = New Structure;
		FillingValues.Insert("BusinessOperation", BusinessOperation);
		
		OpenFormForBusinessTransactions(BusinessOperation, FillingValues);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OpenFormForBusinessTransactions(BusinessOperation, FillingValues)
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("FillingValues", FillingValues);
	
	NameOfFormToOpen_ = OBEntryServerCall.ObtainingFormForEnteringBalancesOnSalesForPastPeriods(BusinessOperation);
	NameOfFormToOpen_ = "Document.OBEntrySalesForPastPeriods.Form." + NameOfFormToOpen_;
	OpenForm(NameOfFormToOpen_, OpeningParameters, , , , , , );
	
EndProcedure

#EndRegion