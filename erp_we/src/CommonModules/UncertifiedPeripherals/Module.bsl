
#Region Internal

// Returns an empty table of registered drivers. 
//
// Returns:
//  ValueTable   - table with columns:
//   * EquipmentType      - DefinedType.PeripheralTypes
//   * Description         - String
//   * ObjectID - String
//   * DriverTemplateName    - String
//   * DriverVersion       - String
//   * NoLongerSupported       - Boolean
//   * LocalMode_       - Boolean
//   * NetworkMode         - Boolean
//   * ServerMode       - Boolean
//
Function NewTableOfNonCertifiedDrivers() Export
	
	HardwareDrivers = New ValueTable;
	// General properties.
	HardwareDrivers.Columns.Add("EquipmentType"     , Metadata.DefinedTypes.PeripheralTypes.Type);
	HardwareDrivers.Columns.Add("Description"        , New TypeDescription("String", , New StringQualifiers(0)));
	HardwareDrivers.Columns.Add("ObjectID", New TypeDescription("String", , New StringQualifiers(0)));
	HardwareDrivers.Columns.Add("DriverTemplateName"   , New TypeDescription("String", , New StringQualifiers(0)));
	HardwareDrivers.Columns.Add("DriverVersion"      , New TypeDescription("String", , New StringQualifiers(0)));
	HardwareDrivers.Columns.Add("NoLongerSupported"      , New TypeDescription("Boolean"));
	// Operation parameters
	HardwareDrivers.Columns.Add("LocalMode_", New TypeDescription("Boolean"));
	HardwareDrivers.Columns.Add("NetworkMode"  , New TypeDescription("Boolean"));
	HardwareDrivers.Columns.Add("ServerMode", New TypeDescription("Boolean"));   
	Return HardwareDrivers;
	
	
EndFunction

// Adds the supplied drivers to the list as part of the configuration.
// 
// Parameters:
//  Equipment Driver - Assignment Table - See EquipmentManager.NewTableOfSuppliedHardwareDrivers
//  ()
//
Procedure RegisterDrivers() Export
	
	HardwareDrivers = NewTableOfNonCertifiedDrivers();
	UncertifiedPeripheralsOverridable.RegisterDrivers(HardwareDrivers);
	For Each Driver In HardwareDrivers Do
	
		If Not ValueIsFilled(Driver.EquipmentType) Then
			Driver.EquipmentType =  Enums.PeripheralTypes.Uncertified;
		EndIf;
	
	EndDo;
	Catalogs.HardwareDrivers.RegisterNonCertifiedDrivers(HardwareDrivers);
	
EndProcedure

// Returns the availability of logging payment transactions
//
// Returns:
//  Boolean
//
Function NonCertifiedEquipmentIsAvailable() Export
	
	Result = False;
	Available = Result; 
	StandardProcessing = True;
	UncertifiedPeripheralsOverridable.NonCertifiedEquipmentIsAvailable(Available, StandardProcessing);
	Result = ?(StandardProcessing, Result, Available);
	Return Result; 
	
EndFunction

#EndRegion
