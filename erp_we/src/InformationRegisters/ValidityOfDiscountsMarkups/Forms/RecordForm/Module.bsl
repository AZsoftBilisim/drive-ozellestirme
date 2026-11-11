
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);
	
	FormData1 = New Structure;
	FormData1.Insert("Source");
	FormData1.Insert("DiscountMarkup");
	
	If Parameters.Key.Source <> Undefined Then
		FormData1.Source = Parameters.Key.Source;
	EndIf;
	If Parameters.FillingValues.Property("Source")
		And Parameters.FillingValues.Source <> Undefined Then
		FormData1.Source = Parameters.FillingValues.Source;
	EndIf;
	
	If ValueIsFilled(Parameters.Key.DiscountMarkup) Then
		FormData1.DiscountMarkup = Parameters.Key.DiscountMarkup;
	EndIf;
	If Parameters.FillingValues.Property("DiscountMarkup")
		And ValueIsFilled(Parameters.FillingValues.DiscountMarkup) Then
		FormData1.DiscountMarkup = Parameters.FillingValues.DiscountMarkup;
	EndIf;
	
	If ValueIsFilled(FormData1.Source) Or FormData1.Source = Catalogs.Warehouses.EmptyRef() Then
		Items.Source.ReadOnly = True;
	EndIf;
	
	If ValueIsFilled(FormData1.DiscountMarkup) Or FormData1.Source = Catalogs.Warehouses.EmptyRef() Then
		Items.DiscountMarkup.ReadOnly = True;
	EndIf;
	
	If Items.Source.ReadOnly And Items.DiscountMarkup.ReadOnly Then
		Items.PagesDiscountMarkup.CurrentPage = Items.PageEditingIsProhibited;
	EndIf;
	
	If Items.Source.ReadOnly Then
		
		If TypeOf(FormData1.Source) = Type("CatalogRef.Warehouses") Then
			Items.SourceHyperlink.Title = NStr("vi = 'Kho bãi';
												|ru = 'Склад';
												|en = 'Warehouse'; fa = 'Warehouse';
												|it = 'Magazzino';
												|pl = 'Magazyn';
												|tr = 'Ambar'");
		ElsIf TypeOf(FormData1.Source) = Type("CatalogRef.TermsOfSale") Then
			Items.SourceHyperlink.Title = NStr("vi = 'Thỏa thuận';
												|ru = 'Соглашение';
												|en = 'Agreement'; fa = 'توافق‌نامه';
												|it = 'Accordo';
												|pl = 'Porozumienie:';
												|tr = 'Anlaşma'");
		ElsIf TypeOf(FormData1.Source) = Type("CatalogRef.LoyaltyCardKinds") Then
			Items.SourceHyperlink.Title = NStr("vi = 'Dạng thẻ khách hàng thân thiết';
												|ru = 'Вид карты лояльности';
												|en = 'Loyalty card kind'; fa = 'نوع کارت وفاداری';
												|it = 'Tipo di carta di fedeltà';
												|pl = 'Rodzaj karty lojalnościowej';
												|tr = 'Sadakat kartı türü'");
		EndIf;
		
		If FormData1.Source = Catalogs.Warehouses.EmptyRef() Then
			Items.SourceHyperlink.Visible = False;
			Items.Source.Visible = False;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ArrayDiscountsMargins = New Array;
	ArraySources = New Array;
	
	ArrayDiscountsMargins.Add(Record.DiscountMarkup);
	ArraySources.Add(Record.Source);
	
	Parameter = New Structure;
	Parameter.Insert("DiscountMarkup", ArrayDiscountsMargins);
	Parameter.Insert("Source", ArraySources);
	
	Notify("Write_ValidityOfDiscountsMarkups", Parameter, ThisForm);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Not ValueIsFilled(CurrentObject.EmployeeResponsible) Then
		CurrentObject.EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
EndProcedure

#EndRegion