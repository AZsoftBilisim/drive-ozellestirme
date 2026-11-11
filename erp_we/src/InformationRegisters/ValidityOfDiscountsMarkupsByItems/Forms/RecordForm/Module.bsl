
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);
	
	FormData1 = New Structure;
	FormData1.Insert("Source");
	FormData1.Insert("Products");
	FormData1.Insert("Characteristic");
	
	If Parameters.Key.Source <> Undefined Then
		FormData1.Source = Parameters.Key.Source;
	EndIf;
	If Parameters.FillingValues.Property("Source")
		And Parameters.FillingValues.Source <> Undefined Then
		FormData1.Source = Parameters.FillingValues.Source;
	EndIf;
	
	If ValueIsFilled(Parameters.Key.Products) Then
		FormData1.Products = Parameters.Key.Products;
	EndIf;
	If Parameters.FillingValues.Property("Products")
		And ValueIsFilled(Parameters.FillingValues.Products) Then
		FormData1.Products = Parameters.FillingValues.Products;
	EndIf;
	If ValueIsFilled(Parameters.Key.Characteristic) Then
		FormData1.Characteristic = Parameters.Key.Characteristic;
	EndIf;
	If Parameters.FillingValues.Property("Characteristic")
		And ValueIsFilled(Parameters.FillingValues.Characteristic) Then
		FormData1.Characteristic = Parameters.FillingValues.Characteristic;
	EndIf;
	
	If ValueIsFilled(FormData1.Source) Then
		Items.Source.ReadOnly = True;
	EndIf;
	
	If ValueIsFilled(FormData1.Products) Then
		Items.Products.ReadOnly = True;
		Items.Characteristic.ReadOnly = True;
	EndIf;
	
	If Items.Source.ReadOnly And Items.Products.ReadOnly Then
		Items.Pages.CurrentPage = Items.PageEditingIsProhibited;
		Items.HyperlinkFeature.Visible = ValueIsFilled(FormData1.Characteristic);
		Items.Characteristic.Visible = ValueIsFilled(FormData1.Characteristic);
	EndIf;
	
	If Items.Source.ReadOnly Then
		
		If TypeOf(FormData1.Source) = Type("CatalogRef.DiscountsMarkups") Then
			Items.SourceHyperlink.Title = NStr("vi = 'Chiết khấu (phụ thu)';
												|ru = 'Скидка (наценка)';
												|en = 'Discount (markup)'; fa = 'تخفیف (افزایش قیمت)';
												|it = 'Sconto (sovrapprezzo)';
												|pl = 'Rabat (marża)';
												|tr = 'İndirim (zam)'");
		ElsIf TypeOf(FormData1.Source) = Type("CatalogRef.DiscountMarkupTerms") Then
			Items.SourceHyperlink.Title = NStr("vi = 'Điều kiện cho phép';
												|ru = 'Условие предоставления';
												|en = 'Term'; fa = 'شرط';
												|it = 'Condizione della concessione';
												|pl = 'Warunek nadania';
												|tr = 'Sağlama şartı'");
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ArraySources = New Array;
	ArraySources.Add(Record.Source);
	
	Parameter = New Structure;
	Parameter.Insert("Source", ArraySources);
	
	Notify("Write_ValidityOfDiscountsMarkupsByItems", Parameter, ThisForm);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Not ValueIsFilled(CurrentObject.EmployeeResponsible) Then
		CurrentObject.EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
EndProcedure

#EndRegion