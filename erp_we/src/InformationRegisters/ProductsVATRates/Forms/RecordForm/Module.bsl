#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Record.Products) Then
		Items.Products.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ProductsVATRates", WriteParameters, Record);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	CurrentVATRateOfProductItem = InformationRegisters.ProductsVATRates.CurrentVATRateOfProductByMainCountry(
										CurrentObject.Products);
	ThisIsCurrentRate = CurrentObject.VATRate = CurrentVATRateOfProductItem;
	
	WriteParameters.Insert("ThisIsCurrentRate", ThisIsCurrentRate);
	
EndProcedure

#EndRegion
