
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Address = Undefined;
	Parameters.Property("Address", Address);
	SelectionOfProductsSetting = GetFromTempStorage(Address);
	DeleteFromTempStorage(Address);
	
	DataCompositionSchema = DataProcessors.WarehouseGoodsIssueReceiptWizard.GetTemplate("ItemFilterMain");
	DataProcessors.WarehouseGoodsIssueReceiptWizard.RedefineQueryTextOfTemplateSelectionOfMainItem(DataCompositionSchema);
	URLSchemes = PutToTempStorage(DataCompositionSchema, New UUID());
	SettingsSource = New DataCompositionAvailableSettingsSource(URLSchemes);
	FilterOfProductItem.Initialize(SettingsSource);
	FilterOfProductItem.LoadSettings(SelectionOfProductsSetting);
	FilterOfProductItem.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OKButton(Command)
	
	Close(PlaceProductSelectionSettingsToTemporaryStorage(FilterOfProductItem));
	
EndProcedure

&AtClient
Procedure CancelButton(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function PlaceProductSelectionSettingsToTemporaryStorage(FilterOfProductItem)
	SelectionOfProductsSetting = FilterOfProductItem.GetSettings();
	Return PutToTempStorage(SelectionOfProductsSetting);
EndFunction

#EndRegion
