
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Object = Parameters.RouteSheet;
	
	FillInProductSettings();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersItemList

&AtClient
Procedure ItemListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	AddCharacteristicsToList();
	
EndProcedure

&AtClient
Procedure ItemListBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	RemoveCharacteristicsFromList();
	
EndProcedure

&AtClient
Procedure ItemListChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	RowOfProducts = Items.ItemList.CurrentData;
	If RowOfProducts = Undefined Then
		Return;
	EndIf;
	
	If RowOfProducts.RowType = 1 Then
		RowOfProducts = RowOfProducts.GetParent();
	EndIf; 
	
	CollectionOfCharacteristics = RowOfProducts.GetItems();
	
	// Let's check the presence of the selected characteristic
	For Each CollectionItem In CollectionOfCharacteristics Do
		If CollectionItem.Characteristic = ValueSelected Then
			Return;
		EndIf;
	EndDo;
	
	NewCharacteristic = CollectionOfCharacteristics.Add();
	NewCharacteristic.Characteristic = ValueSelected;
	NewCharacteristic.RowType = 1;
	
	If CollectionOfCharacteristics.Count() = 0 Then
		RowOfProducts.AnyCharacteristics = True;
	Else
		RowOfProducts.AnyCharacteristics = False;
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TheSelectCharacteristicsCommand(Command)
	
	AddCharacteristicsToList();
	
EndProcedure

&AtClient
Procedure DeleteCharacteristics(Command)
	
	RemoveCharacteristicsFromList();
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)

	WriteAtServer();
	
	ProductDataManagementClient.NotifyAboutRecordingOfMainRouteMap();
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemListCheck.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemListProducts.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemList.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , False, True, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemListCharacteristic.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.ItemVariantsAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.AnyCharacteristics");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với đặc tính bất kỳ>';
													|ru = '<для любых характеристик>';
													|en = '<for any variants>'; fa = '<for any variants>';
													|it = '<per qualsiasi caratteristica>';
													|pl = '<dla dowolnych charakterystyk>';
													|tr = '<herhangi bir varyant için>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemListCharacteristic.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.ItemVariantsAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItemList.AnyCharacteristics");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<cho các đặc tính đã chọn>';
													|ru = '<для выбранных характеристик>';
													|en = '<for selected variants>'; fa = '<for selected variants>';
													|it = '<per le caratteristiche selezionate>';
													|pl = '<dla wybranych charakterystyk>';
													|tr = '<seçilen varyantlar için>'"));

EndProcedure

#Region ProductSetting

&AtServer
Procedure FillInProductSettings()

	UseItemVariants = GetFunctionalOption("UseItemVariants");
	InputOfCharacteristicIsAvailable = False;
	ItemVariantsAreUsed = False;
	
	// We will get the products and add them to the selection list 
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ManufacturedProducts.Products AS Products,
	|	ManufacturedProducts.Characteristic AS Characteristic,
	|	ManufacturedProducts.Products.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind), VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)) AS ItemVariantsAreUsed
	|FROM
	|	Catalog.RouteSheets.ManufacturedProducts AS ManufacturedProducts
	|WHERE
	|	ManufacturedProducts.Ref = &Object
	|
	|ORDER BY
	|	ManufacturedProducts.LineNumber";
	
	Query.SetParameter("Object", Object);
	
	Result = Query.Execute();
	
	SelectionOfProducts_ = Result.Select();
	
	ItemsCollection = ItemList.GetItems();
	While SelectionOfProducts_.Next() Do
		
		NewNomenclature = ItemsCollection.Add();
		NewNomenclature.Products   = SelectionOfProducts_.Products;
		NewNomenclature.Characteristic = SelectionOfProducts_.Characteristic;
		NewNomenclature.ItemVariantsAreUsed = SelectionOfProducts_.ItemVariantsAreUsed;
		NewNomenclature.AnyCharacteristics = True;
		NewNomenclature.Check = True;
		
		If UseItemVariants And NewNomenclature.ItemVariantsAreUsed And NewNomenclature.Characteristic.IsEmpty() Then
			InputOfCharacteristicIsAvailable = True;
		EndIf; 

		ItemVariantsAreUsed = ItemVariantsAreUsed Or NewNomenclature.ItemVariantsAreUsed;
		
	EndDo;

	If ItemsCollection.Count() = 1 Then
		Items.ItemListCheck.Visible = False;
		
		If Not InputOfCharacteristicIsAvailable Then
			Items.ItemList.ReadOnly = True;
		EndIf;
	EndIf; 
	
	// If the input of the characteristic is not available, then we will remove the command panel
	If Not InputOfCharacteristicIsAvailable Then
		Items.ItemList.CommandBarLocation = FormItemCommandBarLabelLocation.None;
	EndIf; 
	
	// If the characteristics are not used, then we will remove the "Characteristic" column
	If Not UseItemVariants Or Not ItemVariantsAreUsed Then
		Items.ItemListCharacteristic.Visible = False;
	EndIf; 
	
