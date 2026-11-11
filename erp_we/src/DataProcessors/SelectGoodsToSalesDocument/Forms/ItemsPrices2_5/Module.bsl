
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Title = Title + ": "+ Parameters.Products;
	
	If ValueIsFilled(Parameters.Characteristic) Then
		Items.ListCharacteristic.Visible = False;
		Title = Title + " ("+ Parameters.Characteristic + ")";
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(List, "Date", Parameters.Date);
	CommonClientServer.SetDynamicListParameter(List, "Products", Parameters.Products);
	CommonClientServer.SetDynamicListParameter(List, "Characteristic", Parameters.Characteristic);
	CommonClientServer.SetDynamicListParameter(List, "Series", Catalogs.ItemsBatches.EmptyRef());
	CommonClientServer.SetDynamicListParameter(List, "Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
		
	AddDynamicListSelection();
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

#EndRegion
#Region Private

&AtServer
Procedure AddDynamicListSelection()
	
	Var ListOfOwnersSelection;
	
	CommonClientServer.SetFilterItem(List.Filter, "PriceKind.Status",                 Enums.StatusesOfPriceTypeValidity.Valid);
	CommonClientServer.SetFilterItem(List.Filter, "PriceKind.AuxiliaryPrice",    False);
	CommonClientServer.SetFilterItem(List.Filter, "PriceKind.UseWhileSellingToCustomers", True);
	
	If Parameters.Property("ObjectForStoringSalesTermsAndConditions") Then
		ListOfOwnersSelection = New ValueList();
		ListOfOwnersSelection.Add(Catalogs.Partners.EmptyRef());
		ListOfOwnersSelection.Add(Parameters.ObjectForStoringSalesTermsAndConditions);
		CommonClientServer.SetFilterItem(List.Filter, "ObjectForStoringSalesTermsAndConditions", ListOfOwnersSelection);
	Else
		CommonClientServer.SetFilterItem(List.Filter, "PriceKind.Purpose", Enums.PriceTypesAssignment.Shared);
	EndIf;

EndProcedure

#EndRegion