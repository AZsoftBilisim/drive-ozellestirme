#Region FormEventHandlers

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If Not IsBaseVersion Then
		Items.CategoryType.WarningOnEditRepresentation =
			WarningOnEditRepresentation.Show;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CategoryType = ?(Record.ExcisableGoods, 1, 0);
	UseMultiCountryAccounting = GetFunctionalOption("UseMultiCountryAccounting");
	IsBaseVersion = GetFunctionalOption("BaseVersion");
	SetVisibilityAndPresentationOfElements();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Products");
	NotificationParameters.Insert("Country");
	NotificationParameters.Insert("Period");
	FillPropertyValues(NotificationParameters, Record);
	
	Notify("Recording_ExciseCategoryOfItem", NotificationParameters, FormOwner);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Recording_ExciseCategory"
		And Source = Record.ExcisableGoodsCategory Then
		
		SetVisibilityAndPresentationOfElements();
		NotificationParameters = New Structure;
		NotificationParameters.Insert("Products");
		NotificationParameters.Insert("Country");
		NotificationParameters.Insert("Period");
		FillPropertyValues(NotificationParameters, Record);
		Notify("Recording_ExciseCategoryOfItem", NotificationParameters, FormOwner);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Record.ExcisableGoods
	And ItSFirmBet
	And Not ValueIsFilled(Record.ConversionFactor_) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền giá trị hệ số tính lại';
				|ru = 'Не заполнено значение коэффициента пересчета';
				|en = 'Conversion ratio value is required'; fa = 'Conversion ratio value is required';
				|it = 'Conversion ratio value is required';
				|pl = 'Conversion ratio value is required';
				|tr = 'Dönüştürme oranı değeri doldurulmadı'"),
			,
			"Record.ConversionFactor_",
			,
			Cancel);
	EndIf;
	
	If ThereIsAnotherEntry() Then
		If UseMultiCountryAccounting Then
			Message = NStr("vi = 'Đối với mặt hàng ""%1"" theo quốc gia ""%2"" vào ngày %3 đã đặt tùy chỉnh thể loại chịu thuế TTĐB.';
							|ru = 'Для номенклатуры ""%1"" по стране ""%2"" на дату %3 уже заданы настройки подакцизной категории.';
							|en = 'The excise category settings are already set for the ""%1"" item for the ""%2"" country as of %3.'; fa = 'The excise category settings are already set for the ""%1"" item for the ""%2"" country as of %3.';
							|it = 'The excise category settings are already set for the ""%1"" item for the ""%2"" country as of %3.';
							|pl = 'The excise category settings are already set for the ""%1"" item for the ""%2"" country as of %3.';
							|tr = '%3 tarihinde ""%2"" ülke kapsamındaki ""%1"" öğesi için, tüketim vergisine tabi kategori ayarları zaten yapıldı.'");
			Message = StrTemplate(Message, Record.Products, Record.Country, Format(Record.Period, "DLF=D"));
		Else
			Message = NStr("vi = 'Đối với mặt hàng ""%1"" vào ngày %2 đã đặt các tùy chỉnh thể loại chịu thuế TTĐB.';
							|ru = 'Для номенклатуры ""%1"" на дату %2 уже заданы настройки подакцизной категории.';
							|en = 'The excise category settings are already set for the ""%1"" item as of %2.'; fa = 'The excise category settings are already set for the ""%1"" item as of %2.';
							|it = 'The excise category settings are already set for the ""%1"" item as of %2.';
							|pl = 'The excise category settings are already set for the ""%1"" item as of %2.';
							|tr = '%2 tarihinde  ""%1"" öğesi için, tüketim vergisine tabi kategori ayarları zaten yapıldı.'");
			Message = StrTemplate(Message, Record.Products, Format(Record.Period, "DLF=D"));
		EndIf;
		
		ShowMessageBox(,Message);
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ExcisableGoodsCategoryOnChange(Item)
	
	If ValueIsFilled(Record.ExcisableGoodsCategory) Then
		Record.ConversionFactor_ = 0;
	EndIf;

	SetVisibilityAndPresentationOfElements();
	
EndProcedure

&AtClient
Procedure ExcisableGoodsOnChange(Item)
	
	If Not Record.ExcisableGoods 
		And ValueIsFilled(Record.ExcisableGoodsCategory) Then
		Record.ExcisableGoodsCategory = Undefined;
		Record.ConversionFactor_ = 0;
	EndIf;
	
	SetVisibilityAndPresentationOfElements();
	
EndProcedure

&AtClient
Procedure CategoryTypeOnChange(Item)
	
	If CategoryType = 0 Then
		Record.ExcisableGoods = False;
	Else
		Record.ExcisableGoods = True;
	EndIf;

	If Not Record.ExcisableGoods 
		And ValueIsFilled(Record.ExcisableGoodsCategory) Then
		Record.ExcisableGoodsCategory = Undefined;
		Record.ConversionFactor_ = 0;
	EndIf;
	
	SetVisibilityAndPresentationOfElements();
	
EndProcedure

#EndRegion

#Region Private 

&AtServer
Procedure SetVisibilityAndPresentationOfElements()
	
	If ValueIsFilled(Record.Products) Then
		Items.Products.ReadOnly = True;
	EndIf;

	If Not UseMultiCountryAccounting Then
		Items.Country.Visible = False;
	EndIf;

	ItSFirmBet = False;
	UnitsAreDifferent = False;
	
	If Record.ExcisableGoods And Not IsBaseVersion Then
		Items.ExcisableGoodsCategory.Enabled = True;
		
		CategoryDetails = Undefined;
		
		If ValueIsFilled(Record.ExcisableGoodsCategory) Then
			
			CategoryDetails = Common.ObjectAttributesValues(Record.ExcisableGoodsCategory, "RateType, UnitOfMeasure");
			ItSFirmBet = CategoryDetails.RateType = Enums.TypesOfExcisableCategoryRates.FixedRate;
			
			If ItSFirmBet
				And ValueIsFilled(Record.Products) Then
				Items.CategoryOfExcisableGoodsUnitOfCat.Visible = True;
				UnitOfProductMeasurement_ = Common.ObjectAttributeValue(Record.Products, "UnitOfMeasure");
				
				If UnitOfProductMeasurement_ <> CategoryDetails.UnitOfMeasure Then
					UnitsAreDifferent = True;
					TitleText = NStr("vi = 'Trong 1 %1.';
									|ru = 'В 1 %1.';
									|en = 'In 1 %1.'; fa = 'In 1 %1.';
									|it = 'In 1 %1.';
									|pl = 'In 1 %1.';
									|tr = '1 %1 dahilinde.'");
					TitleText = StringFunctionsClientServer.SubstituteParametersToString(TitleText, TrimAll(String(UnitOfProductMeasurement_)));
					Items.ConversionFactor_.Title = TitleText;
				Else
					Record.ConversionFactor_ = 1;
				EndIf;
			ElsIf Record.ConversionFactor_ <> 0 Then
				Record.ConversionFactor_ = 0;
			EndIf;
			
		EndIf;
				
	Else
		Items.ExcisableGoodsCategory.Enabled = False;
	EndIf;
	
	If IsBaseVersion Then
		Items.ExcisableGoodsCategory.Visible = False;
	EndIf;

	Items.UnitOfMeasurementGroup.Visible = ItSFirmBet And UnitsAreDifferent;
	Items.ConversionFactor_.Enabled = ItSFirmBet;
	Items.CategoryOfExcisableGoodsUnitOfCat.Visible = ItSFirmBet;

EndProcedure

&AtServer
Function ThereIsAnotherEntry()
	
	Result = False;
	
	If Not (Record.Period = Record.SourceRecordKey.Period
		And Record.Products = Record.SourceRecordKey.Products
		And Record.Country = Record.Country) Then
			
		EntryYouAreLookingFor = InformationRegisters.ExcisableGoodsCategories.CreateRecordManager();
		EntryYouAreLookingFor.Period = Record.Period;
		EntryYouAreLookingFor.Products = Record.Products;
		EntryYouAreLookingFor.Country = Record.Country;
		EntryYouAreLookingFor.Read();
		Result = EntryYouAreLookingFor.Selected();
		
	EndIf;

	Return Result;
	
EndFunction

#EndRegion
