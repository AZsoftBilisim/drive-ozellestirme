#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	For Each Record In ThisObject Do
		If Record.Products = Catalogs.Products.EmptyRef()
			Or Record.Products = Catalogs.ProductSegments.EmptyRef() Then
			Record.Products = Undefined;
		EndIf;
		If Record.Partner = Catalogs.Partners.EmptyRef()
			Or Record.Partner = Catalogs.PartnersSegments.EmptyRef() Then
			Record.Partner = Undefined;
		EndIf;
	EndDo;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If FillingData = Undefined Then
		FillingData = New Structure;
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure")
	   And Not FillingData.Property("LineOfBusinessAllocationMethod")
	Then
		FillingData.Insert("LineOfBusinessAllocationMethod", Catalogs.LinesOfBusiness.EmptyRef());
	EndIf;
	
EndProcedure

#EndRegion

#EndIf