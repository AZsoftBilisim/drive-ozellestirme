
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If ValueIsFilled(Parameters.ProductionPlan) Then
		
		AutoTitle = False;
		
		Attributes = Common.ObjectAttributesValues(
			Parameters.ProductionPlan,
			"Number, Date");
		
		Title = StrTemplate(
			NStr("vi = 'Đã hủy điều chỉnh kế hoạch sản xuất %1 ngày %2';
				|ru = 'Отмененные корректировки плана производства %1 от %2';
				|en = 'Canceled production plan adjusting entries %1 dated %2'; fa = 'Canceled production plan adjusting entries %1 dated %2';
				|it = 'Annullate le correzioni del piano di produzione %1 da %2';
				|pl = 'Anulowane korekty planu produkcji %1 od %2';
				|tr = '%2 itibarıyla %1 üretim planındaki düzeltmelerin iptalleri'"),
			Attributes.Number,
			Format(Attributes.Date, "DLF=DT"));
		
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
		"InformationRegister.CancelProductionPlanAdjustingEntries.Form.RecordFormView",
		FormParameters,
		ThisObject);
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ListAfterDeleteRow(Item)
	
	NotificationParameters = New Structure("ProductionPlan", Parameters.ProductionPlan);
	
	If FormOwner <> Undefined Then
		Notify("CancelProductionPlanAdjustingEntries", NotificationParameters, FormOwner.UUID);
	Else
		Notify("CancelProductionPlanAdjustingEntries", NotificationParameters);
	EndIf;
	
EndProcedure

#EndRegion
