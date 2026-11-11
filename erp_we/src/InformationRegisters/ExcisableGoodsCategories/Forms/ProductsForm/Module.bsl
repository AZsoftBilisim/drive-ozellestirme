#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	EditRight = AccessRight("Update", Metadata.InformationRegisters.ExcisableGoodsCategories);
	Items.ExciseCategoriesOfItemsAdd.Visible = EditRight;
	Items.ExciseCategoriesOfItemsDelete.Visible = EditRight;
	Items.ExciseCategoriesOfItemsEdit.Visible = EditRight;
	
	Products = Parameters.Products;
	If Not GetFunctionalOption("UseMultiCountryAccounting") Then
		Country = SettingsValueClientServerCached.MainCountry();
	EndIf;
	
	AutoTitle = False;
	UnitOfProductMeasurement_ = Common.ObjectAttributeValue(Products, "UnitOfMeasure");
	HeaderTex = NStr("vi = 'Thể loại hàng hóa chịu thuế TTĐB ""%1"" (%2)';
					|ru = 'Категории подакцизного товара ""%1"" (%2)';
					|en = '""%1"" (%2) excisable goods categories'; fa = '""%1"" (%2) excisable goods categories';
					|it = '""%1"" (%2) excisable goods categories';
					|pl = '""%1"" (%2) excisable goods categories';
					|tr = 'Tüketim vergisine tabi ürün kategorileri ""%1"" (%2)'");
	Title = StringFunctionsClientServer.SubstituteParametersToString(HeaderTex,
		TrimAll(String(Products)), TrimAll(String(UnitOfProductMeasurement_)));
	
	If Parameters.CurrentPeriod Then
		Period = CurrentSessionDate();
		Items.Period.ReadOnly = True;
	EndIf;
	
	ReadItemCategories();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Recording_ExciseCategoryOfItem"
		And Parameter.Products = Products And Source = ThisObject Then
		TheStructureOfTheSearch = New Structure("Period, Country");
		FillPropertyValues(TheStructureOfTheSearch, Parameter);
		ReadItemCategories(TheStructureOfTheSearch);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PeriodOnChange(Item)
	ReadItemCategories();
EndProcedure

&AtClient
Procedure CountryOnChange(Item)
	ReadItemCategories();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersExciseCategoriesOfItems

&AtClient
Procedure ExciseCategoriesOfItemsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData =  ExciseCategoriesOfItems.FindByID(RowSelected);
	OpenEditForm(CurrentData);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Delete(Command)
	
	CurrentRow = Items.ExciseCategoriesOfItems.CurrentData;
	If CurrentRow = Undefined Then
		Return;
	Else
		EndOfDeletion = New CallbackDescription("CompleteDeletionOfRecord",
			ThisObject, CurrentRow);
			
		ShowQueryBox(EndOfDeletion,
			NStr("vi = 'Xóa bản ghi đã chọn?';
				|ru = 'Удалить выбранную запись?';
				|en = 'Delete the selected record?'; fa = 'Delete the selected record?';
				|it = 'Delete the selected record?';
				|pl = 'Delete the selected record?';
				|tr = 'Seçilen kayıt silinsin mi?'"),
			QuestionDialogMode.YesNo,
			,
			DialogReturnCode.No);
	EndIf;
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	ReadItemCategories();
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
	
	OpenForm("InformationRegister.ExcisableGoodsCategories.Form.RecordForm", 
				FormParameters, ThisObject,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Edit(Command)
	
	If Items.ExciseCategoriesOfItems.CurrentData <> Undefined Then
		OpenEditForm(Items.ExciseCategoriesOfItems.CurrentData);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExciseCategoriesOfItemsRate1.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExciseCategoriesOfItemsCategoryUnitOfMeasurement.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExciseCategoriesOfItemsConversionFactor_.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExciseCategoriesOfItems.RateType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Enum.TypesOfExcisableCategoryRates.AdValoremRate");
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExciseCategoriesOfItemsCurrency.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExciseCategoriesOfItems.RateType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Enum.TypesOfExcisableCategoryRates.AdValoremRate");
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExciseCategoriesOfItemsExcisableGoodsCategory.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExciseCategoriesOfItems.RateType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Enum.TypesOfExcisableCategoryRates.FixedRate");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExciseCategoriesOfItems.ExcisableGoodsCategory");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa được đặt>';
													|ru = '<не задана>';
													|en = '<not set>'; fa = '<تنظیم نشده>';
													|it = '<non impostato>';
													|pl = '<nie ustalona>';
													|tr = '<ayarlanmadı>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExciseCategoriesOfItemsConversionFactor_.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExciseCategoriesOfItems.RateType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Enum.TypesOfExcisableCategoryRates.FixedRate");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExciseCategoriesOfItems.ConversionFactor_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa đặt>';
													|ru = '<не задан>';
													|en = '<not specified>'; fa = '<مشخص نشده>';
													|it = '<non impostato>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExciseCategoriesOfItemsRate1.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExciseCategoriesOfItemsCurrency.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Period");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

&AtServer
Procedure ReadItemCategories(FilterParameters = Undefined)
	
	ExciseDutyTable = ExcisableGoodsAccounting.GetHistoryOfItemCategories(Products, Country, Period);
	ExciseCategoriesOfItems.Load(ExciseDutyTable);
	If FilterParameters <> Undefined Then
		TableRows = ExciseCategoriesOfItems.FindRows(FilterParameters);
		If ValueIsFilled(TableRows) Then
			RowID = TableRows[0].GetID();
			Items.ExciseCategoriesOfItems.CurrentRow = RowID;
		EndIf;
	EndIf;
	
EndProcedure

// Completes the deletion of the record.
//
// Parameters:
//	Result - DialogReturnCode - Response result returned;
//	CurrentRow - FormDataCollectionItem - The record line that is being deleted.
//
&AtClient
Procedure CompleteDeletionOfRecord(Result, CurrentRow) Export
	
	If Result = DialogReturnCode.Yes Then
		RecordID = CurrentRow.GetID();
		DeleteRecordServer(RecordID);
		NotificationParameters = New Structure("Products", Products);
		Notify("Recording_ExciseCategoryOfItem", NotificationParameters, ThisObject);
	EndIf;

EndProcedure

&AtServer
Procedure DeleteRecordServer(RecordID)
	
	Record = ExciseCategoriesOfItems.FindByID(RecordID);
	InformationRegisters.ExcisableGoodsCategories.DeleteRecord(Record.Period, Products, Record.Country);
	
	ReadItemCategories();
	
EndProcedure

&AtClient
Procedure OpenEditForm(CurrentData)
	
	Filter = New Structure();
	Filter.Insert("Products", Products);
	Filter.Insert("Country", CurrentData.Country);
	Filter.Insert("Period", CurrentData.Period);
	
	FormParameters = New Structure;
	
	ArrayFilter = New Array;
	ArrayFilter.Add(Filter);
	RecordKey = New("InformationRegisterRecordKey.ExcisableGoodsCategories", ArrayFilter);
	FormParameters.Insert("Key", RecordKey);
	
	OpenForm("InformationRegister.ExcisableGoodsCategories.Form.RecordForm", 
				FormParameters, ThisObject,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure;

#EndRegion
