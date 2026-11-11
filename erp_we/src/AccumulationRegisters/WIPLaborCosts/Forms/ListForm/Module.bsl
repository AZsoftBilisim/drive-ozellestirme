
#Region FormHeaderItemsEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	MonthEndTransactionsServer.SetSelectionsInRegisterListForm(ThisObject, List);
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	Value = Item.CurrentData[Field.Name];
	ShowValue(Undefined, Value);
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtServer
Procedure ListBeforeLoadUserSettingsAtServer(Item, Settings)
	
	If MonthEndTransactionsServer.ThisFormIsOpenedFromMonthClosingForm(ThisObject) Then
		CompositionFilter = Settings.Items.Find(List.SettingsComposer.Settings.Filter.UserSettingID);
		CompositionFilter.Items.Clear();
	EndIf;

EndProcedure

#EndRegion