EndProcedure

// Opens the feature selection form and adds the selected features to the list
//
&AtClient
Procedure AddCharacteristicsToList()

	RowOfProducts = Items.ItemList.CurrentData;
	If RowOfProducts = Undefined Then
		Return;
	EndIf;
	
	If RowOfProducts.RowType = 1 Then
		RowOfProducts = RowOfProducts.GetParent();
	EndIf; 
	
	If Not RowOfProducts.Characteristic.IsEmpty() Then
		ShowMessageBox(,NStr("vi = 'Các đặc tính được xác định trong bản đồ tuyến đường.';
							|ru = 'Характеристика определена в маршрутной карте.';
							|en = 'Characteristic is determined in the route sheet.'; fa = 'Characteristic is determined in the route sheet.';
							|it = 'La caratteristica è definita nel foglio di lavorazione';
							|pl = 'Charakterystyka jest określona w karcie technologicznej.';
							|tr = 'Varyant, rotada tanımlandı.'"));
		Return;
	EndIf; 
	
	FormParameters = New Structure;
	FormParameters.Insert("Products", RowOfProducts.Products);
	FormParameters.Insert("CloseOnChoice", False);
	
	OpenForm("Catalog.ItemsCharacteristics.ChoiceForm", 
					FormParameters, 
					Items.ItemList,,,,, 
					FormWindowOpeningMode.LockOwnerWindow); 

EndProcedure

&AtClient
Procedure RemoveCharacteristicsFromList()

	CurrentData = Items.ItemList.CurrentData;
	If CurrentData = Undefined Or CurrentData.RowType = 0 Then
		Return;
	EndIf;
	
	RowOfProducts = CurrentData.GetParent();
	
	CollectionOfCharacteristics = RowOfProducts.GetItems();
	CollectionOfCharacteristics.Delete(CurrentData);
	
	If CollectionOfCharacteristics.Count() = 0 Then
		RowOfProducts.AnyCharacteristics = True;
	EndIf; 
	
EndProcedure

#EndRegion

#Region RecordingSettings_

&AtServer
Procedure AddSettingForItem(Products, Characteristic, HasErrors)

	RecordProperties = New Structure;
	RecordProperties.Insert("Products",    Products);
	RecordProperties.Insert("Characteristic",  Characteristic);
	RecordProperties.Insert("RouteSheet", Object);
	
	If Not ProductDataManagementServerCall.SetAsMainOperationsSheet(RecordProperties) Then
		HasErrors = True;
	EndIf;

EndProcedure
 
&AtServer
Procedure WriteAtServer()
	
	BeginTransaction();
	
	Try
		
		HasErrors = False;
		ItemsCollection = ItemList.GetItems();
		
		For Each RowOfProducts In ItemsCollection Do
			
			If Not RowOfProducts.Check Then
				Continue;
			EndIf;
			
			If RowOfProducts.AnyCharacteristics Then
				AddSettingForItem(RowOfProducts.Products, RowOfProducts.Characteristic, HasErrors);
			Else
				CollectionOfCharacteristics = RowOfProducts.GetItems();
				For Each FeatureLine In CollectionOfCharacteristics Do
					AddSettingForItem(RowOfProducts.Products, FeatureLine.Characteristic, HasErrors);
				EndDo; 
			EndIf;
			
		EndDo;
		
		If HasErrors Then
			Raise NStr("vi = 'Không thể đặt bản đồ tuyến chính.';
						|ru = 'Не удалось назначить маршрутную карту основной.';
						|en = 'Cannot set the route sheet as the main one.'; fa = 'Cannot set the route sheet as the main one.';
						|it = 'Impossibile assegnare un foglio di lavorazione a quello principale.';
						|pl = 'Nie udało się przeznaczyć kartę technologiczną, jako podstawową.';
						|tr = 'Rota temel olarak atanamadı.'");
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
 		WriteLogEvent(
			NStr("vi = 'Chỉ định sơ đồ quy trình chính';
				|ru = 'Назначение основной маршрутной карты';
				|en = 'Assign main route sheet'; fa = 'Assign main route sheet';
				|it = 'Assegnazione foglio di lavorazione del percorso';
				|pl = 'Przeznaczenie podstawowej karty technologicznej';
				|tr = 'Temel rotanın atanması'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
			
 		Raise;
		
	EndTry;
	
EndProcedure

#EndRegion

#EndRegion
