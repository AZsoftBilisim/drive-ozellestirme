 
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	UseMultiCountryAccounting = GetFunctionalOption("UseMultiCountryAccounting");
	Items.TypesOfPricesCountry.Visible = UseMultiCountryAccounting;
	
	If Parameters.Property("ArrayOfPriceTypes") Then
		For Each ArrayRow In Parameters.ArrayOfPriceTypes Do
			PriceViewString = TypesOfPrices.Add();
			FillPropertyValues(PriceViewString, ArrayRow);
		EndDo;
	EndIf;
	
	If Parameters.Property("OnlySelectedItems") Then
		SelectedLinesOnly = Parameters.OnlySelectedItems;
	EndIf;
	
	If Parameters.Property("ValidityDate") Then
		ValidityDate = Parameters.ValidityDate;
	EndIf;
	
	VATAccountingLocalization.SetUpFormForFillingInVATRates(ThisObject, ValidityDate);
	
	ChangeConvolutionOfGroup(Items, True);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CollapseExpandGroup(Item)
	
	ChangeConvolutionOfGroup(Items);
	
EndProcedure

&AtClient
Procedure GoodsOwnerOnChange(Item)
	
	If Not ValueIsFilled(GoodsOwner) Then
		Return;
	EndIf;
	GetCounterpartyTaxationATServer(GoodsOwner, ValidityDate, VATRate);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeVATRate(Command)
		
	ArrayOfPriceTypes = New Array();
	For Each PriceKind In TypesOfPrices Do
		If PriceKind.ShouldRecalculate Then
			ArrayOfPriceTypes.Add(PriceKind.PriceKind);
		EndIf;
	EndDo;
	
	Result = New Structure();
	Result.Insert("SelectedTypesOfPrices",			ArrayOfPriceTypes);
	Result.Insert("SelectedLinesOnly",	SelectedLinesOnly = 1);
	Result.Insert("ValidityDate",				ValidityDate);
	
	If Items.VATRateGroup.Visible Then
		Result.Insert("VATRate", CatalogVATRate);
	Else
		Result.Insert("VATRate", VATRate);
	EndIf;
		
	Close(Result);
	
EndProcedure

&AtClient
Procedure PriceTypesSelectAll(Command)
	
	For Each PriceKind In TypesOfPrices Do
		If Not PriceKind.ShouldRecalculate Then
			PriceKind.ShouldRecalculate = True;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure PriceTypesExcludeAll(Command)
	
	For Each PriceKind In TypesOfPrices Do
		If PriceKind.ShouldRecalculate Then
			PriceKind.ShouldRecalculate = False;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure ChangeConvolutionOfGroup(Items, GroupBy = Undefined)
	
	Items.SettingsGroupIsCollapsible.Visible = ?(GroupBy = Undefined, Not Items.SettingsGroupIsCollapsible.Visible, Not GroupBy);
	Items.SceneryOpen.Visible = ?(GroupBy = Undefined, Not Items.SceneryOpen.Visible, GroupBy);
	Items.DecorationClose.Visible = ?(GroupBy = Undefined, Not Items.DecorationClose.Visible, Not GroupBy);
	
EndProcedure

&AtServerNoContext
Procedure GetCounterpartyTaxationATServer(Counterparty, ValidityDate, VATRate)
	
	PartnersAndCounterpartiesLocalization.GetCounterpartyTaxation(Counterparty, ValidityDate, VATRate);
	
EndProcedure

#EndRegion