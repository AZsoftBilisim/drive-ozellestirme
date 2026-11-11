
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	OnReadCreateAtServer();
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.Shop = Common.ObjectAttributeValue(CurrentObject.RouteSheet, "Shop");
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ProductDataManagementClient.NotifyAboutRecordingOfMainRouteMap(Record);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RouteSheetOnChange(Item)
	
	If ItemVariantsAreUsed Then
		UpdateCharacteristicSetting();
		AvailabilityControl(ThisForm);
	EndIf;	
	
EndProcedure

&AtClient
Procedure CharacteristicSpecificationMethodOnChange(Item)
	
	If CharacteristicSpecificationMethod = 0 Then
		Record.Characteristic = Undefined;
	EndIf; 
	
	AvailabilityControl(ThisForm);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Characteristic.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CharacteristicSpecificationMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 1;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

EndProcedure

#Region Other

&AtServer
Procedure OnReadCreateAtServer()

	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", Record.Characteristic);

	StringStructure = New Structure;
	StringStructure.Insert("Products",   Record.Products);
	StringStructure.Insert("Characteristic", Record.Characteristic);
	StringStructure.Insert("ItemVariantsAreUsed", ItemVariantsAreUsed);
	
	BatchProcessingOfTablePartServer.ProcessTSString(StringStructure, StructureOfActions, Undefined);

	FillPropertyValues(Record, StringStructure);
	
	ItemVariantsAreUsed = StringStructure.ItemVariantsAreUsed;
	Items.Characteristic.Enabled = ItemVariantsAreUsed;
	
	If Not ItemVariantsAreUsed Then
		Items.PageGroupSettingsCharacteristics.CurrentPage = Items.GroupPageCharacteristicsAreNotUsed;
	EndIf; 
	
	UpdateCharacteristicSetting();
	
	If Not Record.Characteristic.IsEmpty() Then
		CharacteristicSpecificationMethod = 1;
	EndIf;

	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)

	Form.Items.Characteristic.ReadOnly = (Form.CharacteristicSpecificationMethod <> 1);

EndProcedure

&AtServer
Procedure UpdateCharacteristicSetting()

	If Not ItemVariantsAreUsed Then
		Return;
	EndIf;
	
	If Record.RouteSheet.IsEmpty() Then
		Items.SetupGroup.CurrentPage = Items.GroupPageRouteMapNotSelected;
		Return;
	EndIf; 
	
	Items.SetupGroup.CurrentPage = Items.GroupPageRouteMapSelected;
	
	Query = New Query;
	Query.Text = "SELECT
	               |	ManufacturedProducts.Characteristic,
	               |	ManufacturedProducts.Ref.ValidOnDate AS ValidOnDate,
	               |	ManufacturedProducts.Ref.ValidToDate AS ValidToDate
	               |FROM
	               |	Catalog.RouteSheets.ManufacturedProducts AS ManufacturedProducts
	               |WHERE
	               |	ManufacturedProducts.Ref = &Object
	               |	AND ManufacturedProducts.Products = &Products
	               |
	               |ORDER BY
	               |	ManufacturedProducts.LineNumber";
	
	Query.SetParameter("Object",       Record.RouteSheet);
	Query.SetParameter("Products", Record.Products);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	
	Selection.Next();
	
	If Selection.Characteristic.IsEmpty() Then
		Items.PageGroupSettingsCharacteristics.CurrentPage = Items.TheFeaturePageGroupIsConfigurable;
	Else
		Record.Characteristic = Selection.Characteristic;
		Items.PageGroupSettingsCharacteristics.CurrentPage = Items.TheGroupPageCharacteristicIsSpecifiedInTheRouteMap;
	EndIf; 
	
EndProcedure

#EndRegion

#EndRegion
