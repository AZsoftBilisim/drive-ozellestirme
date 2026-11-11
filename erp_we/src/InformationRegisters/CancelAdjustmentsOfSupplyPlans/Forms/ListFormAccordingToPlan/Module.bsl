
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If ValueIsFilled(Parameters.Plan) Then
		
		Plan = Parameters.Plan; 
		AutoTitle = False;
		
		Title = StrTemplate(
			NStr("vi = 'Hủy điều chỉnh theo kế hoạch: %1';
				|ru = 'Отмененные корректировки по плану: %1';
				|en = 'Canceled adjustments by plan: %1'; fa = 'Canceled adjustments by plan: %1';
				|it = 'Rettifiche del piano annullate: %1';
				|pl = 'Anulowane korekty według planu: %1';
				|tr = 'Plana göre iptal edilen düzenlemeler: %1'"),
			Parameters.Plan);
		
	EndIf;
	
	Items.Purpose.Visible = Parameters.ShowAssignment;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("Key", RowSelected);
	FormParameters.Insert("ShowAssignment", Items.Purpose.Visible);
	
	OpenForm(
		"InformationRegister.CancelAdjustmentsOfSupplyPlans.Form.RecordFormView",
		FormParameters,
		ThisObject);
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region BNDFormHandlers

&AtClient
Procedure ClearList(Command)
	ClearListOnServer();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ClearListOnServer()
	
	RecordSet = InformationRegisters.CancelAdjustmentsOfSupplyPlans.CreateRecordSet();
	RecordSet.Filter.Plan.Set(Plan);
	RecordSet.Write();
	Items.List.Refresh();
	
EndProcedure

#EndRegion
