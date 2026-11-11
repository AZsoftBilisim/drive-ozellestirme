
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	Products = Undefined;
	If Parameters.Property("Products", Products) Then
		
		If Products.PackagingGroup = Catalogs.PackagingGroups.SpecialForItem Then
			OwnerForSelection = Products;
		Else
			OwnerForSelection = Products.PackagingGroup;
		EndIf;
		
#If Not MobileStandaloneServer Then
		CommonClientServer.SetDynamicListFilterItem(List,
																			"Owner",
																			OwnerForSelection,
																			DataCompositionComparisonType.Equal,
																			,
																			True);
#Else
		MobileWarehouseKeeperWorkspaceClientServer.SetDynamicListFilterItem(List,
																			"Owner",
																			OwnerForSelection,
																			DataCompositionComparisonType.Equal,
																			,
																			True);
#EndIf
	EndIf;
	
	If Parameters.Property("Ref") Then
		
		LinkParameters = Parameters["Ref"]; // CatalogRef.Peripherals
		
#If Not MobileStandaloneServer Then
		CommonClientServer.SetDynamicListFilterItem(List,
																			"Ref",
																			LinkParameters,
																			DataCompositionComparisonType.NotEqual,
																			,
																			True);
#Else
		MobileWarehouseKeeperWorkspaceClientServer.SetDynamicListFilterItem(List,
																			"Ref",
																			LinkParameters,
																			DataCompositionComparisonType.NotEqual,
																			,
																			True);
#EndIf
		
	EndIf;
	// StandardSubsystems.Core
#If Not MobileStandaloneServer Then
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
#EndIf
	// End StandardSubsystems.Core	
EndProcedure

#EndRegion
