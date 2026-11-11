
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.PackagingGroup = Catalogs.PackagingGroups.SpecialForItem Then
		Owner = Parameters.Products;
	Else
		Owner = Parameters.PackagingGroup;
	EndIf;
	
	QueryText = PackagingList.QueryText;
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor1",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
									"ProductPackagesOverridable",
									Undefined));
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor2",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
									"PackagesOverridable",
									Undefined));
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText					= QueryText;
	ListProperties.MainTable				= "Catalog.PackagesAndUnitsOfMeasure";
	ListProperties.DynamicDataRead	= True;
	
	Common.SetDynamicListProperties(Items.PackagingList, ListProperties);
	
	CommonClientServer.SetDynamicListParameter(PackagingList, "Owner", Owner, True);
	
	Items.PackagingListZoomRatio.Title =
		StrReplace(Items.PackagingListZoomRatio.Title, "%1%", String(Parameters.StorageUnit));
		
	Items.PackagingList.CurrentRow = Parameters.UnitForReports;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure PackagingListValueChoice(Item, Value, StandardProcessing)
	
	SelectedUnit = Item.CurrentData;
	
	If ValueIsFilled(SelectedUnit.Package) Then
		AlertStructure = New Structure;
		AlertStructure.Insert("ZoomRatio", SelectedUnit.ZoomRatio);
		
		Notify("SelectedPackagingForReports", AlertStructure);
	EndIf;
	
EndProcedure

#EndRegion
#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

