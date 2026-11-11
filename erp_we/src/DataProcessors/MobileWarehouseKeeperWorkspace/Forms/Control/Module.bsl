
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	RowsArray = Parameters.RowsArray;
	Warehouse       = Parameters.Warehouse;
	Premise   = Parameters.Premise;
	ShowProductPhotos = Parameters.ShowProductPhotos;
	
	FillForm(RowsArray);
	
	SetConditionalAppearance();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	LongDesc = New CallbackDescription("CompleteConfirmation", ThisForm);
	
	FormParameters = New Structure;
	FormParameters.Insert("Products", Item.CurrentData.Products);
	FormParameters.Insert("Characteristic", Item.CurrentData.Characteristic);
	FormParameters.Insert("Series", Item.CurrentData.Series);
	FormParameters.Insert("Purpose", Item.CurrentData.Purpose);
	FormParameters.Insert("Package", Item.CurrentData.Package);
	FormParameters.Insert("Count", Item.CurrentData.NumberOfPackagesReal);
	FormParameters.Insert("Mode", "EditingRecalculation");
	FormParameters.Insert("LineNumber", Item.CurrentRow);
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("SKU", Item.CurrentData.SKU);

	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile",FormParameters,
	ThisForm,,,,LongDesc,
	FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure FinishAcceptance(Command)
	
	For Each String In Goods Do
		If String.CountReal = 0 Then
			ErrorText = NStr("vi = 'Hãy chỉ ra số lượng hàng hóa';
							|ru = 'Укажите количество товаров';
							|en = 'Specify goods quantity'; fa = 'Specify goods quantity';
							|it = 'Укажите количество товаров';
							|pl = 'Specify goods quantity';
							|tr = 'Ürün sayısını belirtin'");
			UserMessage = New UserMessage;
			UserMessage.Text = TrimAll(ErrorText);
			UserMessage.Message();
			
			Return;
		EndIf;
	EndDo;
	
	RowsArray = New Array;
	For Each String In Goods Do

		FillingStructure = GetStructureOfControlFilling();
		FillPropertyValues(FillingStructure, String);
		RowsArray.Add(FillingStructure);
		
	EndDo;
	
	Close(RowsArray);
	
EndProcedure

&AtClient
Procedure Scan(Command)
	
	StandardProcessing = False;
	
	LongDesc = New CallbackDescription("ScanningResult", ThisForm);
	
	FormParameters = New Structure;
	FormParameters.Insert("FindType", "ProductItemsSearch");
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	
	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.BarcodeScanning",FormParameters,
	ThisForm,,,,LongDesc,
	FormWindowOpeningMode.Independent);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackagesIsDifference.Name);
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.NumberOfPackagesIsDifference");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.TextColorIssue); 
	
	UpdateHint();
	
EndProcedure

&AtServer
Procedure FillForm(RowsArray)
	
	For Each String In RowsArray Do
		
		NewRow = Goods.Add();
		FillPropertyValues(NewRow, String);
		NewRow.NumberOfPackagesIsDifference = NewRow.NumberOfPackages;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure CompleteConfirmation(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	CompleteConfirmationOnServer(Result);
	
EndProcedure

&AtServer
Procedure CompleteConfirmationOnServer(Result)
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Products", Result.Products);
	TheStructureOfTheSearch.Insert("Characteristic", Result.Characteristic);
	TheStructureOfTheSearch.Insert("Series", Result.Series);
	TheStructureOfTheSearch.Insert("Package", Result.Package);
	TheStructureOfTheSearch.Insert("Purpose", Result.Purpose);
	
	PackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Result.Package, Result.Products);
	
	SearchResult = Goods.FindRows(TheStructureOfTheSearch);
	If SearchResult.Count() > 0 Then
		
		If Result.Mode = "Recalculate" Then
			SearchResult[0].NumberOfPackagesReal = SearchResult[0].NumberOfPackagesReal + Result.NumberOfPackages;
		Else
			SearchResult[0].NumberOfPackagesReal = Result.NumberOfPackages;
		EndIf;
		
		SearchResult[0].CountReal = SearchResult[0].NumberOfPackagesReal * PackagingFactor;
		
		SearchResult[0].NumberOfPackagesIsDifference = SearchResult[0].NumberOfPackages - SearchResult[0].NumberOfPackagesReal;
		SearchResult[0].QuantityDifference = SearchResult[0].NumberOfPackagesIsDifference * PackagingFactor;
		
	EndIf; 
	
	UpdateHint();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	If Items.GroupPages.CurrentPage = Items["InformationPage"] Then
		
		StandardProcessing = False;
		Items.GroupPages.CurrentPage = Items["PageToReceive"];
		
	EndIf;
EndProcedure

&AtServer
Procedure UpdateHint()
	
	Plan = Goods.Total("NumberOfPackages");
	Real = Goods.Total("NumberOfPackagesReal");
	Difference = Plan - Real;
	
	Items.TitleHintFact.Title = Real;
	Items.TitleHintPlan.Title = Plan;
	Items.TitleHintDifference.Title = Difference;
	
EndProcedure

&AtClient
Function GetStructureOfControlFilling()
	
	Structure = New Structure;
	Structure.Insert("Products");
	Structure.Insert("Characteristic");
	Structure.Insert("Series");
	Structure.Insert("Package");
	Structure.Insert("NumberOfPackagesReal");
	Structure.Insert("Purpose");
	Structure.Insert("Action");
	
	Return Structure;
	
EndFunction

&AtClient
Procedure ScanningResult(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	LongDesc = New CallbackDescription("CompleteConfirmation", ThisForm);
	
	FormParameters = New Structure;
	FormParameters.Insert("Products", Result.Products);
	FormParameters.Insert("Characteristic", Result.Characteristic);
	If Result.Property("Series") Then
		FormParameters.Insert("Series", Result.Series);
	Else
		FormParameters.Insert("Series", EmptyBatch_);
	EndIf;
	FormParameters.Insert("Package", Result.Package);
	FormParameters.Insert("Count", 1);
	FormParameters.Insert("Mode", "Recalculate");
	FormParameters.Insert("LineNumber", 0);
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	
	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.GoodsProfile",FormParameters,
	ThisForm,,,,LongDesc,
	FormWindowOpeningMode.Independent);
	
EndProcedure


#EndRegion
