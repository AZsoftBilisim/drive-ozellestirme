#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	EditRight = AccessRight("Update", Metadata.InformationRegisters.ProductsVATRates);
	Items.ProductsVATRatesAdd.Visible = EditRight;
	Items.ProductsVATRatesDelete.Visible = EditRight;
	
	Products = Parameters.Products;
	If Not GetFunctionalOption("UseMultiCountryAccounting") Then
		Country = SettingsValueClientServerCached.MainCountry();
	EndIf;
	
	VATRate = InformationRegisters.ProductsVATRates.CurrentVATRateOfProductByMainCountry(Products);
	
	ReadProductVATRates();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		BidUpdated = ValueIsFilled(CurrentVATRate)
								And VATRate <> CurrentVATRate;
		
		NotifyChoice(BidUpdated);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ProductsVATRates"
		And Source.Products = Products Then
		
		ReadProductVATRates();
		
		If Parameter.Property("ThisIsCurrentRate")
			And Parameter.ThisIsCurrentRate Then
			
			VATRate = CurrentVATRate;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure ProductsVATRatesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData =  ProductsVATRates.FindByID(RowSelected);
	
	Filter = New Structure();
	Filter.Insert("Products", Products);
	Filter.Insert("Country", CurrentData.Country);
	Filter.Insert("Period", CurrentData.Period);
	
	FormParameters = New Structure;
	
	If CurrentData.BasicRate Then
		Filter.Insert("VATRate", CurrentData.VATRate);
		FormParameters.Insert("FillingValues", Filter);
	ElsIf CurrentData.EmptyRate Then    
		FormParameters.Insert("FillingValues", Filter);	
	Else
		
		CheckSetEmptyCountryInSelection(Filter);
		
		ArrayFilter = New Array;
		ArrayFilter.Add(Filter);
		RecordKey = New("InformationRegisterRecordKey.ProductsVATRates", ArrayFilter);
		FormParameters.Insert("Key", RecordKey);
	EndIf;
	
	OpenForm("InformationRegister.ProductsVATRates.Form.RecordForm", 
				FormParameters, ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure PeriodOnChange(Item)
	ReadProductVATRates();
EndProcedure

&AtClient
Procedure CountryOnChange(Item)
	ReadProductVATRates();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Delete(Command)
	
	CurrentRow = Items.ProductsVATRates.CurrentData;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If CurrentRow.BasicRate Then
		ClearMessages();
		CommonClient.MessageToUser(NStr("vi = 'Đã cấm xóa thuế suất thuế GTGT chính';
										|ru = 'Удаление основной ставки НДС запрещено';
										|en = 'Cannot delete the main VAT rate'; fa = 'Cannot delete the main VAT rate';
										|it = 'Удаление основной ставки НДС запрещено';
										|pl = 'Cannot delete the main VAT rate';
										|tr = 'Temel KDV oranının silinmesi yasaktır'"));
		Return;
	EndIf;
	
	If ProductsVATRates.Count() = 1 Then
		ClearMessages();
		CommonClient.MessageToUser(NStr("vi = 'Đã cấm xóa bản ghi duy nhất';
										|ru = 'Удаление единственной записи запрещено';
										|en = 'Cannot delete the only record'; fa = 'Cannot delete the only record';
										|it = 'Удаление единственной записи запрещено';
										|pl = 'Cannot delete the only record';
										|tr = 'Tek kaydın silinmesi yasaktır'"));
		Return;
	EndIf;
	
	OldVATRate = CurrentVATRate;
	
	Filter = New Structure();
	Filter.Insert("Period", CurrentRow.Period);
	Filter.Insert("Products", Products);
	Filter.Insert("Country", CurrentRow.Country);
	
	DeleteRecordServer(Filter);
	
	If OldVATRate <> CurrentVATRate Then
		NotificationParameters = New Structure("ThisIsCurrentRate", True);
		SourceStructure = New Structure("Products", Products);
		Notify("Write_ProductsVATRates", NotificationParameters, SourceStructure);
	EndIf;
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	ReadProductVATRates();
EndProcedure

&AtClient
Procedure Add(Command)
	
	Filter = New Structure();
	Filter.Insert("Products", Products);
	If ValueIsFilled(Country) Then
		Filter.Insert("Country", Country);
	EndIf;
	
	FormParameters = New Structure();
	FormParameters.Insert("FillingValues", Filter);
	
	OpenForm("InformationRegister.ProductsVATRates.Form.RecordForm", 
				FormParameters, ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsVATRatesVATRate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductsVATRates.BasicRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsVATRatesPeriod.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductsVATRates.Period");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Date("19800101");

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Giá trị ban đầu';
													|ru = 'Начальное значение';
													|en = 'Initial value'; fa = 'مقدار اولیه';
													|it = 'Valore iniziale';
													|pl = 'Wartość początkowa';
													|tr = 'İlk değer'"));
	
EndProcedure

&AtServer
Procedure ReadProductVATRates()
	
	TableOfVATRates = InformationRegisters.ProductsVATRates.TableOfProductVATRates(Products, Country, Period);
	ProductsVATRates.Load(TableOfVATRates);
	
	CurrentVATRate = InformationRegisters.ProductsVATRates.CurrentVATRateOfProductByMainCountry(
							Products);
	
EndProcedure

&AtServer
Procedure DeleteRecordServer(Filter)
	
	RecordSet = InformationRegisters.ProductsVATRates.CreateRecordSet();
	RecordSet.Filter.Period.Set(Filter.Period);
	RecordSet.Filter.Products.Set(Filter.Products);
	RecordSet.Filter.Country.Set(Filter.Country);
	
	RecordSet.Read();
	
	If RecordSet.Count() = 0 Then
		RecordSet = InformationRegisters.ProductsVATRates.CreateRecordSet();
		RecordSet.Filter.Period.Set(Filter.Period);
		RecordSet.Filter.Products.Set(Filter.Products);
	EndIf;
	
	RecordSet.Clear();
	RecordSet.Write();
	
	ReadProductVATRates();
	
EndProcedure

&AtServer
Procedure CheckSetEmptyCountryInSelection(Filter)
	
	RecordSet = InformationRegisters.ProductsVATRates.CreateRecordSet();
	RecordSet.Filter.Period.Set(Filter.Period);
	RecordSet.Filter.Products.Set(Filter.Products);
	RecordSet.Filter.Country.Set(Filter.Country);
	
	RecordSet.Read();
	
	If RecordSet.Count() = 0 Then
		Filter.Country = Catalogs.WorldCountries.EmptyRef();
	EndIf;
	
EndProcedure

#EndRegion
