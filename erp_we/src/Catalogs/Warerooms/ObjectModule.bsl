#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	AgreeOnFeatureValues();
	
	AdditionalProperties.Insert("IsNew",IsNew());
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InformationRegisters.SettingsOfBinLocationWarehouses.ApplyDefaultSettings(
		Owner,
		Ref,
		UseBinLocationWarehousing,
		StartDateOfUsingWarehouseBinSystem,
		UseBinLocationWarehousingForInformation,
		WarehouseZoneUsage = Enums.UseIsDeterminedInWarerooms.Use,
		AdditionalProperties.IsNew);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If Not ValueIsFilled(FillingData)
		Or Not FillingData.Property("Owner") Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	1 AS Field1
	|FROM
	|	Catalog.Warerooms AS Premises
	|WHERE
	|	NOT Premises.DeletionMark
	|	AND Premises.Owner = &Owner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SettingsOfBinLocationWarehouses.UseBinLocationWarehousing,
	|	SettingsOfBinLocationWarehouses.UseBinLocationWarehousingForInformation,
	|	SettingsOfBinLocationWarehouses.UseWarehouseZones,
	|	Warehouses.CurrentEmployeeInChargeTypes,
	|	Warehouses.CurrentPositionOfTheResponsiblePerson
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|		LEFT JOIN InformationRegister.SettingsOfBinLocationWarehouses AS SettingsOfBinLocationWarehouses
	|		ON (SettingsOfBinLocationWarehouses.Warehouse = Warehouses.Ref)
	|			AND (SettingsOfBinLocationWarehouses.Premise = &EmptyRoom)
	|WHERE
	|	Warehouses.Ref = &Owner";
	Query.SetParameter("Owner",FillingData.Owner);
	Query.SetParameter("EmptyRoom",Catalogs.Warerooms.EmptyRef());
	Result = Query.ExecuteBatch();
	If Result[0].IsEmpty() Then
		Selection = Result[1].Select();
		Selection.Next();
		FillPropertyValues(ThisObject, Selection);
		If Selection.UseBinLocationWarehousing Then
			CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.CellsBalance;
		ElsIf Selection.UseBinLocationWarehousingForInformation Then
			CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.BinsReferenceAddress;
		Else
			CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.DontUse;
		EndIf;
		If Selection.UseWarehouseZones Then
			WarehouseZoneUsage = Enums.UseIsDeterminedInWarerooms.Use;
		Else
			WarehouseZoneUsage = Enums.UseIsDeterminedInWarerooms.DontUse;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region Other

Procedure AgreeOnFeatureValues() Export
	If Not ValueIsFilled(CustomizeBinLocationWarehousing)
		Or CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.DeterminedByWareroomsSettings Then
		CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.DontUse;
	EndIf;
	
	If CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.CellsBalance Then
		UseBinLocationWarehousing          = True;
	ElsIf CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.BinsReferenceAddress Then
		UseBinLocationWarehousing          = False;
		UseBinLocationWarehousingForInformation = True;
	Else
		UseBinLocationWarehousing          = False;
		UseBinLocationWarehousingForInformation = False;
	EndIf;
	
	If Not UseBinLocationWarehousing
		And Not UseBinLocationWarehousingForInformation Then
		CustomizeBinLocationWarehousing = Enums.SettingsOfBinLocationWarehousing.DontUse;
	EndIf;
	
	If Not UseBinLocationWarehousing Then
		StartDateOfUsingWarehouseBinSystem = Date(1, 1, 1);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf