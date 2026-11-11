
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	FormCode = "ImportVendorPricesFromFile";
	
	Object.Partner = Parameters.Partner;
	TableOfPriceTypes = SettingPricesServer.DownloadSupplierSPriceCatalog(ThisForm);
	
	For Each TSRow In TableOfPriceTypes Do
		
		NewRow = SelectedPrices.Add();
		FillPropertyValues(NewRow, TSRow);
		NewRow.Selected_5 = Not Parameters.SelectedTypesOfPrices.Find(TSRow.Ref) = Undefined;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_VendorPriceTypes"
		And Parameter.Partner = Object.Partner Then
		
		ReReadVendorPriceTypesOnServer();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSelectedPrices

&AtClient
Procedure SelectedPricesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
	Filter = New Structure;
	Filter.Insert("Owner", Object.Partner);
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", Filter);
	
	OpenForm("Catalog.VendorPriceTypes.Form.ItemForm", FormParameters, ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	UpdateOrder = False;
	IndexOf = 1;
	For Each TSRow In SelectedPrices Do
		If TSRow.AddlOrderingAttribute <> IndexOf Then
			UpdateOrder = True;
		EndIf;
		IndexOf = IndexOf + 1;
	EndDo;
	
	If UpdateOrder Then
		SaveSettingsForOrderOfSupplierPriceTypes();
	EndIf;
	
	NotifyChoice(SettingPricesClientServer.SelectedTypesOfPrices(ThisForm));
	
EndProcedure

&AtClient
Procedure SelectAllPriceTypes(Command)
	
	For Each TableRow In SelectedPrices Do
		If Not TableRow.Selected_5 And Not TableRow.ProhibitedPriceType Then
			TableRow.Selected_5 = True;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearAllPriceTypes(Command)
	
	For Each TableRow In SelectedPrices Do
		If TableRow.Selected_5 And Not TableRow.ProhibitedPriceType Then
			TableRow.Selected_5 = False;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedPrices.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedPrices.DeletionMark");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

EndProcedure

#Region Other

&AtServer
Procedure SaveSettingsForOrderOfSupplierPriceTypes()
	
	SettingPricesServer.SaveSettingsForOrderOfSupplierPriceTypes(ThisForm);
	
EndProcedure

&AtServer
Procedure ReReadVendorPriceTypesOnServer()
	
	SettingPricesServer.ReReadSelectedPrices(ThisForm);
	
EndProcedure

#EndRegion

#EndRegion