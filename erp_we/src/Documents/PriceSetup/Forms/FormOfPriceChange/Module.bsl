
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	DownloadPriceTypes();
	
	SelectedLinesOnly = Parameters.OnlySelectedItems;
	ApplyRounding    = True;
	
	Items.SelectedLinesOnly.Title = NStr("vi = 'Cập nhật lại các dòng trong chứng từ';
										|ru = 'Пересчитать строки документа';
										|en = 'Recalculate document lines'; fa = 'محاسبه مجدد سطرهای سند';
										|it = 'Ricalcola le stringhe del documento';
										|pl = 'Przelicz wiersze dokumentu';
										|tr = 'Belge satırlarını yeniden hesapla'");

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTypesOfPrices

&AtClient
Procedure TypesOfPricesChangePercentageOnChange(Item)
	
	CurrentData = Items.TypesOfPrices.CurrentData;
	CurrentData.ShouldRecalculate = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ArrayOfPriceTypes = New Array();
	For Each PriceKind In TypesOfPrices Do
		If PriceKind.ShouldRecalculate Then
			ArrayOfPriceTypes.Add(New Structure("PriceKind, Price", PriceKind.Ref, PriceKind.Price));
		EndIf;
	EndDo;
	
	Result = New Structure();
	Result.Insert("TypesOfPrices",                        ArrayOfPriceTypes);
	Result.Insert("SelectedLinesOnly",         SelectedLinesOnly = 1);
	
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
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

// The procedure loads the price types in the price Types table in the order
// that corresponds to the order in the document.
&AtServer
Procedure DownloadPriceTypes()
	
	Query = New Query();
	Query.Text = "SELECT
		|	TypesOfPrices.Ref            AS Ref,
		|	TypesOfPrices.PricingMethod AS PricingMethod,
		|	CASE
		|		WHEN
		|			TypesOfPrices.PricingMethod = VALUE(Enum.PriceSettingMethods.Manually)
		|		THEN
		|			0
		|		WHEN
		|			TypesOfPrices.PricingMethod = VALUE(Enum.PriceSettingMethods.FillInByInfobaseData)
		|		THEN
		|			1
		|		WHEN
		|			TypesOfPrices.PricingMethod = VALUE(Enum.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes)
		|		THEN
		|			2
		|	END AS PictureIndex
		|FROM
		|	Catalog.TypesOfPrices AS TypesOfPrices
		|WHERE
		|	TypesOfPrices.Ref IN(&ArrayOfPriceTypes)";
		
	Query.SetParameter("ArrayOfPriceTypes", Parameters.AllKindsOfPrices);
	TableOfPriceTypes = Query.Execute().Unload();
	
	// In order for the types of prices in the list to be in the same order as on the document form,
	// we load them manually.
	For Each PricesKind In Parameters.AllKindsOfPrices Do
		
		FoundTypeOfPrices = TableOfPriceTypes.Find(PricesKind, "Ref");
		
		PriceViewString                   = TypesOfPrices.Add();
		PriceViewString.Ref            = PricesKind;
		PriceViewString.PricingMethod = FoundTypeOfPrices.PricingMethod;
		PriceViewString.ShouldRecalculate       = False;
		PriceViewString.PictureIndex    = FoundTypeOfPrices.PictureIndex;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion
