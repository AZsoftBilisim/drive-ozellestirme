
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.ListCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	If Parameters.Property("CurrentRow") And ValueIsFilled(Parameters.CurrentRow) Then
		Parameters.CurrentRow = InformationRegisters.DocumentsRegistry.DocumentRecordingKey(Parameters.CurrentRow);
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	List.Parameters.SetParameterValue("RefType",
		Common.MetadataObjectID("Document.ARAPAccountingScheduleAdjustment"));
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
	WithoutBTSelections = True;
	If Parameters.Filter.Property("BusinessOperation")
		And TypeOf(Parameters.Filter.BusinessOperation) = Type("ValueList")
		And Parameters.Filter.BusinessOperation.Count() = 2 Then
		If Parameters.Filter.BusinessOperation.FindByValue(Enums.BusinessTransactions.AdjustCustomerPaymentSchedule) <> Undefined
			And Parameters.Filter.BusinessOperation.FindByValue(Enums.BusinessTransactions.AdjustCustomerPrepaymentRepaymentSchedule) <> Undefined Then
			Title = NStr("vi = 'Điều chỉnh lịch biểu hạch toán với khách hàng';
						|ru = 'Корректировки графиков взаиморасчетов с клиентами';
						|en = 'Customer AR/AP schedule adjustments'; fa = 'Customer AR/AP schedule adjustments';
						|it = 'Customer AR/AP schedule adjustments';
						|pl = 'Customer AR/AP schedule adjustments';
						|tr = 'Müşterilerle olan alacak/borç muhasebesi planlarının düzeltilmesi'");
			WithoutBTSelections = False;
		ElsIf Parameters.Filter.BusinessOperation.FindByValue(Enums.BusinessTransactions.AdjustVendorPaymentSchedule) <> Undefined
			And Parameters.Filter.BusinessOperation.FindByValue(Enums.BusinessTransactions.AdjustVendorPrepaymentRepaymentSchedule) <> Undefined Then
			Title = NStr("vi = 'Điều chỉnh lịch biểu hạch toán với nhà cung cấp';
						|ru = 'Корректировки графиков взаиморасчетов с поставщиками';
						|en = 'Vendor AR/AP schedule adjustments'; fa = 'Vendor AR/AP schedule adjustments';
						|it = 'Vendor AR/AP schedule adjustments';
						|pl = 'Vendor AR/AP schedule adjustments';
						|tr = 'Tedarikçilerle olan alacak/borç muhasebesi planlarının düzeltilmesi'");
			WithoutBTSelections = False;
		EndIf;
	EndIf;
	If WithoutBTSelections Then
		Title = NStr("vi = 'Điều chỉnh lịch biểu hạch toán';
					|ru = 'Корректировки графиков взаиморасчетов';
					|en = 'AR/AP accounting schedule adjustments'; fa = 'تعدیلات برنامه حسابداری دریافتنی/پرداختنی';
					|it = 'AR/AP accounting schedule adjustments';
					|pl = 'AR/AP accounting schedule adjustments';
					|tr = 'Alacak/borç muhasebesi planlarının düzeltilmesi'");
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;	
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Copy Then
		TMCommonUseClient.CopyItem(Item);
	Else
		OpenForm("Document.ARAPAccountingScheduleAdjustment.ObjectForm", , Items.List);
	EndIf;
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.SetDeletionMark(Items.List, Title);
	
EndProcedure

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.List, Title);
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.List, Title);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ARAPAccountingScheduleAdjustment" Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion
